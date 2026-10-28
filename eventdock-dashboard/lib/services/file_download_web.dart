import 'dart:js_interop';

@JS('eventdockDownloadFile')
external void jsEventdockDownloadFile(
    JSString filename, JSString content, JSString mimeType);

void platformDownloadFile(String filename, String content, String mimeType) {
  try {
    jsEventdockDownloadFile(filename.toJS, content.toJS, mimeType.toJS);
  } catch (_) {
    // Graceful fallback if interop function is unavailable
  }
}
