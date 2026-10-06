import 'dart:math' as math;
import '../models/contact_data.dart';
import 'ocr_result.dart';

class _Item {
  _Item(this.text, this.height, this.top);
  final String text;
  final double height; // text size in the photo (0 = unknown)
  final double top;
}

class _Cand {
  _Cand(this.text, this.height, this.top, this.order);
  String text;
  final double height;
  final double top;
  int order;
}

/// Turns the text read from a card into contact fields using readable rules.
class CardParser {
  // ---------- patterns ----------
  static final _emailRe = RegExp(r'[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}', caseSensitive: false);
  static final _linkedinRe =
      RegExp(r'(?:https?://)?(?:[a-z]{2,3}\.)?linkedin\.com/[^\s|,;]+', caseSensitive: false);
  static final _urlRe = RegExp(
      r'(?:https?://|www\.)[^\s|,;]+|\b[a-z0-9\-]+(?:\.[a-z0-9\-]+)*\.(?:com|in|org|net|io|info|biz|edu|health|care|app|dev|ae|uk|us|de|sg)\b(?:/[^\s|,;]*)?',
      caseSensitive: false);
  static final _phoneRe = RegExp(r'\+?\(?\d[\d\s\-().]{6,}\d');

  static final _labelRe = RegExp(
      r'\b(?:e-?mail|mobile|mob|cell|telephone|tel|phone|fax|website|linkedin|whats\s?app|address|addr|add)\b\s*(?:[:.\-]|$)',
      caseSensitive: false);
  static final _shortLabelRe = RegExp(r'\b[mtfewa]\s*:', caseSensitive: false);
  static final _edgeRe = RegExp(r'^[\s,;:|\-–•]+|[\s,;:|\-–•]+$');

  static final _strongCompany = RegExp(
      r'\b(?:pvt|private|ltd|limited|llp|inc|llc|corp|corporation|gmbh|plc|co)\b',
      caseSensitive: false);
  static final _weakCompany = RegExp(
      r'\b(?:solutions|technologies|technology|industries|enterprises|systems|associates|medical|healthcare|labs|laboratories|hospital|clinic|services|trading|traders|group|consultancy|consulting|studio|agency|university|institute|foundation|bank|motors|electricals|constructions|builders|pharma|pharmaceuticals|exports|imports|infotech|software|logistics|textiles|agencies|distributors|marketing)\b',
      caseSensitive: false);
  static final _titleRe = RegExp(
      r'\b(?:director|manager|ceo|cto|cfo|coo|cmo|founder|co-?founder|president|vice president|vp|engineer|consultant|partner|executive|officer|head|lead|sales|surgeon|physician|specialist|analyst|associate|proprietor|owner|architect|designer|developer|advisor|chairman|chairperson|managing|md|supervisor|coordinator|representative|professor|lecturer|principal|accountant|attorney|advocate|proprietress|secretary|treasurer|trustee)\b',
      caseSensitive: false);
  static final _addressWordsRe = RegExp(
      r'\b(?:road|street|floor|flr|building|bldg|nagar|avenue|ave|lane|suite|plot|sector|near|opp|opposite|block|tower|towers|po box|district|dist|junction|colony|house|apartment|apartments|complex|cross|layout|market|bypass|highway|pincode|pin)\b',
      caseSensitive: false);
  static final _cityRe = RegExp(
      r'\b(?:kerala|tamil nadu|karnataka|maharashtra|delhi|mumbai|bangalore|bengaluru|chennai|kochi|cochin|ernakulam|thiruvananthapuram|trivandrum|kozhikode|calicut|thrissur|kollam|kannur|hyderabad|telangana|pune|kolkata|gujarat|ahmedabad|rajasthan|jaipur|uttar pradesh|punjab|goa|india|dubai|uae|usa|uk|singapore)\b',
      caseSensitive: false);
  static final _postcodeRe = RegExp(r'\b\d{5,6}\b');
  static final _nameRe = RegExp(r"^[\p{L}][\p{L}.'\- ]*$", unicode: true);

  static final _honorificRe =
      RegExp(r'^(?:mr|mrs|ms|miss|dr|prof|shri|smt|sri|er)\.?\s+', caseSensitive: false);
  static final _lonePrefixRe =
      RegExp(r'^(?:mr|mrs|ms|miss|dr|prof|shri|smt|sri|er)\.?$', caseSensitive: false);
  static final _dropHonorificRe =
      RegExp(r'^(?:mr|mrs|ms|miss|shri|smt|sri)\.?\s+', caseSensitive: false);

  // ---------- entry points ----------
  /// From plain text (phone scanner).
  static ContactData parse(String raw) {
    final items = raw
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .map((l) => _Item(l, 0, 0))
        .toList();
    return _run(items);
  }

  /// From text pieces that know where they sit on the card (web scanner).
  static ContactData parseResult(OcrResult r) {
    if (r.lines.isEmpty) return parse(r.text);
    return _run([for (final l in r.lines) _Item(l.text, l.height, l.top)]);
  }

  // ---------- main work ----------
  static ContactData _run(List<_Item> items) {
    final c = ContactData();
    final cands = <_Cand>[];

    // 1. Pull out the easy things: email, links, phone numbers.
    for (final it in items) {
      var rest = it.text;

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
      if (_usable(cleaned)) cands.add(_Cand(cleaned, it.height, it.top, cands.length));
    }

    // 2. A lone "Mr." / "Dr." belongs to the name line that follows it.
    for (var i = 0; i < cands.length; i++) {
      if (_lonePrefixRe.hasMatch(cands[i].text)) {
        if (i + 1 < cands.length && _nameLike(cands[i + 1].text)) {
          cands[i + 1].text = '${cands[i].text} ${cands[i + 1].text}';
        }
        cands.removeAt(i);
        i--;
      }
    }
    for (var i = 0; i < cands.length; i++) {
      cands[i].order = i;
    }

    // 3. Decide which line is the company, designation, name and address.
    final used = <_Cand>{};
    _Cand? company, title, name;

    for (final x in cands) {
      if (_strongCompany.hasMatch(x.text)) {
        company = x;
        break;
      }
    }
    if (company != null) used.add(company);

    for (final x in cands) {
      if (used.contains(x)) continue;
      if (_titleRe.hasMatch(x.text) && _addrScore(x.text) < 2) {
        title = x;
        break;
      }
    }
    if (title != null) used.add(title);

    final nameCands = cands.where((x) => !used.contains(x) && _nameLike(x.text)).toList();
    if (nameCands.isNotEmpty) {
      final maxH = nameCands.map((x) => x.height).reduce(math.max);
      final titleOrder = title?.order;
      double score(_Cand x) {
        final words = x.text.split(RegExp(r'\s+')).length;
        var s = 0.0;
        if (_honorificRe.hasMatch(x.text)) s += 3;
        if (words >= 2 && words <= 3) s += 2;
        s -= x.order * 0.15;
        if (maxH > 0) s += 3 * (x.height / maxH);
        if (titleOrder != null && x.order == titleOrder - 1) s += 1.5;
        return s;
      }

      nameCands.sort((a, b) => score(b).compareTo(score(a)));
      name = nameCands.first;
      used.add(name);
    }
    if (name == null) {
      for (final x in cands) {
        if (!used.contains(x) && _addrScore(x.text) < 2) {
          name = x;
          used.add(x);
          break;
        }
      }
    }

    if (company == null) {
      final rest = cands.where((x) => !used.contains(x) && _addrScore(x.text) < 2).toList();
      _Cand? pick;
      for (final x in rest) {
        if (_weakCompany.hasMatch(x.text)) {
          pick = x;
          break;
        }
      }
      if (pick == null && rest.isNotEmpty) {
        pick = rest.reduce((a, b) => b.height > a.height ? b : a);
      }
      if (pick != null) {
        company = pick;
        used.add(pick);
      }
    }

    // Address: lines that look like one, plus the lines right next to them.
    final addr = <_Cand>{};
    for (final x in cands) {
      if (!used.contains(x) && _addrScore(x.text) >= 2) addr.add(x);
    }
    var changed = true;
    var guard = 0;
    while (changed && guard++ < 4) {
      changed = false;
      for (final x in cands) {
        if (used.contains(x) || addr.contains(x)) continue;
        final near = addr.any((a) => _near(a, x));
        if (near && (_addrScore(x.text) >= 1 || RegExp(r'[\d,]').hasMatch(x.text))) {
          addr.add(x);
          changed = true;
        }
      }
    }

    if (name != null) c.name = _finalName(name.text);
    if (title != null) c.title = _tidy(title.text);
    if (company != null) c.company = _tidy(company.text);
    c.address = cands.where(addr.contains).map((x) => _tidy(x.text)).join(', ');

    c.rawLines.addAll(cands.map((x) => x.text).toSet());
    return c;
  }

  // ---------- helpers ----------
  static bool _near(_Cand a, _Cand b) {
    if (a.height > 0 && b.height > 0) {
      return (a.top - b.top).abs() < 2.4 * math.max(a.height, b.height);
    }
    return (a.order - b.order).abs() == 1;
  }

  static int _addrScore(String s) {
    var n = 0;
    if (_addressWordsRe.hasMatch(s)) n += 2;
    if (_postcodeRe.hasMatch(s)) n += 2;
    if (_cityRe.hasMatch(s)) n += 1;
    if (','.allMatches(s).length >= 2) n += 1;
    if (RegExp(r'^\d').hasMatch(s)) n += 1;
    return n;
  }

  static bool _nameLike(String s) {
    final t = s.replaceFirst(_honorificRe, '').trim();
    if (t.isEmpty) return false;
    if (t.split(RegExp(r'\s+')).length > 4) return false;
    if (!_nameRe.hasMatch(t)) return false;
    if (_titleRe.hasMatch(t) || _strongCompany.hasMatch(t) || _weakCompany.hasMatch(t)) return false;
    if (_addrScore(t) >= 2) return false;
    return true;
  }

  static bool _usable(String s) {
    if (s.isEmpty) return false;
    final letters = RegExp(r'\p{L}', unicode: true).allMatches(s).length;
    final alnum = RegExp(r'[\p{L}\p{N}]', unicode: true).allMatches(s).length;
    return letters >= 2 && alnum >= 0.6 * s.length;
  }

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

  /// Indian mobile numbers are 10 digits starting with 6-9 (with or without +91).
  static bool _looksMobile(String number) {
    var d = number.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('91') && d.length == 12) d = d.substring(2);
    return d.length == 10 && '6789'.contains(d[0]);
  }

  static bool _looksLandline(String number) {
    final d = number.replaceAll(RegExp(r'\D'), '');
    return d.startsWith('0') && !d.startsWith('00');
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
        if (_looksLandline(n) && c.phone.isEmpty) {
          c.phone = n;
        } else if (_looksMobile(n) && c.mobile.isEmpty) {
          c.mobile = n;
        } else if (c.mobile.isEmpty) {
          c.mobile = n;
        } else if (c.phone.isEmpty) {
          c.phone = n;
        }
    }
  }

  static String _clean(String s) {
    var out = s.replaceAll(RegExp(r'[|¦_~]'), ' ');
    out = out.replaceAll(_labelRe, ' ').replaceAll(_shortLabelRe, ' ');
    out = out.replaceAll(_edgeRe, '');
    return out.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  }

  static String _tidy(String s) => s.replaceAll(_edgeRe, '').replaceAll(RegExp(r'\s{2,}'), ' ').trim();

  static String _finalName(String s) {
    final out = s.replaceFirst(_dropHonorificRe, '').replaceAll(RegExp(r'\s{2,}'), ' ');
    return _tidyName(_tidy(out));
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
