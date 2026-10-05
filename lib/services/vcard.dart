import '../models/contact_data.dart';

/// Builds a standard vCard 3.0 (.vcf) that iOS and Android Contacts understand.
///
/// compact: true is used for QR codes. It leaves out the bio and uses short
/// line breaks, so the QR code stays as simple and easy to scan as possible.
String buildVCard(ContactData c, {bool compact = false}) {
  String esc(String s) => s
      .replaceAll('\\', '\\\\')
      .replaceAll(';', '\\;')
      .replaceAll(',', '\\,')
      .replaceAll('\r', '')
      .replaceAll('\n', '\\n');

  final fullName = c.name.trim().isNotEmpty ? c.name.trim() : c.company.trim();
  final parts = fullName.split(RegExp(r'\s+'));
  final family = parts.length > 1 ? parts.last : '';
  final given = parts.length > 1 ? parts.sublist(0, parts.length - 1).join(' ') : fullName;

  final l = <String>[
    'BEGIN:VCARD',
    'VERSION:3.0',
    'N:${esc(family)};${esc(given)};;;',
    'FN:${esc(fullName)}',
  ];
  if (c.company.isNotEmpty) l.add('ORG:${esc(c.company)}');
  if (c.title.isNotEmpty) l.add('TITLE:${esc(c.title)}');
  if (c.mobile.isNotEmpty) l.add('TEL;TYPE=CELL:${c.mobile}');
  if (c.phone.isNotEmpty) l.add('TEL;TYPE=WORK,VOICE:${c.phone}');
  if (c.whatsapp.isNotEmpty && c.whatsapp != c.mobile) l.add('TEL;TYPE=OTHER:${c.whatsapp}');
  if (c.email.isNotEmpty) l.add('EMAIL;TYPE=INTERNET:${c.email}');
  if (c.website.isNotEmpty) l.add('URL:${c.website}');
  if (c.linkedin.isNotEmpty) l.add('URL:${c.linkedin}');
  if (c.address.isNotEmpty) l.add('ADR;TYPE=WORK:;;${esc(c.address)};;;;');
  if (!compact && c.bio.isNotEmpty) l.add('NOTE:${esc(c.bio)}');
  l.add('END:VCARD');
  final sep = compact ? '\n' : '\r\n';
  return '${l.join(sep)}$sep';
}
