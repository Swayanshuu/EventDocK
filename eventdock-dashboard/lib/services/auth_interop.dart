import 'auth_interop_stub.dart'
    if (dart.library.js_interop) 'auth_interop_web.dart' as platform;

Future<String?> platformGetRestoredUser() => platform.platformGetRestoredUser();

void platformSaveSession(String sessionJson, bool rememberMe) =>
    platform.platformSaveSession(sessionJson, rememberMe);

void platformClearSession() => platform.platformClearSession();

Future<String?> platformSignInWithEmail(
        String email, String password, bool rememberMe) =>
    platform.platformSignInWithEmail(email, password, rememberMe);

Future<String?> platformSignUpWithEmail(
        String email, String password, bool rememberMe) =>
    platform.platformSignUpWithEmail(email, password, rememberMe);

Future<String?> platformGoogleSignIn({bool rememberMe = true}) =>
    platform.platformGoogleSignIn(rememberMe: rememberMe);

void platformSignOut() => platform.platformSignOut();
