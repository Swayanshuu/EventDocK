import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

/// Mandatory Email Verification Gate for EventDock.
/// Prevents unverified users from accessing projects, API keys, or telemetry data.
class EmailVerificationScreen extends StatefulWidget {
  final String userEmail;
  final VoidCallback onVerified;
  final VoidCallback onSignOut;

  const EmailVerificationScreen({
    super.key,
    required this.userEmail,
    required this.onVerified,
    required this.onSignOut,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isChecking = false;
  bool _isResending = false;
  String? _statusMessage;
  bool _isError = false;

  // 60-second resend cooldown timer
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _startCooldown(60);
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    setState(() {
      _cooldownSeconds = seconds;
    });

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        setState(() {
          _cooldownSeconds = 0;
        });
      } else {
        setState(() {
          _cooldownSeconds--;
        });
      }
    });
  }

  Future<void> _handleCheckVerification() async {
    setState(() {
      _isChecking = true;
      _statusMessage = null;
    });

    try {
      final isVerified = await AuthService().checkEmailVerified();
      if (mounted) {
        if (isVerified) {
          widget.onVerified();
        } else {
          setState(() {
            _isError = true;
            _statusMessage = 'Email not verified yet. Please check your inbox (and spam folder) and click the verification link.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _statusMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _handleResendVerification() async {
    if (_cooldownSeconds > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _statusMessage = null;
    });

    try {
      await AuthService().sendEmailVerification();
      if (mounted) {
        setState(() {
          _isError = false;
          _statusMessage = 'A fresh verification link has been sent to ${widget.userEmail}.';
        });
        _startCooldown(60);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _statusMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeModeNotifier,
      builder: (context, themeMode, _) {
        final isDark = themeMode == ThemeMode.dark;
        final bgColor = isDark ? AppTheme.background : AppTheme.lightBackground;
        final cardBg = isDark ? AppTheme.card : AppTheme.lightCard;
        final borderColor = isDark ? AppTheme.cardBorder : AppTheme.lightCardBorder;
        final textPrimary = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
        final textMuted = isDark ? AppTheme.textMuted : AppTheme.lightTextMuted;

        return Scaffold(
          backgroundColor: bgColor,
          body: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 520),
                    padding: const EdgeInsets.all(36),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderColor, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                          blurRadius: 32,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Brand Logo Header
                const Center(
                  child: EventDockLogo(height: 32, fontSize: 18),
                ),
                const SizedBox(height: 24),

                // Top Email Icon
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.heroOrange.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.heroOrange.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.mark_email_unread_outlined,
                      size: 36,
                      color: AppTheme.heroOrange,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Heading
                Text(
                  'Verify Your Email Address',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 12),

                // Subtitle
                Text(
                  'Before you can access the dashboard or deploy the EventDock starter, please verify your email address.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: textMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),

                // Email Container Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.cardSecondary : AppTheme.lightCardSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.email_outlined, size: 16, color: AppTheme.heroOrange),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.userEmail,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Dynamic Status Banner
                if (_statusMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isError
                          ? AppTheme.status5xx.withValues(alpha: 0.12)
                          : AppTheme.status2xx.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _isError
                            ? AppTheme.status5xx.withValues(alpha: 0.3)
                            : AppTheme.status2xx.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _isError ? Icons.error_outline : Icons.check_circle_outline,
                          size: 16,
                          color: _isError ? AppTheme.status5xx : AppTheme.status2xx,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _statusMessage!,
                            style: TextStyle(
                              fontSize: 12,
                              color: _isError ? AppTheme.status5xx : AppTheme.status2xx,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Action 1: "I've Verified My Email" Primary Button
                ElevatedButton(
                  onPressed: _isChecking ? null : _handleCheckVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.heroOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isChecking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          "I've Verified My Email — Continue",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                ),
                const SizedBox(height: 12),

                // Action 2: "Resend Verification Email" with Cooldown
                OutlinedButton.icon(
                  onPressed: (_cooldownSeconds > 0 || _isResending)
                      ? null
                      : _handleResendVerification,
                  icon: _isResending
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(
                    _cooldownSeconds > 0
                        ? 'Resend email in ${_cooldownSeconds}s'
                        : 'Resend Verification Email',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textPrimary,
                    side: BorderSide(color: borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                const Divider(),
                const SizedBox(height: 12),

                // Action 3: Sign Out / Change Email Link
                Center(
                  child: TextButton.icon(
                    onPressed: widget.onSignOut,
                    icon: const Icon(Icons.arrow_back_rounded, size: 14),
                    label: const Text(
                      'Sign out or use different email',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
        Positioned(
          top: 16,
          right: 20,
          child: Tooltip(
            message: isDark ? 'Switch to Light Mode (White & Orange)' : 'Switch to Dark Mode (Black & Orange)',
            child: InkWell(
              onTap: () {
                AppTheme.toggleThemeMode();
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.cardSecondary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Center(
                  child: Icon(
                    isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    size: 18,
                    color: AppTheme.heroOrange,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
      },
    );
  }
}

