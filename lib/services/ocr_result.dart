import 'dart:math' as math;

/// One piece of text found on the card, with where it sits in the photo.
class OcrLine {
  OcrLine(this.text, this.left, this.top, this.right, this.bottom);
  final String text;
  final double left, top, right, bottom;
  double get height => bottom - top;
}

class _W {
  _W(this.text, this.left, this.top, this.right, this.bottom);
  final String text;
  final double left, top, right, bottom;
}

class OcrResult {
  OcrResult(this.text, this.lines);
  final String text;
  final List<OcrLine> lines;

  factory OcrResult.fromJson(Map<String, dynamic> m) {
    final text = (m['text'] ?? '').toString();
    var lines = linesFromTsv((m['tsv'] ?? '').toString());
    if (lines.isEmpty && m['lines'] is List) {
      for (final e in (m['lines'] as List)) {
        if (e is! Map) continue;
        final t = (e['text'] ?? '').toString().trim();
        if (t.isEmpty) continue;
        lines.add(OcrLine(t, _d(e['l']), _d(e['t']), _d(e['r']), _d(e['b'])));
      }
      lines = _ordered(lines);
    }
    return OcrResult(text, lines);
  }

  static double _d(dynamic v) => v is num ? v.toDouble() : (double.tryParse('$v') ?? 0);

  /// Turns Tesseract's word table (TSV) into text pieces. Words that are far apart
  /// on the same row (for example two columns on a card) become separate pieces.
  static List<OcrLine> linesFromTsv(String tsv) {
    if (tsv.trim().isEmpty) return [];
    final groups = <String, List<_W>>{};
    for (final row in tsv.split(RegExp(r'\r?\n'))) {
      final c = row.split('\t');
      if (c.length < 12 || c[0] != '5') continue;
      final text = c.sublist(11).join(' ').trim();
      final conf = double.tryParse(c[10]) ?? 0;
      if (text.isEmpty || conf < 20) continue;
      final left = double.tryParse(c[6]);
      final top = double.tryParse(c[7]);
      final w = double.tryParse(c[8]);
      final h = double.tryParse(c[9]);
      if (left == null || top == null || w == null || h == null) continue;
      groups
          .putIfAbsent('${c[2]}-${c[3]}-${c[4]}', () => <_W>[])
          .add(_W(text, left, top, left + w, top + h));
    }
    final lines = <OcrLine>[];
    for (final words in groups.values) {
      words.sort((a, b) => a.left.compareTo(b.left));
      final avgH = words.map((w) => w.bottom - w.top).reduce((a, b) => a + b) / words.length;
      var current = <_W>[words.first];
      for (var i = 1; i < words.length; i++) {
        final gap = words[i].left - words[i - 1].right;
        if (gap > 1.6 * avgH) {
          lines.add(_make(current));
          current = <_W>[];
        }
        current.add(words[i]);
      }
      lines.add(_make(current));
    }
    return _ordered(lines);
  }

  static OcrLine _make(List<_W> ws) {
    final text = ws.map((w) => w.text).join(' ');
    final left = ws.map((w) => w.left).reduce(math.min);
    final top = ws.map((w) => w.top).reduce(math.min);
    final right = ws.map((w) => w.right).reduce(math.max);
    final bottom = ws.map((w) => w.bottom).reduce(math.max);
    return OcrLine(text, left, top, right, bottom);
  }

  /// Reading order: top to bottom, and left to right within the same row.
  static List<OcrLine> _ordered(List<OcrLine> lines) {
    final sorted = [...lines]..sort((a, b) => a.top.compareTo(b.top));
    final rows = <List<OcrLine>>[];
    for (final l in sorted) {
      if (rows.isNotEmpty) {
        final ref = rows.last.first;
        if ((l.top - ref.top).abs() < 0.6 * ref.height) {
          rows.last.add(l);
          continue;
        }
      }
      rows.add(<OcrLine>[l]);
    }
    final out = <OcrLine>[];
    for (final r in rows) {
      r.sort((a, b) => a.left.compareTo(b.left));
      out.addAll(r);
    }
    return out;
  }
}
