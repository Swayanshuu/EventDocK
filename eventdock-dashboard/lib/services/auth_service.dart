import 'dart:convert';
import 'dart:js_util' as js_util;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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

  Future<void> signInWithToken(String token, {String? email}) async {
    _token = token;
    _userEmail = email ?? 'developer@eventdock.swynx.dev';
    notifyListeners();
  }

  Future<void> signInWithGoogle({String? googleEmail, int? cliPort}) async {
    if (kIsWeb) {
      try {
        final jsPromise = js_util.callMethod(js_util.globalThis, 'eventdockGoogleSignIn', []);
        if (jsPromise != null) {
          final dynamic rawResult = await js_util.promiseToFuture(jsPromise);
          if (rawResult != null && rawResult.toString().isNotEmpty) {
            final data = jsonDecode(rawResult.toString()) as Map<String, dynamic>;
            _token = data['token'] as String?;
            _userEmail = data['email'] as String?;
            _userId = data['uid'] as String?;
            notifyListeners();

            if (cliPort != null && _token != null) {
              await _deliverCliCallback(cliPort);
            }
            return;
          }
        }
      } catch (e) {
        debugPrint('[AuthService] Firebase Google Sign-In error: $e');
      }
    }

    // Fallback for non-web or local dev preview
    final email = googleEmail ?? 'developer@gmail.com';
    _userEmail = email;
    _token = 'dev_${email.split('@').first}';
    _userId = 'google_${email.hashCode.abs()}';
    notifyListeners();

    if (cliPort != null) {
      await _deliverCliCallback(cliPort);
    }
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

  Future<void> signInWithFirebase(String email, String password) async {
    await signInWithGoogle(googleEmail: email);
  }

  void signOut() {
    if (kIsWeb) {
      try {
        js_util.callMethod(js_util.globalThis, 'eventdockSignOut', []);
      } catch (_) {}
    }
    _token = null;
    _userEmail = null;
    _userId = null;
    notifyListeners();
  }
}
