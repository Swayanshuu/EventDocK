import 'auth_interop_stub.dart'
    if (dart.library.js_interop) 'auth_interop_web.dart' as platform;

Future<String?> platformGoogleSignIn() => platform.platformGoogleSignIn();

void platformSignOut() => platform.platformSignOut();
