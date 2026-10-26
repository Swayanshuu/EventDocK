import 'dart:async';
import 'package:flutter/material.dart';
import '../models/auth_state.dart';
import '../services/auth_service.dart';
import 'role_selector.dart';

class AuthForm extends StatefulWidget {
  final AuthRole initialRole;
  final AuthMode initialMode;
  final ValueChanged<AuthRole> onRoleChanged;
  final VoidCallback onAuthSuccess;
  final ValueChanged<AuthMode>? onModeChanged;

  const AuthForm({
    super.key,
    this.initialRole = AuthRole.individual,
    this.initialMode = AuthMode.signIn,
    required this.onRoleChanged,
    required this.onAuthSuccess,
    this.onModeChanged,
  });

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  late AuthRole _role;
  late AuthMode _mode;
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _successMessage;

  // Rate Limiting Countdown Timer
  Timer? _countdownTimer;
  int _lockoutRemainingSeconds = 0;

  // Form Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _orgNameController = TextEditingController();
  final _leadNameController = TextEditingController();

  // Dropdown States
  String _selectedTeamSize = '1-10';
  final List<String> _teamSizeOptions = [
    '1-10',
    '11-50',
    '50-200',
    '200+',
  ];

  // Focus Nodes for Keyboard Traversal (Tab + Enter)
  final _nameFocusNode = FocusNode();
  final _orgNameFocusNode = FocusNode();
  final _leadNameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  // Live password validation
  PasswordValidation _passwordValidation = const PasswordValidation(
    hasMinLength: false,
    hasUppercase: false,
    hasLowercase: false,
    hasDigit: false,
    hasSpecialChar: false,
  );

  @override
  void initState() {
    super.initState();
    _role = widget.initialRole;
    _mode = widget.initialMode;

    _passwordController.addListener(_onPasswordChanged);
    _emailController.addListener(_checkRateLimitStatus);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _emailController.removeListener(_checkRateLimitStatus);
    _passwordController.removeListener(_onPasswordChanged);

    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _orgNameController.dispose();
    _leadNameController.dispose();

    _nameFocusNode.dispose();
    _orgNameFocusNode.dispose();
    _leadNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();

    super.dispose();
  }

  void _onPasswordChanged() {
    setState(() {
      _passwordValidation = PasswordValidation.validate(_passwordController.text);
    });
  }

  void _checkRateLimitStatus() {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    final limit = AuthService().checkRateLimit(email);
    if (limit.isLocked && limit.remainingSeconds > 0) {
      _startCountdown(limit.remainingSeconds);
    }
  }

  void _startCountdown(int seconds) {
    _countdownTimer?.cancel();
    setState(() {
      _lockoutRemainingSeconds = seconds;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_lockoutRemainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _lockoutRemainingSeconds = 0;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _lockoutRemainingSeconds--;
        });
      }
    });
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    // Check rate limit before dispatching
    final limit = AuthService().checkRateLimit(email);
    if (limit.isLocked) {
      _startCountdown(limit.remainingSeconds);
      setState(() {
        _errorMessage = limit.message;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_mode == AuthMode.signIn) {
        await AuthService().signInWithEmailAndPassword(
          email: email,
          password: password,
          role: _role,
          rememberMe: _rememberMe,
        );
        widget.onAuthSuccess();
      } else if (_mode == AuthMode.signUp) {
        if (!_passwordValidation.isValid) {
          throw Exception('Please fulfill all password security requirements.');
        }

        final name = _role == AuthRole.individual
            ? _nameController.text.trim()
            : _leadNameController.text.trim();

        if (name.isEmpty) {
          throw Exception('Please enter your full name.');
        }

        if (_role == AuthRole.organisation && _orgNameController.text.trim().isEmpty) {
          throw Exception('Please enter your organization or company name.');
        }

        await AuthService().createUserWithEmailAndPassword(
          email: email,
          password: password,
          role: _role,
          name: name,
          orgName: _orgNameController.text.trim(),
          teamSize: _role == AuthRole.organisation ? _selectedTeamSize : null,
          leadName: _leadNameController.text.trim(),
        );

        widget.onAuthSuccess();
      } else if (_mode == AuthMode.forgotPassword) {
        await AuthService().sendPasswordReset(email);
        setState(() {
          _successMessage = 'Password reset instructions have been sent to $email';
        });
      }
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      final limitAfter = AuthService().checkRateLimit(email);
      if (limitAfter.isLocked && limitAfter.remainingSeconds > 0) {
        _startCountdown(limitAfter.remainingSeconds);
      }
      setState(() {
        _errorMessage = msg;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _switchRole(AuthRole newRole) {
    setState(() {
      _role = newRole;
      _errorMessage = null;
    });
    widget.onRoleChanged(newRole);
  }

  void _switchMode(AuthMode newMode) {
    setState(() {
      _mode = newMode;
      _errorMessage = null;
      _successMessage = null;
    });
    widget.onModeChanged?.call(newMode);
  }

  @override
  Widget build(BuildContext context) {
    final isSignIn = _mode == AuthMode.signIn;
    final isSignUp = _mode == AuthMode.signUp;
    final isOrg = _role == AuthRole.organisation;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Header with Logo & Typography
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0038FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/auth_mascot.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(
                          Icons.radar_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'EventDock',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                isSignIn
                    ? 'Welcome Back'
                    : isSignUp
                        ? 'Create Your Account'
                        : 'Reset Password',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                  letterSpacing: -0.7,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isSignIn
                    ? 'Authenticate to access deterministic benchmarking and telemetry.'
                    : isSignUp
                        ? 'Join the engineering platform for verified teams and developers.'
                        : 'Enter your email to receive recovery instructions.',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),

              // 2. Dual-Role Segmented Selector
              RoleSelector(
                selectedRole: _role,
                onRoleChanged: _switchRole,
              ),
              const SizedBox(height: 16),

              // 3. Real-Time Lockout Alert Banner
              if (_lockoutRemainingSeconds > 0)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_clock_rounded, color: Color(0xFFDC2626), size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Security Lockout: Rate limit exceeded. Try again in ${_lockoutRemainingSeconds}s.',
                          style: const TextStyle(
                            color: Color(0xFF991B1B),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Error Banner
              if (_errorMessage != null && _lockoutRemainingSeconds == 0)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFF991B1B),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Success Banner
              if (_successMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF6EE7B7)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF059669), size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: const TextStyle(
                            color: Color(0xFF065F46),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // 4. Form Fields
              // Sign Up Specific Fields:
              if (isSignUp) ...[
                if (isOrg) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildInputField(
                          label: 'Organisation Name',
                          hintText: 'Acme Systems Corp',
                          controller: _orgNameController,
                          focusNode: _orgNameFocusNode,
                          nextFocusNode: _leadNameFocusNode,
                          icon: Icons.business_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInputField(
                          label: 'Lead Contact Name',
                          hintText: 'Sarah Connor',
                          controller: _leadNameController,
                          focusNode: _leadNameFocusNode,
                          nextFocusNode: _emailFocusNode,
                          icon: Icons.badge_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Organisation Row 2: Work Email + Team Size
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildInputField(
                          label: 'Work Email Address',
                          hintText: 'engineering@company.com',
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          nextFocusNode: _passwordFocusNode,
                          keyboardType: TextInputType.emailAddress,
                          icon: Icons.mail_outline_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: _buildDropdownField<String>(
                          label: 'Team Size',
                          value: _selectedTeamSize,
                          items: _teamSizeOptions,
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedTeamSize = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  _buildInputField(
                    label: 'Full Name',
                    hintText: 'Alex Rivera',
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    nextFocusNode: _emailFocusNode,
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 12),

                  _buildInputField(
                    label: 'Email Address',
                    hintText: 'engineer@domain.com',
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    nextFocusNode: _passwordFocusNode,
                    keyboardType: TextInputType.emailAddress,
                    icon: Icons.mail_outline_rounded,
                  ),
                  const SizedBox(height: 12),
                ],
              ] else ...[
                // Sign In mode Email Field
                _buildInputField(
                  label: isOrg ? 'Work Email Address' : 'Email Address',
                  hintText: isOrg ? 'engineering@company.com' : 'engineer@domain.com',
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  nextFocusNode: _passwordFocusNode,
                  keyboardType: TextInputType.emailAddress,
                  icon: Icons.mail_outline_rounded,
                ),
                const SizedBox(height: 12),
              ],

              // Password Field (if not in forgotPassword mode)
              if (_mode != AuthMode.forgotPassword) ...[
                _buildInputField(
                  label: 'Password',
                  hintText: '••••••••••••',
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  isPassword: true,
                  obscureText: _obscurePassword,
                  onToggleObscure: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  onSubmitted: (_) => _handleSubmit(),
                  icon: Icons.lock_outline_rounded,
                ),
                const SizedBox(height: 8),

                // Live Password Strength Checklist (Sign Up only)
                if (isSignUp) ...[
                  _buildPasswordRequirementList(),
                  const SizedBox(height: 16),
                ],
              ],

              // Remember Me & Forgot Password Row (Sign In mode)
              if (isSignIn) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() => _rememberMe = !_rememberMe);
                      },
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (v) => setState(() => _rememberMe = v ?? false),
                              activeColor: const Color(0xFF0038FF),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              side: const BorderSide(color: Color(0xFFD1D5DB)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Remember me',
                            style: TextStyle(
                              color: Color(0xFF4B5563),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _switchMode(AuthMode.forgotPassword),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF0038FF),
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // 5. Primary Action CTA Button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: (_isLoading || _lockoutRemainingSeconds > 0) ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0038FF),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF93C5FD),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    splashFactory: NoSplash.splashFactory,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          isSignIn
                              ? 'Sign In to EventDock'
                              : isSignUp
                                  ? 'Create Verified Account'
                                  : 'Send Reset Link',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 22),

              // 6. Footer Mode Toggle
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      isSignIn
                          ? "Don't have an account? "
                          : isSignUp
                              ? 'Already have an account? '
                              : 'Remembered your password? ',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        if (isSignIn) {
                          _switchMode(AuthMode.signUp);
                        } else {
                          _switchMode(AuthMode.signIn);
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF0038FF),
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        isSignIn
                            ? 'Sign Up'
                            : 'Sign In',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocusNode,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleObscure,
    ValueChanged<String>? onSubmitted,
    TextInputType keyboardType = TextInputType.text,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: isPassword && obscureText,
            keyboardType: keyboardType,
            textInputAction: nextFocusNode != null ? TextInputAction.next : TextInputAction.done,
            onSubmitted: (val) {
              if (nextFocusNode != null) {
                FocusScope.of(context).requestFocus(nextFocusNode);
              } else if (onSubmitted != null) {
                onSubmitted(val);
              }
            },
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF111827),
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              filled: true,
              fillColor: const Color(0xFFFAFAFA),
              prefixIcon: icon != null
                  ? Icon(icon, size: 17, color: const Color(0xFF9CA3AF))
                  : null,
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 17,
                        color: const Color(0xFF9CA3AF),
                      ),
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onPressed: onToggleObscure,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF0038FF), width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF6B7280)),
              items: items.map((item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    item.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF111827),
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordRequirementList() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Password requirements:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4B5563),
                ),
              ),
              Text(
                _passwordValidation.isValid ? 'Strong' : 'Incomplete',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _passwordValidation.isValid
                      ? const Color(0xFF059669)
                      : const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRequirementItem('8+ characters', _passwordValidation.hasMinLength),
                    const SizedBox(height: 3),
                    _buildRequirementItem('Uppercase (A-Z)', _passwordValidation.hasUppercase),
                    const SizedBox(height: 3),
                    _buildRequirementItem('One number (0-9)', _passwordValidation.hasDigit),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRequirementItem('Lowercase (a-z)', _passwordValidation.hasLowercase),
                    const SizedBox(height: 3),
                    _buildRequirementItem('Special char (!@#\$%)', _passwordValidation.hasSpecialChar),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String label, bool isSatisfied) {
    return Row(
      children: [
        Icon(
          isSatisfied ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 13,
          color: isSatisfied ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSatisfied ? FontWeight.w600 : FontWeight.w400,
            color: isSatisfied ? const Color(0xFF065F46) : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}
