import 'file_download_stub.dart'
    if (dart.library.js_interop) 'file_download_web.dart' as platform;

void downloadFile(
  String filename,
  String content, {
  String mimeType = 'text/plain;charset=utf-8',
}) {
  platform.platformDownloadFile(filename, content, mimeType);
}
