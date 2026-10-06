import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Cuts out the chosen area of the photo, scales it to a good size for reading,
/// and boosts the contrast (grey, light background, dark text). [frac] is the
/// area as fractions of the whole photo, from 0 to 1.
Future<Uint8List> cropAndEnhance(ui.Image src, ui.Rect frac) async {
  final srcRect = ui.Rect.fromLTRB(
    frac.left * src.width,
    frac.top * src.height,
    frac.right * src.width,
    frac.bottom * src.height,
  );
  final targetW = srcRect.width < 1400 ? 1400.0 : (srcRect.width > 2000 ? 2000.0 : srcRect.width);
  final scale = targetW / srcRect.width;
  final outW = (srcRect.width * scale).round();
  final outH = (srcRect.height * scale).round();

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawImageRect(
    src,
    srcRect,
    ui.Rect.fromLTWH(0, 0, outW.toDouble(), outH.toDouble()),
    ui.Paint()..filterQuality = ui.FilterQuality.high,
  );
  final cropped = await recorder.endRecording().toImage(outW, outH);

  try {
    final data = await cropped.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) return _png(cropped);
    final px = Uint8List.fromList(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    final n = outW * outH;
    final gray = Uint8List(n);
    final hist = List<int>.filled(256, 0);
    var sum = 0;
    for (var i = 0, p = 0; i < n; i++, p += 4) {
      final g = (px[p] * 299 + px[p + 1] * 587 + px[p + 2] * 114) ~/ 1000;
      gray[i] = g;
      hist[g]++;
      sum += g;
    }
    final mean = sum / n;
    final cut = (n * 0.02).round();
    var lo = 0, hi = 255, acc = 0;
    for (var v = 0; v < 256; v++) {
      acc += hist[v];
      if (acc >= cut) {
        lo = v;
        break;
      }
    }
    acc = 0;
    for (var v = 255; v >= 0; v--) {
      acc += hist[v];
      if (acc >= cut) {
        hi = v;
        break;
      }
    }
    if (hi - lo < 40) {
      lo = 0;
      hi = 255;
    }
    final range = (hi - lo).toDouble();
    final invert = mean < 110; // light text on a dark card -> dark text on light
    for (var i = 0, p = 0; i < n; i++, p += 4) {
      var v = ((gray[i] - lo) * 255 / range).round();
      if (v < 0) v = 0;
      if (v > 255) v = 255;
      if (invert) v = 255 - v;
      px[p] = v;
      px[p + 1] = v;
      px[p + 2] = v;
      px[p + 3] = 255;
    }
    final done = Completer<ui.Image>();
    ui.decodeImageFromPixels(px, outW, outH, ui.PixelFormat.rgba8888, done.complete);
    return _png(await done.future);
  } catch (_) {
    // If the contrast boost fails for any reason, use the plain cropped picture.
    return _png(cropped);
  }
}

Future<Uint8List> _png(ui.Image img) async {
  final bd = await img.toByteData(format: ui.ImageByteFormat.png);
  if (bd == null) throw Exception('could not prepare the picture');
  return bd.buffer.asUint8List(bd.offsetInBytes, bd.lengthInBytes);
}
