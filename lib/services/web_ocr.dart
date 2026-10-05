import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

/// WEB ONLY. Uses Tesseract.js (loaded by web/index.html) to read text from a
/// picture, inside the browser. The photo is not uploaded anywhere.
@JS('Tesseract.recognize')
external JSPromise<JSObject> _recognizeDefault(JSAny image, String language);

@JS('Tesseract.recognize')
external JSPromise<JSObject> _recognizeWith(JSAny image, String language, JSAny options);

// A second place to get the English reading data from, used only if the first one fails.
const _altLangPath = 'https://cdn.jsdelivr.net/npm/@tesseract.js-data/eng/4.0.0_best_int';

String _text(JSObject result) {
  final data = result.getProperty<JSObject>('data'.toJS);
  return data.getProperty<JSString>('text'.toJS).toDart;
}

Future<String> webOcr(Uint8List imageBytes) async {
  final engine = globalContext.getProperty<JSAny?>('Tesseract'.toJS);
  if (engine == null) {
    throw Exception('the reading engine did not load (internet problem or blocked)');
  }
  final blob = web.Blob(<JSAny>[imageBytes.toJS].toJS);
  try {
    return _text(await _recognizeDefault(blob, 'eng').toDart);
  } catch (first) {
    try {
      final options = <String, String>{'langPath': _altLangPath}.jsify()!;
      return _text(await _recognizeWith(blob, 'eng', options).toDart);
    } catch (second) {
      throw Exception('$first | retry: $second');
    }
  }
}
