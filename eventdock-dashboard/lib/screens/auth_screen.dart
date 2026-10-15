import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const AuthScreen({super.key, required this.onLoginSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController(text: 'developer@gmail.com');
  final _tokenController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _showTokenInput = false;
  bool _showCustomGoogleEmail = false;
  int? _cliPort;

  @override
  void initState() {
    super.initState();
    final queryParams = Uri.base.queryParameters;
    if (queryParams.containsKey('cli_port')) {
      _cliPort = int.tryParse(queryParams['cli_port']!);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_showTokenInput) {
        if (_tokenController.text.trim().isEmpty) {
          throw Exception('Please paste a valid Google ID token');
        }
        await AuthService().signInWithToken(
          _tokenController.text.trim(),
          email: _emailController.text.trim(),
        );
      } else {
        final email = _showCustomGoogleEmail && _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : 'developer@gmail.com';
        await AuthService().signInWithGoogle(googleEmail: email, cliPort: _cliPort);
      }
      widget.onLoginSuccess();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 500;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            padding: EdgeInsets.all(isMobile ? 22 : 36),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.cardBorder, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // EventDock Official Wordmark Branding
                const Center(
                  child: EventDockLogo(height: 36, fontSize: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  'API Failure Detection & Reproduction',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: isMobile ? 12 : 13,
                    letterSpacing: 0.1,
                  ),
                ),

                // Terminal callback banner if invoked from CLI
                if (_cliPort != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.terminal_rounded, color: AppTheme.primary, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Terminal session on port $_cliPort. Signing in will authenticate your CLI.',
                            style: const TextStyle(fontSize: 11, color: AppTheme.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.status5xx.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.status5xx.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppTheme.status5xx, fontSize: 13),
                    ),
                  ),

                if (!_showTokenInput) ...[
                  // Prominent Google Login Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1F1F1F),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildGoogleLogo(),
                              const SizedBox(width: 12),
                              const Flexible(
                                child: Text(
                                  'Sign in with Google',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: Color(0xFF1F1F1F),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                  ),

                  if (_showCustomGoogleEmail) ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Google Account Email',
                        hintText: 'e.g. yourname@gmail.com',
                        prefixIcon: Icon(Icons.account_circle_outlined, size: 18),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        setState(() => _showCustomGoogleEmail = !_showCustomGoogleEmail);
                      },
                      child: Text(
                        _showCustomGoogleEmail
                            ? 'Use default Google test account'
                            : 'Sign in with another Google email',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                    ),
                  ),
                ] else ...[
                  // Token Input Mode
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Google Account Email',
                      prefixIcon: Icon(Icons.person_outline, size: 18),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _tokenController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Google Auth ID Token',
                      hintText: 'Paste Google JWT or dev_token',
                      prefixIcon: Icon(Icons.key_outlined, size: 18),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Text('Authenticate with Token', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],

                const SizedBox(height: 16),
                const Divider(color: AppTheme.cardBorder),
                const SizedBox(height: 8),

                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _showTokenInput = !_showTokenInput;
                        _errorMessage = null;
                      });
                    },
                    child: Text(
                      _showTokenInput ? '← Back to Google Sign In' : 'Sign in with Google ID Token →',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
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

  Widget _buildGoogleLogo() {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontWeight: FontWeight.bold,
          fontSize: 16,
          fontFamily: 'sans-serif',
        ),
      ),
    );
  }
}
