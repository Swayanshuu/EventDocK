import 'package:flutter/material.dart';
import '../models/auth_state.dart';
import '../theme/app_theme.dart';
import '../widgets/split_auth_card.dart';

enum AuthViewMode { signIn, signUp, forgotPassword, emailVerification }

class AuthScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final AuthViewMode initialMode;

  const AuthScreen({
    super.key,
    required this.onLoginSuccess,
    this.initialMode = AuthViewMode.signIn,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  AuthMode _mapInitialMode(AuthViewMode viewMode) {
    switch (viewMode) {
      case AuthViewMode.signUp:
        return AuthMode.signUp;
      case AuthViewMode.forgotPassword:
        return AuthMode.forgotPassword;
      case AuthViewMode.signIn:
      case AuthViewMode.emailVerification:
        return AuthMode.signIn;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeModeNotifier,
      builder: (context, themeMode, _) {
        final isDark = themeMode == ThemeMode.dark;
        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: Stack(
              children: [
                SplitAuthCard(
                  onAuthSuccess: widget.onLoginSuccess,
                  initialRole: AuthRole.individual,
                  initialMode: _mapInitialMode(widget.initialMode),
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
          ),
        );
      },
    );
  }
}
