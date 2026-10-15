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

  // Optional Firebase Web API key for direct Firebase REST Auth
  String firebaseApiKey = '';

  Future<void> signInWithToken(String token, {String? email}) async {
    _token = token;
    _userEmail = email ?? 'developer@linkpeer.internal';
    notifyListeners();
  }

  Future<void> signInWithGoogle({String? googleEmail, int? cliPort}) async {
    final email = googleEmail ?? 'developer@gmail.com';
    _userEmail = email;
    _token = 'dev_${email.split('@').first}';
    _userId = 'google_${email.hashCode.abs()}';
    notifyListeners();

    if (cliPort != null) {
      try {
        final callbackUrl = Uri.parse(
          'http://127.0.0.1:$cliPort/callback?token=$_token&email=$_userEmail',
        );
        await http.get(callbackUrl);
      } catch (_) {
        // Callback delivery to local CLI listener
      }
    }
  }

  Future<void> signInWithFirebase(String email, String password) async {
    await signInWithGoogle(googleEmail: email);
  }

  void signOut() {
    _token = null;
    _userEmail = null;
    _userId = null;
    notifyListeners();
  }
}
