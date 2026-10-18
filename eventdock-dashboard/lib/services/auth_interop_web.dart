import 'dart:js_interop';

@JS('eventdockGoogleSignIn')
external JSPromise<JSString?> jsEventdockGoogleSignIn();

@JS('eventdockSignOut')
external void jsEventdockSignOut();

Future<String?> platformGoogleSignIn() async {
  try {
    final promise = jsEventdockGoogleSignIn();
    final jsString = await promise.toDart;
    return jsString?.toDart;
  } catch (_) {
    return null;
  }
}

void platformSignOut() {
  try {
    jsEventdockSignOut();
  } catch (_) {}
}
