// Stub implementation of web authentication interop for non-web platforms.
String? _stubSession;

Future<String?> platformGetRestoredUser() async => _stubSession;

void platformSaveSession(String sessionJson, bool rememberMe) {
  _stubSession = sessionJson;
}

void platformClearSession() {
  _stubSession = null;
}

Future<String?> platformSignInWithEmail(
    String email, String password, bool rememberMe) async =>
    null;

Future<String?> platformSignUpWithEmail(
    String email, String password, bool rememberMe) async =>
    null;

Future<String?> platformGoogleSignIn({bool rememberMe = true}) async => null;

void platformSignOut() {
  _stubSession = null;
}
