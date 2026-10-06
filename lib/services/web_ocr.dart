import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;
import 'ocr_result.dart';

/// WEB ONLY. Reads text from a picture inside the browser with Tesseract.js
/// (loaded by web/index.html). The photo is not uploaded anywhere.
///
/// A tiny JavaScript helper is added to the page the first time it is needed.
/// It uses "sparse text" mode, which is much better for business cards because
/// it treats every block of text on its own instead of reading across columns.
const _bridgeJs = r'''
window.cardlinkOcr = async function (bytes) {
  if (typeof Tesseract === 'undefined') {
    throw new Error('the reading engine did not load (internet problem or blocked)');
  }
  const blob = new Blob([bytes], { type: 'image/png' });
  const attempts = [
    {},
    { langPath: 'https://cdn.jsdelivr.net/npm/@tesseract.js-data/eng/4.0.0_best_int' }
  ];
  let lastError;
  for (const opts of attempts) {
    let worker;
    try {
      worker = await Tesseract.createWorker('eng', 1, opts);
      await worker.setParameters({
        tessedit_pageseg_mode: '11',
        preserve_interword_spaces: '1'
      });
      const result = await worker.recognize(blob);
      const data = result.data || {};
      await worker.terminate();
      const lines = (data.lines || []).map(function (l) {
        const b = l.bbox || {};
        return { text: (l.text || '').trim(), l: b.x0, t: b.y0, r: b.x1, b: b.y1 };
      });
      return JSON.stringify({ text: data.text || '', tsv: data.tsv || '', lines: lines });
    } catch (e) {
      lastError = e;
      try { if (worker) { await worker.terminate(); } } catch (_) {}
    }
  }
  throw new Error(String(lastError && lastError.message ? lastError.message : lastError));
};
''';

@JS('cardlinkOcr')
external JSPromise<JSString> _cardlinkOcr(JSUint8Array bytes);

bool _installed = false;

void _installBridge() {
  if (_installed) return;
  final script = web.document.createElement('script') as web.HTMLScriptElement;
  script.textContent = _bridgeJs;
  web.document.head!.appendChild(script);
  _installed = true;
}

Future<OcrResult> webOcr(Uint8List imageBytes) async {
  _installBridge();
  final jsonText = (await _cardlinkOcr(imageBytes.toJS).toDart).toDart;
  return OcrResult.fromJson(jsonDecode(jsonText) as Map<String, dynamic>);
}
