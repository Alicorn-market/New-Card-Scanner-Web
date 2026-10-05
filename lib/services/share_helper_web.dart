import 'dart:typed_data';
import '../models/contact_data.dart';
import 'vcard.dart';
import 'web_download.dart';

Future<void> shareVCard(ContactData d) async {
  final base = d.name.trim().isNotEmpty ? d.name : (d.company.isNotEmpty ? d.company : 'contact');
  final safe = base.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
  downloadText('$safe.vcf', buildVCard(d), 'text/vcard');
}

Future<void> shareImageBytes(Uint8List bytes, String filename, {String? text}) async {
  downloadBytes(filename, bytes, 'image/png');
}
