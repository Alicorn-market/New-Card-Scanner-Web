import '../models/contact_data.dart';
import 'save_result.dart';
import 'vcard.dart';
import 'web_download.dart';

export 'save_result.dart';

/// Web version: a website cannot write into Contacts, so we download a standard
/// .vcf file. The phone then offers "Add to Contacts".
Future<SaveResult> saveToPhoneContacts(ContactData d) async {
  try {
    final base = d.name.trim().isNotEmpty ? d.name : (d.company.isNotEmpty ? d.company : 'contact');
    final safe = base.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    downloadText('$safe.vcf', buildVCard(d), 'text/vcard');
    return SaveResult.downloaded;
  } catch (_) {
    return SaveResult.failed;
  }
}
