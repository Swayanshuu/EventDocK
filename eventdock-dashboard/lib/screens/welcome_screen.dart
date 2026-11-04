import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onSignIn;

  const WelcomeScreen({
    super.key,
    required this.onGetStarted,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 700;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeModeNotifier,
      builder: (context, themeMode, _) {
        final isDark = themeMode == ThemeMode.dark;
        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: Column(
              children: [
                // Top Header: Logo & Theme Toggle
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 20 : 40,
                    vertical: 24,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const EventDockLogo(height: 32, fontSize: 20),
                      Tooltip(
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
                    ],
                  ),
                ),

            // Main Content Area
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: isCompact ? 24 : 40),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 580),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Subtle Graphic Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.heroOrange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.heroOrange.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.bolt_rounded, size: 14, color: AppTheme.heroOrange),
                              SizedBox(width: 6),
                              Text(
                                'Real-time API Failure Detection & Reproduction',
                                style: TextStyle(
                                  color: AppTheme.heroOrange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Main Headline
                        Text(
                          'The Developer Platform for Telemetry & Diagnostics',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Supporting Description
                        Text(
                          'Capture microservice HTTP faults, inspect sanitised stack traces, manage workspace API keys, and replay failed production requests seamlessly.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: onGetStarted,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.heroOrange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Get Started',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 16),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            OutlinedButton(
                              onPressed: onSignIn,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.textPrimary,
                                side: BorderSide(color: AppTheme.cardBorder),
                                backgroundColor: AppTheme.cardSecondary,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text(
                                'Sign In',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'EventDock Desktop Studio v1.2.0 • Privacy Policy • Terms of Service',
                    style: TextStyle(color: AppTheme.textSubtle, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
        );
      },
    );
  }
}