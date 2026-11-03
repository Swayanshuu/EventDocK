import 'package:flutter/material.dart';
import '../models/auth_state.dart';
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
      default:
        return AuthMode.signIn;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0D12),
      body: SafeArea(
        child: SplitAuthCard(
          onAuthSuccess: widget.onLoginSuccess,
          initialRole: AuthRole.individual,
          initialMode: _mapInitialMode(widget.initialMode),
        ),
      ),
    );
  }
}
