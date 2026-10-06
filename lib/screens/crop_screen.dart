import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/image_prep.dart';
import '../theme.dart';

double _cl(double v, double lo, double hi) => v < lo ? lo : (v > hi ? hi : v);

/// Shows the photo with a frame and grid. Drag the corners (or the whole frame)
/// so that only the card is inside, then tap USE THIS AREA.
class CropScreen extends StatefulWidget {
  const CropScreen({super.key, required this.imageBytes});
  final Uint8List imageBytes;

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  static const _startFrame = Rect.fromLTRB(0.05, 0.2, 0.95, 0.8);
  ui.Image? _image;
  Rect _crop = _startFrame; // as fractions of the photo (0 to 1)
  Rect _display = Rect.zero; // where the photo is drawn on screen
  int _drag = -1; // 0 TL, 1 TR, 2 BL, 3 BR, 4 move, -1 nothing
  bool _working = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.imageBytes);
      final frame = await codec.getNextFrame();
      if (!mounted) return;
      setState(() => _image = frame.image);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'This photo could not be opened. Please go back and try another one.');
      }
    }
  }

  Future<void> _rotate() async {
    final img = _image;
    if (img == null) return;
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    canvas.translate(img.height.toDouble(), 0);
    canvas.rotate(math.pi / 2);
    canvas.drawImage(img, Offset.zero, Paint());
    final rotated = await rec.endRecording().toImage(img.height, img.width);
    if (!mounted) return;
    setState(() {
      _image = rotated;
      _crop = _startFrame;
    });
  }

  Rect _fit(Size area, ui.Image img) {
    final s = math.min(area.width / img.width, area.height / img.height);
    final w = img.width * s;
    final h = img.height * s;
    return Rect.fromLTWH((area.width - w) / 2, (area.height - h) / 2, w, h);
  }

  Rect _screenRect() => Rect.fromLTRB(
        _display.left + _crop.left * _display.width,
        _display.top + _crop.top * _display.height,
        _display.left + _crop.right * _display.width,
        _display.top + _crop.bottom * _display.height,
      );

  void _start(Offset p) {
    final r = _screenRect();
    const grab = 44.0;
    final corners = [r.topLeft, r.topRight, r.bottomLeft, r.bottomRight];
    var best = -1;
    var bestDist = grab;
    for (var i = 0; i < 4; i++) {
      final d = (corners[i] - p).distance;
      if (d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    if (best >= 0) {
      _drag = best;
    } else if (r.inflate(10).contains(p)) {
      _drag = 4;
    } else {
      _drag = -1;
    }
  }

  void _update(Offset delta) {
    if (_drag < 0 || _display.width == 0 || _display.height == 0) return;
    final dx = delta.dx / _display.width;
    final dy = delta.dy / _display.height;
    var l = _crop.left, t = _crop.top, r = _crop.right, b = _crop.bottom;
    const minSize = 0.12;
    switch (_drag) {
      case 0:
        l += dx;
        t += dy;
      case 1:
        r += dx;
        t += dy;
      case 2:
        l += dx;
        b += dy;
      case 3:
        r += dx;
        b += dy;
      case 4:
        final w = r - l;
        final h = b - t;
        l = _cl(l + dx, 0, 1 - w);
        t = _cl(t + dy, 0, 1 - h);
        r = l + w;
        b = t + h;
    }
    if (_drag != 4) {
      l = _cl(l, 0, r - minSize);
      r = _cl(r, l + minSize, 1);
      t = _cl(t, 0, b - minSize);
      b = _cl(b, t + minSize, 1);
    }
    setState(() => _crop = Rect.fromLTRB(l, t, r, b));
  }

  Future<void> _use({bool whole = false}) async {
    final img = _image;
    if (img == null) return;
    setState(() => _working = true);
    try {
      final bytes = await cropAndEnhance(img, whole ? const Rect.fromLTRB(0, 0, 1, 1) : _crop);
      if (mounted) context.pop(bytes);
    } catch (_) {
      if (mounted) {
        setState(() => _working = false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('The photo could not be prepared. Please try again.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: const Text('Frame the card'),
          actions: [
            IconButton(
              icon: const Icon(Icons.rotate_90_degrees_cw),
              tooltip: 'Rotate',
              onPressed: (_image == null || _working) ? null : _rotate,
            ),
          ],
        ),
        body: _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_error!, style: const TextStyle(color: Colors.white)),
                ),
              )
            : _image == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: Text(
                          'Drag the corners so only the card is inside the frame. Use the rotate button if the card is sideways.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: LayoutBuilder(builder: (context, cons) {
                          _display = _fit(Size(cons.maxWidth, cons.maxHeight), _image!);
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanStart: (d) => _start(d.localPosition),
                            onPanUpdate: (d) => _update(d.delta),
                            onPanEnd: (_) => _drag = -1,
                            child: Stack(children: [
                              Positioned.fromRect(
                                rect: _display,
                                child: RawImage(image: _image, fit: BoxFit.fill),
                              ),
                              Positioned.fill(child: CustomPaint(painter: _CropPainter(_screenRect()))),
                            ]),
                          );
                        }),
                      ),
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            FilledButton(
                              onPressed: _working ? null : () => _use(),
                              child: Text(_working ? 'Preparing…' : 'USE THIS AREA'),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: _working ? null : () => _use(whole: true),
                                  child: const Text('Use the whole photo'),
                                ),
                                TextButton(
                                  onPressed: _working ? null : () => context.pop(),
                                  child: const Text('Cancel'),
                                ),
                              ],
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ),
      );
}

class _CropPainter extends CustomPainter {
  _CropPainter(this.rect);
  final Rect rect;

  @override
  void paint(Canvas canvas, Size size) {
    final full = Path()..addRect(Offset.zero & size);
    final hole = Path()..addRect(rect);
    canvas.drawPath(
      Path.combine(PathOperation.difference, full, hole),
      Paint()..color = const Color(0x99000000),
    );
    final grid = Paint()
      ..color = const Color(0x99FFFFFF)
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      final x = rect.left + rect.width * i / 3;
      final y = rect.top + rect.height * i / 3;
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), grid);
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), grid);
    }
    canvas.drawRect(
      rect,
      Paint()
        ..color = teal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    for (final p in [rect.topLeft, rect.topRight, rect.bottomLeft, rect.bottomRight]) {
      canvas.drawCircle(p, 12, Paint()..color = Colors.white);
      canvas.drawCircle(
        p,
        12,
        Paint()
          ..color = teal
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CropPainter old) => old.rect != rect;
}
