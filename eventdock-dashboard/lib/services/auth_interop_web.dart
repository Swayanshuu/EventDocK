import 'dart:js_interop';

@JS('eventdockGetRestoredUser')
external JSPromise<JSString?> jsEventdockGetRestoredUser();

@JS('eventdockSaveSession')
external void jsEventdockSaveSession(JSString sessionJson, JSBoolean rememberMe);

@JS('eventdockClearSession')
external void jsEventdockClearSession();

@JS('eventdockSignInWithEmail')
external JSPromise<JSString?> jsEventdockSignInWithEmail(
    JSString email, JSString password, JSBoolean rememberMe);

@JS('eventdockSignUpWithEmail')
external JSPromise<JSString?> jsEventdockSignUpWithEmail(
    JSString email, JSString password, JSBoolean rememberMe);

@JS('eventdockGoogleSignIn')
external JSPromise<JSString?> jsEventdockGoogleSignIn(JSBoolean? rememberMe);

@JS('eventdockSignOut')
external void jsEventdockSignOut();

Future<String?> platformGetRestoredUser() async {
  try {
    final promise = jsEventdockGetRestoredUser();
    final jsString = await promise.toDart;
    return jsString?.toDart;
  } catch (_) {
    return null;
  }
}

void platformSaveSession(String sessionJson, bool rememberMe) {
  try {
    jsEventdockSaveSession(sessionJson.toJS, rememberMe.toJS);
  } catch (_) {}
}

void platformClearSession() {
  try {
    jsEventdockClearSession();
  } catch (_) {}
}

Future<String?> platformSignInWithEmail(
    String email, String password, bool rememberMe) async {
  try {
    final promise = jsEventdockSignInWithEmail(
      email.toJS,
      password.toJS,
      rememberMe.toJS,
    );
    final jsString = await promise.toDart;
    return jsString?.toDart;
  } catch (_) {
    return null;
  }
}

Future<String?> platformSignUpWithEmail(
    String email, String password, bool rememberMe) async {
  try {
    final promise = jsEventdockSignUpWithEmail(
      email.toJS,
      password.toJS,
      rememberMe.toJS,
    );
    final jsString = await promise.toDart;
    return jsString?.toDart;
  } catch (_) {
    return null;
  }
}

Future<String?> platformGoogleSignIn({bool rememberMe = true}) async {
  try {
    final promise = jsEventdockGoogleSignIn(rememberMe.toJS);
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
