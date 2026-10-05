import '../models/contact_data.dart';

/// Turns raw OCR text into contact fields using simple, readable rules.
class CardParser {
  static final _emailRe = RegExp(r'[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}', caseSensitive: false);
  static final _linkedinRe =
      RegExp(r'(?:https?://)?(?:[a-z]{2,3}\.)?linkedin\.com/[^\s|,;]+', caseSensitive: false);
  static final _urlRe = RegExp(
      r'(?:https?://|www\.)[^\s|,;]+|\b[a-z0-9\-]+(?:\.[a-z0-9\-]+)*\.(?:com|in|org|net|io|info|biz|edu|health|care|app|dev|ae|uk|us|de|sg)\b(?:/[^\s|,;]*)?',
      caseSensitive: false);
  static final _phoneRe = RegExp(r'\+?\(?\d[\d\s\-().]{6,}\d');

  static final _labelRe = RegExp(
      r'\b(?:e-?mail|mobile|mob|cell|telephone|tel|phone|fax|website|linkedin|whats\s?app)\b\s*(?:[:.\-]|$)',
      caseSensitive: false);
  static final _shortLabelRe = RegExp(r'\b[mtfew]\s*:', caseSensitive: false);
  static final _edgeRe = RegExp(r'^[\s,;:|\-–•]+|[\s,;:|\-–•]+$');

  static final _strongCompany = RegExp(
      r'\b(?:pvt|private|ltd|limited|llp|inc|llc|corp|corporation|gmbh|plc|co)\b',
      caseSensitive: false);
  static final _weakCompany = RegExp(
      r'\b(?:solutions|technologies|technology|industries|enterprises|systems|associates|medical|healthcare|labs|laboratories|hospital|clinic|services|trading|traders|group|consultancy|consulting|studio|agency|university|institute|foundation|bank|motors|electricals|constructions|builders)\b',
      caseSensitive: false);
  static final _titleRe = RegExp(
      r'\b(?:director|manager|ceo|cto|cfo|coo|cmo|founder|co-?founder|president|vice president|vp|engineer|consultant|partner|executive|officer|head|lead|sales|surgeon|physician|specialist|analyst|associate|proprietor|owner|architect|designer|developer|advisor|chairman|chairperson|managing|md|supervisor|coordinator|representative|professor|lecturer|principal|accountant|attorney|advocate)\b',
      caseSensitive: false);
  static final _addressWordsRe = RegExp(
      r'\b(?:road|street|floor|flr|building|bldg|nagar|avenue|ave|lane|suite|plot|sector|near|opp|opposite|block|tower|towers|po box|district|dist|junction|colony|kerala|india|usa|uae|uk|singapore)\b',
      caseSensitive: false);
  static final _postcodeRe = RegExp(r'\b\d{5,6}\b');
  static final _nameRe = RegExp(r"^[\p{L}][\p{L}.'\- ]*$", unicode: true);

  static ContactData parse(String raw) {
    final c = ContactData();
    final lines =
        raw.split(RegExp(r'[\r\n]+')).map((l) => l.trim()).where((l) => l.isNotEmpty);
    final leftovers = <String>[];

    for (final line in lines) {
      var rest = line;

      final em = _emailRe.firstMatch(rest);
      if (em != null) {
        if (c.email.isEmpty) c.email = em.group(0)!;
        rest = rest.replaceAll(_emailRe, ' ');
      }

      final li = _linkedinRe.firstMatch(rest);
      if (li != null) {
        if (c.linkedin.isEmpty) c.linkedin = _withScheme(li.group(0)!);
        rest = rest.replaceAll(_linkedinRe, ' ');
      }

      final web = _urlRe.firstMatch(rest);
      if (web != null) {
        if (c.website.isEmpty) c.website = _withScheme(web.group(0)!);
        rest = rest.replaceAll(_urlRe, ' ');
      }

      for (final m in _phoneRe.allMatches(rest)) {
        final number = m.group(0)!.trim();
        final digits = number.replaceAll(RegExp(r'\D'), '');
        if (digits.length < 8 || digits.length > 15) continue;
        _assignPhone(c, number, _labelBefore(rest.substring(0, m.start)));
      }
      rest = rest.replaceAll(_phoneRe, ' ');

      final cleaned = _clean(rest);
      final letters = cleaned.replaceAll(RegExp(r'[^\p{L}]', unicode: true), '');
      if (letters.length >= 2) leftovers.add(cleaned);
    }

    final addressParts = <String>[];
    final others = <String>[];
    for (final l in leftovers) {
      if (c.company.isEmpty && _strongCompany.hasMatch(l)) {
        c.company = l;
      } else if (c.title.isEmpty && _titleRe.hasMatch(l)) {
        c.title = l;
      } else if (_looksLikeAddress(l)) {
        addressParts.add(l);
      } else {
        others.add(l);
      }
    }

    String? nameLine;
    for (final l in others) {
      final words = l.split(RegExp(r'\s+'));
      if (_nameRe.hasMatch(l) &&
          words.length >= 2 &&
          words.length <= 4 &&
          !_weakCompany.hasMatch(l)) {
        nameLine = l;
        break;
      }
    }
    nameLine ??= others.isNotEmpty ? others.first : null;
    if (nameLine != null) {
      c.name = _tidyName(nameLine);
      others.remove(nameLine);
    }

    if (c.company.isEmpty && others.isNotEmpty) {
      final weak = others.where((l) => _weakCompany.hasMatch(l));
      c.company = weak.isNotEmpty ? weak.first : others.first;
    }

    c.address = addressParts.join(', ');
    return c;
  }

  static bool _looksLikeAddress(String l) =>
      _addressWordsRe.hasMatch(l) || _postcodeRe.hasMatch(l) || ','.allMatches(l).length >= 2;

  static String _labelBefore(String before) {
    final b = before.toLowerCase();
    final tail = b.length > 18 ? b.substring(b.length - 18) : b;
    if (RegExp(r'\bfax\W*$|\bf\s*[:.\-]\s*$').hasMatch(tail)) return 'fax';
    if (RegExp(r'\b(?:whats\s?app|wa)\W*$').hasMatch(tail)) return 'whatsapp';
    if (RegExp(r'\b(?:mobile|mob|cell)\W*$|\bm\s*[:.\-]\s*$').hasMatch(tail)) return 'mobile';
    if (RegExp(r'\b(?:tel|telephone|phone|ph|off|office|land|landline|direct)\W*$|\bt\s*[:.\-]\s*$')
        .hasMatch(tail)) {
      return 'phone';
    }
    return '';
  }

  static void _assignPhone(ContactData c, String n, String label) {
    switch (label) {
      case 'fax':
        return;
      case 'whatsapp':
        if (c.whatsapp.isEmpty) c.whatsapp = n;
        if (c.mobile.isEmpty) c.mobile = n;
        return;
      case 'mobile':
        if (c.mobile.isEmpty) {
          c.mobile = n;
        } else if (c.phone.isEmpty) {
          c.phone = n;
        }
        return;
      case 'phone':
        if (c.phone.isEmpty) {
          c.phone = n;
        } else if (c.mobile.isEmpty) {
          c.mobile = n;
        }
        return;
      default:
        if (c.mobile.isEmpty) {
          c.mobile = n;
        } else if (c.phone.isEmpty) {
          c.phone = n;
        }
    }
  }

  static String _clean(String s) {
    var out = s.replaceAll(_labelRe, ' ').replaceAll(_shortLabelRe, ' ');
    out = out.replaceAll(_edgeRe, '');
    return out.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  }

  static String _tidyName(String s) {
    final letters = s.replaceAll(RegExp(r'[^A-Za-z]'), '');
    if (letters.length > 3 && s == s.toUpperCase()) {
      return s
          .split(' ')
          .map((w) => w.isEmpty ? w : w[0] + w.substring(1).toLowerCase())
          .join(' ');
    }
    return s;
  }

  static String _withScheme(String u) =>
      RegExp(r'^https?://', caseSensitive: false).hasMatch(u) ? u : 'https://$u';

  static bool isValidEmail(String s) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(s.trim());

  static bool isValidPhone(String s) {
    final d = s.replaceAll(RegExp(r'\D'), '');
    return d.length >= 7 && d.length <= 15;
  }
}
