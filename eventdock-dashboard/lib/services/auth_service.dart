import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_interop.dart' as auth_interop;

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  String? _token;
  String? _userEmail;
  String? _userId;

  String? get token => _token;
  String? get userEmail => _userEmail;
  String? get userId => _userId;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  // Firebase Web Configuration
  final String firebaseApiKey = 'AIzaSyBulU64fSaScUBzVnjv6kk9EwapZOpik7U';
  final String firebaseProjectId = 'eventdock-5cc21';
  final String firebaseAuthDomain = 'eventdock-5cc21.firebaseapp.com';

  /// Authenticate using official Google Sign-In via Firebase popup
  Future<void> signInWithGoogle({int? cliPort}) async {
    if (kIsWeb) {
      final rawResult = await auth_interop.platformGoogleSignIn();
      if (rawResult != null && rawResult.isNotEmpty) {
        final data = jsonDecode(rawResult) as Map<String, dynamic>;
        final token = data['token'] as String?;
        if (token != null && token.isNotEmpty) {
          _token = token;
          _userEmail = data['email'] as String?;
          _userId = data['uid'] as String?;
          notifyListeners();

          if (cliPort != null) {
            await _deliverCliCallback(cliPort);
          }
          return;
        }
      }
      throw Exception('Google Sign-In failed or was cancelled.');
    }

    throw Exception('Google Sign-In is only supported on web browsers.');
  }

  Future<void> _deliverCliCallback(int cliPort) async {
    try {
      final callbackUrl = Uri.parse(
        'http://127.0.0.1:$cliPort/callback?token=$_token&email=$_userEmail',
      );
      await http.get(callbackUrl);
    } catch (_) {
      // Best-effort callback to local CLI listener
    }
  }

  void signOut() {
    if (kIsWeb) {
      auth_interop.platformSignOut();
    }
    _token = null;
    _userEmail = null;
    _userId = null;
    notifyListeners();
  }
}
