import 'package:flutter_contacts/flutter_contacts.dart';
import '../models/contact_data.dart';
import 'save_result.dart';

export 'save_result.dart';

/// Saves a contact into the phone's own Contacts app (asks permission first).
Future<SaveResult> saveToPhoneContacts(ContactData d) async {
  try {
    final granted = await FlutterContacts.requestPermission(readonly: false);
    if (!granted) return SaveResult.permissionDenied;

    final fullName = d.name.trim().isNotEmpty ? d.name.trim() : d.company.trim();
    final parts = fullName.split(RegExp(r'\s+'));

    final contact = Contact();
    if (parts.length > 1) {
      contact.name.first = parts.sublist(0, parts.length - 1).join(' ');
      contact.name.last = parts.last;
    } else {
      contact.name.first = fullName;
    }

    contact.phones = [
      if (d.mobile.isNotEmpty) Phone(d.mobile, label: PhoneLabel.mobile),
      if (d.phone.isNotEmpty) Phone(d.phone, label: PhoneLabel.work),
      if (d.whatsapp.isNotEmpty && d.whatsapp != d.mobile)
        Phone(d.whatsapp, label: PhoneLabel.other),
    ];
    contact.emails = [
      if (d.email.isNotEmpty) Email(d.email, label: EmailLabel.work),
    ];
    contact.websites = [
      if (d.website.isNotEmpty) Website(d.website, label: WebsiteLabel.work),
      if (d.linkedin.isNotEmpty) Website(d.linkedin, label: WebsiteLabel.other),
    ];
    if (d.company.isNotEmpty || d.title.isNotEmpty) {
      contact.organizations = [Organization(company: d.company, title: d.title)];
    }
    if (d.address.isNotEmpty) {
      contact.addresses = [Address(d.address, label: AddressLabel.work)];
    }
    if (d.bio.isNotEmpty) contact.notes = [Note(d.bio)];

    await FlutterContacts.insertContact(contact);
    return SaveResult.saved;
  } catch (_) {
    return SaveResult.failed;
  }
}
