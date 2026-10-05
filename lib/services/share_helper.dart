import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/contact_data.dart';
import 'vcard.dart';

/// Shares a contact as a standard .vcf file (WhatsApp, email, Bluetooth, etc.).
Future<void> shareVCard(ContactData d) async {
  final dir = await getTemporaryDirectory();
  final base = d.name.trim().isNotEmpty ? d.name : (d.company.isNotEmpty ? d.company : 'contact');
  final safe = base.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
  final file = File('${dir.path}/$safe.vcf');
  await file.writeAsString(buildVCard(d));
  await Share.shareXFiles([XFile(file.path, mimeType: 'text/vcard')], subject: base);
}
