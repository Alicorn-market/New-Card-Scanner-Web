import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

/// WEB ONLY. Makes the browser download a file.
void downloadBytes(String filename, Uint8List bytes, String mimeType) {
  final blob = web.Blob(<JSAny>[bytes.toJS].toJS, web.BlobPropertyBag(type: mimeType));
  final url = web.URL.createObjectURL(blob);
  final anchor = (web.document.createElement('a') as web.HTMLAnchorElement)
    ..href = url
    ..download = filename;
  web.document.body!.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}

void downloadText(String filename, String text, String mimeType) =>
    downloadBytes(filename, Uint8List.fromList(utf8.encode(text)), mimeType);
