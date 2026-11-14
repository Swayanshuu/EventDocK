import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../services/waitlist_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

enum WaitlistWheelState {
  idle,
  spinning,
  successTick,
  errorUntick,
}

class WaitlistScreen extends StatefulWidget {
  const WaitlistScreen({super.key});

  @override
  State<WaitlistScreen> createState() => _WaitlistScreenState();
}

class _WaitlistScreenState extends State<WaitlistScreen> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _scrollController = ScrollController();
  final _formKey = GlobalKey<FormState>();

  bool _isSubmitting = false;
  bool _isSubmitted = false;
  bool _isAlreadyJoined = false;
  WaitlistWheelState _wheelState = WaitlistWheelState.idle;
  String? _successMessage;
  String? _errorMessage;
  bool _showAdditionalFields = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _handleJoinWaitlist() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() {
        _errorMessage = 'Please enter a valid developer email address.';
        _wheelState = WaitlistWheelState.errorUntick;
      });
      Future.delayed(const Duration(milliseconds: 2200), () {
        if (mounted && _wheelState == WaitlistWheelState.errorUntick) {
          setState(() {
            _wheelState = WaitlistWheelState.idle;
          });
        }
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _wheelState = WaitlistWheelState.spinning;
      _errorMessage = null;
    });

    try {
      final res = await WaitlistService().submitWaitlist(
        email: email,
        name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        company: _companyController.text.trim().isEmpty ? null : _companyController.text.trim(),
      );

      if (mounted) {
        if (res['success'] == true) {
          final isAlreadyJoined = res['alreadyJoined'] == true;
          setState(() {
            _wheelState = WaitlistWheelState.successTick;
            _isAlreadyJoined = isAlreadyJoined;
            _successMessage = res['message'] as String? ??
                (isAlreadyJoined
                    ? "You're already a part of the waitlist! We have your early access spot reserved."
                    : 'You are on the waitlist!');
          });
          // Wait 650ms for user to experience the animated checkmark tick
          await Future.delayed(const Duration(milliseconds: 650));
          if (mounted) {
            setState(() {
              _isSubmitted = true;
              _isSubmitting = false;
            });
          }
        } else {
          setState(() {
            _wheelState = WaitlistWheelState.errorUntick;
            _errorMessage = res['message'] as String? ?? 'Unable to join waitlist. Please try again.';
            _isSubmitting = false;
          });
          Future.delayed(const Duration(milliseconds: 2500), () {
            if (mounted && _wheelState == WaitlistWheelState.errorUntick) {
              setState(() {
                _wheelState = WaitlistWheelState.idle;
              });
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _wheelState = WaitlistWheelState.successTick;
          _isAlreadyJoined = false;
          _successMessage = "You're on the list! We will notify you when early access begins.";
        });
        await Future.delayed(const Duration(milliseconds: 650));
        if (mounted) {
          setState(() {
            _isSubmitted = true;
            _isSubmitting = false;
          });
        }
      }
    }
  }

  void _resetForm() {
    setState(() {
      _emailController.clear();
      _nameController.clear();
      _companyController.clear();
      _isSubmitted = false;
      _isSubmitting = false;
      _isAlreadyJoined = false;
      _wheelState = WaitlistWheelState.idle;
      _successMessage = null;
      _errorMessage = null;
      _showAdditionalFields = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Organic Glowing Aurora & Neon Ribbon Backdrop
          Positioned.fill(
            child: CustomPaint(
              painter: _GlowRibbonPainter(),
            ),
          ),

          // 2. Main Scrollable Content
          SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Top Navigation Bar
                  _buildNavBar(isMobile),

                  const SizedBox(height: 24),

                  // Hero Section
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 32,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 860),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Frosted Capsule Pill Kicker
                          _buildPillKicker(isMobile),

                          const SizedBox(height: 28),

                          // Coming Soon! Primary Headline (matching Framer reference)
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Colors.white, Color(0xFFECEFF1), Color(0xFFCFD8DC)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ).createShader(bounds),
                            child: Text(
                              'Coming soon!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isMobile ? 44 : 76,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -2.0,
                                height: 1.05,
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Brand Value Proposition
                          Text(
                            'Understand. Debug. Fix Faster.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFFFF7043),
                              fontSize: isMobile ? 20 : 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Subtitle description
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 600),
                            child: Text(
                              'A dedicated developer platform to detect, inspect, and reproduce API failures in Spring Boot applications with zero latency overhead.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFFA3A3A3),
                                fontSize: isMobile ? 14 : 15.5,
                                height: 1.6,
                              ),
                            ),
                          ),

                          const SizedBox(height: 36),

                          // Central Frosted Glassmorphism Card (matching the image)
                          _buildGlassWaitlistCard(isMobile, screenWidth),

                          const SizedBox(height: 24),

                          // Frosted Quick Action Links (GitHub, Maven, Docs)
                          _buildFrostedSocialPills(),

                          const SizedBox(height: 70),

                          // Key Architectural Features
                          _buildFeaturesSection(isMobile),

                          const SizedBox(height: 60),

                          // Spring Boot Starter Integration Preview
                          _buildIntegrationPreview(isMobile),

                          const SizedBox(height: 70),

                          // Huge Outlined "Waitlist" Typographic Backdrop
                          _buildArchitecturalOutlinedText(isMobile),

                          const SizedBox(height: 24),

                          // Fully Functional, Interactive & Zoomed Footer
                          _buildFooter(isMobile),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavBar(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 36,
        vertical: 14,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Zoomed, crystal clear transparent EventDock logo with smooth click-to-top
          Flexible(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _scrollToTop,
                child: Tooltip(
                  message: 'EventDock • Return to top',
                  child: EventDockLogo(
                    height: isMobile ? 32 : 42,
                    fontSize: isMobile ? 20 : 26,
                    isDark: true,
                  ),
                ),
              ),
            ),
          ),

          // Status Badge Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFF7043).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFF7043).withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF7043),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'WAITLIST ONLY',
                  style: TextStyle(
                    color: Color(0xFFFF7043),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillKicker(bool isMobile) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF7043).withValues(alpha: 0.15),
                blurRadius: 16,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('⚡', style: TextStyle(fontSize: 12)),
              SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'EARLY ACCESS WAITLIST • SPRING BOOT 3.X',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassWaitlistCard(bool isMobile, double screenWidth) {
    final useInlineBar = screenWidth >= 520 && !_showAdditionalFields;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 620),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 36,
            vertical: isMobile ? 28 : 40,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.14),
                Colors.white.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.20),
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF7043).withValues(alpha: 0.25),
                blurRadius: 60,
                spreadRadius: -10,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.85),
                blurRadius: 50,
                offset: const Offset(0, 24),
              ),
            ],
          ),
          child: _isSubmitted
              ? _buildSuccessView()
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Card Heading (matching Framer reference)
                      const Text(
                        'Join our waitlist!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sign up for our early access to receive the latest updates\nand private beta credentials straight to your inbox.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFB0B0B0),
                          fontSize: 13.5,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 28),

                      if (_errorMessage != null) ...[
                        Container(
                          key: const Key('waitlist_error_banner'),
                          margin: const EdgeInsets.only(bottom: 18),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.status5xx.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.status5xx.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, size: 16, color: AppTheme.status5xx),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: AppTheme.status5xx, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Integrated Pill Input Bar
                      if (useInlineBar)
                        _buildInlineInputBar()
                      else
                        _buildStackedInputBar(),

                      // Additional fields toggle
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showAdditionalFields = !_showAdditionalFields;
                          });
                        },
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _showAdditionalFields ? Icons.remove_circle_outline : Icons.add_circle_outline,
                                size: 13,
                                color: const Color(0xFF9E9E9E),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _showAdditionalFields
                                    ? 'Hide optional details'
                                    : '+ Add Name & Company (optional)',
                                style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  /// High-fidelity inline pill input bar (matching the Framer screenshot)
  Widget _buildInlineInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 5, 5, 5),
      child: Row(
        children: [
          const Icon(Icons.mail_outline, size: 18, color: Color(0xFFAAAAAA)),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              key: const Key('waitlist_email_input'),
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Enter developer email...',
                hintStyle: TextStyle(color: Color(0xFF6E6E6E), fontSize: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              onFieldSubmitted: (_) => _handleJoinWaitlist(),
            ),
          ),
          const SizedBox(width: 8),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  /// Stacked input bar for mobile viewports
  Widget _buildStackedInputBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: TextFormField(
            key: const Key('waitlist_email_input'),
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'alex@company.com',
              labelText: 'Developer Email',
              labelStyle: TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
              hintStyle: TextStyle(color: Color(0xFF6E6E6E), fontSize: 14),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              prefixIcon: Icon(Icons.mail_outline, size: 18, color: Color(0xFFAAAAAA)),
            ),
            onFieldSubmitted: (_) => _handleJoinWaitlist(),
          ),
        ),

        if (_showAdditionalFields) ...[
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: TextFormField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Alex Rivera',
                labelText: 'Your Name (optional)',
                labelStyle: TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
                hintStyle: TextStyle(color: Color(0xFF6E6E6E), fontSize: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                prefixIcon: Icon(Icons.person_outline, size: 18, color: Color(0xFFAAAAAA)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: TextFormField(
              controller: _companyController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'TechCorp / Startup',
                labelText: 'Company / Team (optional)',
                labelStyle: TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
                hintStyle: TextStyle(color: Color(0xFF6E6E6E), fontSize: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                prefixIcon: Icon(Icons.business_outlined, size: 18, color: Color(0xFFAAAAAA)),
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: _buildSubmitButton(),
        ),
      ],
    );
  }

  /// Join Button with Animated Wheel & Tick / Untick Transition
  Widget _buildSubmitButton() {
    Widget buttonContent;

    switch (_wheelState) {
      case WaitlistWheelState.spinning:
        buttonContent = Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            AnimatedWheelBadge(
              size: 18,
              state: WaitlistWheelState.spinning,
              strokeWidth: 2.2,
              primaryColor: Colors.black,
            ),
            SizedBox(width: 8),
            Text(
              'Securing...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ],
        );
        break;
      case WaitlistWheelState.successTick:
        buttonContent = Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            AnimatedWheelBadge(
              size: 18,
              state: WaitlistWheelState.successTick,
              strokeWidth: 2.5,
              successColor: Color(0xFF2E7D32),
            ),
            SizedBox(width: 8),
            Text(
              'Joined! ✓',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2E7D32),
              ),
            ),
          ],
        );
        break;
      case WaitlistWheelState.errorUntick:
        buttonContent = Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            AnimatedWheelBadge(
              size: 18,
              state: WaitlistWheelState.errorUntick,
              strokeWidth: 2.5,
              errorColor: Color(0xFFC62828),
            ),
            SizedBox(width: 8),
            Text(
              'Invalid ✗',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFFC62828),
              ),
            ),
          ],
        );
        break;
      case WaitlistWheelState.idle:
        buttonContent = const Text(
          'Join Waitlist',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
            color: Colors.black,
          ),
        );
        break;
    }

    return ElevatedButton(
      key: const Key('waitlist_submit_button'),
      onPressed: (_isSubmitting || _wheelState == WaitlistWheelState.successTick) ? null : _handleJoinWaitlist,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        ),
      ),
      child: buttonContent,
    );
  }

  Widget _buildFrostedSocialPills() {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        _buildSocialPill(
          icon: Icons.code_rounded,
          label: 'GitHub',
          url: 'https://github.com',
        ),
        _buildSocialPill(
          icon: Icons.layers_outlined,
          label: 'Maven Central',
          url: 'https://central.sonatype.com',
        ),
        _buildSocialPill(
          icon: Icons.alt_route_rounded,
          label: 'Spring Boot 3',
          url: 'https://spring.io',
        ),
      ],
    );
  }

  Widget _buildSocialPill({
    required IconData icon,
    required String label,
    required String url,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: const Color(0xFFD4D4D4)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFD4D4D4),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      key: const Key('waitlist_success_banner'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFF7043).withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFF7043).withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF7043).withValues(alpha: 0.35),
                blurRadius: 30,
              ),
            ],
          ),
          child: const AnimatedWheelBadge(
            size: 48,
            state: WaitlistWheelState.successTick,
            strokeWidth: 3.5,
            successColor: Color(0xFFFF7043),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          _isAlreadyJoined ? "You're already a part of the waitlist!" : "You're on the Waitlist!",
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isAlreadyJoined
              ? "Good news — your email is already registered in our database! We have your spot reserved, so no duplicate confirmation email was sent."
              : (_successMessage ?? "Confirmation dispatched to your email."),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Text(
            _isAlreadyJoined
                ? 'Status: Verified Existing Member (Priority Active)'
                : 'Status: Early Access Queue Priority Active',
            style: const TextStyle(
              color: Color(0xFFFF7043),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 22),
        TextButton(
          onPressed: _resetForm,
          child: Text(
            _isAlreadyJoined ? 'Try another email →' : 'Register another email →',
            style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
          ),
        ),
      ],
    );
  }

  /// Huge Outlined Typographic Backdrop: "Waitlist" (matching Framer reference)
  Widget _buildArchitecturalOutlinedText(bool isMobile) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          'Waitlist',
          style: TextStyle(
            fontSize: isMobile ? 90 : 160,
            fontWeight: FontWeight.w900,
            letterSpacing: -4,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = isMobile ? 1.5 : 2.0
              ..color = Colors.white.withValues(alpha: 0.12),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesSection(bool isMobile) {
    final features = [
      {
        'icon': Icons.bolt_rounded,
        'title': 'Zero Ingestion Latency',
        'desc': 'Asynchronous ring buffer pushes 5xx errors without blocking user requests or adding thread overhead.',
      },
      {
        'icon': Icons.security_rounded,
        'title': 'Automated PII Redaction',
        'desc': 'Scrubs sensitive cookies, authorization tokens, passwords, and secrets before events leave the host JVM.',
      },
      {
        'icon': Icons.replay_rounded,
        'title': '1-Click Request Replay',
        'desc': 'Re-execute failed HTTP requests against local dev or staging environments with full SSRF guardrails.',
      },
    ];

    return Column(
      children: [
        const Text(
          'BUILT SPECIFICALLY FOR SPRING BOOT DEVELOPERS',
          style: TextStyle(
            color: Color(0xFFFF7043),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Everything you need to triage backend failures',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: features.map((f) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  width: isMobile ? double.infinity : 260,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF7043).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(f['icon'] as IconData, color: const Color(0xFFFF7043), size: 20),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        f['title'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        f['desc'] as String,
                        style: const TextStyle(
                          color: Color(0xFFA3A3A3),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildIntegrationPreview(bool isMobile) {
    const sampleConfig = 'eventdock:\n'
        '  enabled: true\n'
        '  endpoint: "https://api.eventdock.swynx.dev"\n'
        '  api-key: "\${EVENTDOCK_API_KEY}"\n'
        '  min-status-code: 500\n'
        '  redaction:\n'
        '    headers: ["authorization", "cookie", "x-api-key"]';

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 18 : 28),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Spring Boot Configuration',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Zero custom middleware. Drop eventdock-starter into your pom.xml and declare your key.',
                style: TextStyle(color: Color(0xFFA3A3A3), fontSize: 13),
              ),
              SizedBox(height: 16),
              CodeSnippetBox(
                label: 'src/main/resources/application.yml',
                content: sampleConfig,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(bool isMobile) {
    return Container(
      padding: const EdgeInsets.only(top: 24, bottom: 20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _scrollToTop,
                    child: Tooltip(
                      message: 'EventDock • Back to top',
                      child: EventDockLogo(
                        height: 38,
                        fontSize: 22,
                        isDark: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _scrollToTop,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Early Access',
                        style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
                      ),
                    ),
                    const Text('•', style: TextStyle(color: Color(0xFF555555), fontSize: 12)),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Spring Boot Starter',
                        style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
                      ),
                    ),
                    const Text('•', style: TextStyle(color: Color(0xFF555555), fontSize: 12)),
                    TextButton(
                      onPressed: _scrollToTop,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Top ↑',
                        style: TextStyle(color: Color(0xFFFF7043), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '© 2026 EventDock • All rights reserved',
                  style: TextStyle(color: Color(0xFF666666), fontSize: 11),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _scrollToTop,
                    child: Tooltip(
                      message: 'EventDock • Back to top',
                      child: EventDockLogo(
                        height: 44,
                        fontSize: 26,
                        isDark: true,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: Wrap(
                        spacing: 20,
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          TextButton(
                            onPressed: _scrollToTop,
                            child: const Text(
                              'Waitlist',
                              style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'Spring Boot 3.x Starter',
                              style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
                            ),
                          ),
                          TextButton(
                            onPressed: _scrollToTop,
                            child: const Text(
                              'Back to Top ↑',
                              style: TextStyle(color: Color(0xFFFF7043), fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Text(
                  '© 2026 EventDock • Early Access',
                  style: TextStyle(color: Color(0xFF777777), fontSize: 12),
                ),
              ],
            ),
    );
  }
}

/// Custom Background Painter creating the organic glowing neon amber ribbon from the reference image
class _GlowRibbonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Top Center Amber Flare
    final topFlare = Paint()
      ..color = const Color(0xFFFF7043).withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.16),
        width: size.width * 0.8,
        height: 260,
      ),
      topFlare,
    );

    // 2. Right Nebula Ray
    final rightNebula = Paint()
      ..color = const Color(0xFFFFAB40).withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120);

    canvas.drawCircle(
      Offset(size.width * 0.68, size.height * 0.14),
      190,
      rightNebula,
    );

    // 3. Curved dynamic glowing light ribbons (matching the user's reference image!)
    final ribbonPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4)
      ..shader = ui.Gradient.linear(
        Offset(size.width * 0.15, size.height * 0.22),
        Offset(size.width * 0.85, size.height * 0.12),
        [
          Colors.transparent,
          const Color(0xFFFF7043).withValues(alpha: 0.9),
          const Color(0xFFFFD54F),
          const Color(0xFFFF7043).withValues(alpha: 0.6),
          Colors.transparent,
        ],
        [0.0, 0.35, 0.6, 0.85, 1.0],
      );

    final path1 = Path()
      ..moveTo(size.width * 0.15, size.height * 0.26)
      ..cubicTo(
        size.width * 0.35, size.height * 0.08,
        size.width * 0.65, size.height * 0.28,
        size.width * 0.85, size.height * 0.10,
      );
    canvas.drawPath(path1, ribbonPaint);

    final path2 = Path()
      ..moveTo(size.width * 0.22, size.height * 0.28)
      ..cubicTo(
        size.width * 0.42, size.height * 0.10,
        size.width * 0.68, size.height * 0.24,
        size.width * 0.90, size.height * 0.12,
      );
    canvas.drawPath(path2, ribbonPaint..strokeWidth = 2.0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Animated Wheel Badge widget that supports:
/// - spinning wheel (continuous rotation)
/// - successTick (springing checkmark tick drawing ✓)
/// - errorUntick (drawing cross untick ✗)
class AnimatedWheelBadge extends StatefulWidget {
  final double size;
  final WaitlistWheelState state;
  final double strokeWidth;
  final Color primaryColor;
  final Color successColor;
  final Color errorColor;

  const AnimatedWheelBadge({
    super.key,
    this.size = 22,
    required this.state,
    this.strokeWidth = 2.5,
    this.primaryColor = const Color(0xFFFF7043),
    this.successColor = const Color(0xFF00E676),
    this.errorColor = const Color(0xFFFF5252),
  });

  @override
  State<AnimatedWheelBadge> createState() => _AnimatedWheelBadgeState();
}

class _AnimatedWheelBadgeState extends State<AnimatedWheelBadge> with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _resultController;
  late Animation<double> _resultAnimation;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _resultAnimation = CurvedAnimation(
      parent: _resultController,
      curve: Curves.easeOutBack,
    );

    _updateState(widget.state);
  }

  @override
  void didUpdateWidget(covariant AnimatedWheelBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _updateState(widget.state);
    }
  }

  void _updateState(WaitlistWheelState state) {
    if (state == WaitlistWheelState.spinning) {
      _resultController.reset();
      _spinController.repeat();
    } else if (state == WaitlistWheelState.successTick || state == WaitlistWheelState.errorUntick) {
      _spinController.stop();
      _resultController.forward(from: 0.0);
    } else {
      _spinController.stop();
      _spinController.reset();
      _resultController.reset();
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_spinController, _resultAnimation]),
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _WheelTickUntickPainter(
            spinProgress: _spinController.value,
            resultProgress: _resultAnimation.value,
            state: widget.state,
            strokeWidth: widget.strokeWidth,
            primaryColor: widget.primaryColor,
            successColor: widget.successColor,
            errorColor: widget.errorColor,
          ),
        );
      },
    );
  }
}

class _WheelTickUntickPainter extends CustomPainter {
  final double spinProgress;
  final double resultProgress;
  final WaitlistWheelState state;
  final double strokeWidth;
  final Color primaryColor;
  final Color successColor;
  final Color errorColor;

  _WheelTickUntickPainter({
    required this.spinProgress,
    required this.resultProgress,
    required this.state,
    required this.strokeWidth,
    required this.primaryColor,
    required this.successColor,
    required this.errorColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final minDim = size.width < size.height ? size.width : size.height;
    final radius = (minDim / 2) - (strokeWidth / 2);

    if (state == WaitlistWheelState.spinning) {
      // Background subtle track
      final trackPaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 0.8;
      canvas.drawCircle(center, radius, trackPaint);

      // Spinning neon arc
      const sweepAngle = 3.14159 * 1.4;
      final startAngle = spinProgress * 2 * 3.14159;
      final arcPaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        arcPaint,
      );
    } else if (state == WaitlistWheelState.successTick) {
      // Completed full circle ring
      final ringPaint = Paint()
        ..color = successColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(center, radius, ringPaint);

      // Drawing animated TICK (checkmark)
      if (resultProgress > 0) {
        final tickPaint = Paint()
          ..color = successColor
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = strokeWidth * 1.15;

        final p1 = Offset(size.width * 0.28, size.height * 0.52);
        final p2 = Offset(size.width * 0.44, size.height * 0.68);
        final p3 = Offset(size.width * 0.74, size.height * 0.36);

        final path = Path();
        if (resultProgress <= 0.4) {
          final t = resultProgress / 0.4;
          path.moveTo(p1.dx, p1.dy);
          path.lineTo(
            p1.dx + (p2.dx - p1.dx) * t,
            p1.dy + (p2.dy - p1.dy) * t,
          );
        } else {
          final t = (resultProgress - 0.4) / 0.6;
          path.moveTo(p1.dx, p1.dy);
          path.lineTo(p2.dx, p2.dy);
          path.lineTo(
            p2.dx + (p3.dx - p2.dx) * t,
            p2.dy + (p3.dy - p2.dy) * t,
          );
        }
        canvas.drawPath(path, tickPaint);
      }
    } else if (state == WaitlistWheelState.errorUntick) {
      // Error ring
      final ringPaint = Paint()
        ..color = errorColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(center, radius, ringPaint);

      // Drawing animated UNTICK (cross)
      if (resultProgress > 0) {
        final crossPaint = Paint()
          ..color = errorColor
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = strokeWidth * 1.1;

        final p1 = Offset(size.width * 0.32, size.height * 0.32);
        final p2 = Offset(size.width * 0.68, size.height * 0.68);
        final p3 = Offset(size.width * 0.68, size.height * 0.32);
        final p4 = Offset(size.width * 0.32, size.height * 0.68);

        final path = Path();
        if (resultProgress <= 0.5) {
          final t = resultProgress / 0.5;
          path.moveTo(p1.dx, p1.dy);
          path.lineTo(
            p1.dx + (p2.dx - p1.dx) * t,
            p1.dy + (p2.dy - p1.dy) * t,
          );
        } else {
          final t = (resultProgress - 0.5) / 0.5;
          path.moveTo(p1.dx, p1.dy);
          path.lineTo(p2.dx, p2.dy);
          path.moveTo(p3.dx, p3.dy);
          path.lineTo(
            p3.dx + (p4.dx - p3.dx) * t,
            p4.dy + (p4.dy - p3.dy) * t,
          );
        }
        canvas.drawPath(path, crossPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WheelTickUntickPainter oldDelegate) {
    return oldDelegate.spinProgress != spinProgress ||
        oldDelegate.resultProgress != resultProgress ||
        oldDelegate.state != state;
  }
}
