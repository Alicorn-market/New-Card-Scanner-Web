import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/contact_data.dart';
import '../services/card_parser.dart';
import '../services/contact_saver.dart';
import '../services/share_helper.dart';
import '../services/storage.dart';

enum EditorMode { review, profile }

String? _emailCheck(String? v) {
  final t = (v ?? '').trim();
  if (t.isEmpty) return null;
  return CardParser.isValidEmail(t) ? null : 'This email looks incorrect';
}

String? _phoneCheck(String? v) {
  final t = (v ?? '').trim();
  if (t.isEmpty) return null;
  return CardParser.isValidPhone(t) ? null : 'This number looks incorrect';
}

/// One form used for two jobs: reviewing a scanned card, and editing my own card.
class ContactEditor extends StatefulWidget {
  const ContactEditor({super.key, required this.initial, required this.mode});
  final ContactData initial;
  final EditorMode mode;

  @override
  State<ContactEditor> createState() => _ContactEditorState();
}

class _ContactEditorState extends State<ContactEditor> {
  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _c;

  bool get _isProfile => widget.mode == EditorMode.profile;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _c = {
      'name': TextEditingController(text: i.name),
      'title': TextEditingController(text: i.title),
      'company': TextEditingController(text: i.company),
      'mobile': TextEditingController(text: i.mobile),
      'whatsapp': TextEditingController(text: i.whatsapp),
      'phone': TextEditingController(text: i.phone),
      'email': TextEditingController(text: i.email),
      'website': TextEditingController(text: i.website),
      'linkedin': TextEditingController(text: i.linkedin),
      'address': TextEditingController(text: i.address),
      'bio': TextEditingController(text: i.bio),
    };
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _t(String k) => _c[k]!.text.trim();

  ContactData _collect() => ContactData(
        id: widget.initial.id,
        name: _t('name'),
        title: _t('title'),
        company: _t('company'),
        mobile: _t('mobile'),
        whatsapp: _t('whatsapp'),
        phone: _t('phone'),
        email: _t('email'),
        website: _t('website'),
        linkedin: _t('linkedin'),
        address: _t('address'),
        bio: _t('bio'),
      );

  void _snack(String text, {SnackBarAction? action}) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(text), action: action));

  bool _validate() {
    if (_form.currentState!.validate()) return true;
    _snack('Some information could not be identified. Please check the highlighted fields.');
    return false;
  }

  Future<void> _saveToContacts() async {
    if (!_validate()) return;
    final data = _collect();
    final result = await saveToPhoneContacts(data);
    if (!mounted) return;
    switch (result) {
      case SaveResult.saved:
        await Storage.saveRecent(data);
        _snack('Saved to your contacts.');
        if (mounted) context.go('/home');
      case SaveResult.permissionDenied:
        _snack(
          'Contacts permission was not given. You can allow it in your phone settings, or share the contact file instead.',
          action: SnackBarAction(label: 'Share file', onPressed: () => shareVCard(data)),
        );
      case SaveResult.failed:
        _snack('The contact could not be saved. Please try again.');
    }
  }

  Future<void> _saveForLater() async {
    if (!_validate()) return;
    await Storage.saveRecent(_collect());
    if (!mounted) return;
    _snack('Saved for later.');
    context.go('/home');
  }

  Future<void> _saveProfile() async {
    if (!_validate()) return;
    await Storage.saveProfile(_collect());
    if (!mounted) return;
    context.pop();
  }

  Widget _f(String key, String label,
          {TextInputType? kb, int lines = 1, String? Function(String?)? validator, IconData? icon}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: _c[key],
          keyboardType: kb,
          minLines: 1,
          maxLines: lines,
          validator: validator,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: icon == null ? null : Icon(icon),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(_isProfile ? 'Edit my card' : 'Check the details')),
        body: Form(
          key: _form,
          autovalidateMode: AutovalidateMode.always,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (!_isProfile)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text('Please check the details below. Nothing is saved until you tap a button.'),
                ),
              _f('name', 'Full name',
                  icon: Icons.person_outline,
                  validator: (v) => (v ?? '').trim().isEmpty && _t('company').isEmpty
                      ? 'A name or company is needed'
                      : null),
              _f('title', 'Designation', icon: Icons.work_outline),
              _f('company', 'Company', icon: Icons.business),
              _f('mobile', 'Mobile',
                  kb: TextInputType.phone, icon: Icons.smartphone, validator: _phoneCheck),
              _f('whatsapp', 'WhatsApp',
                  kb: TextInputType.phone, icon: Icons.chat_outlined, validator: _phoneCheck),
              _f('phone', 'Telephone',
                  kb: TextInputType.phone, icon: Icons.phone_outlined, validator: _phoneCheck),
              _f('email', 'Email',
                  kb: TextInputType.emailAddress, icon: Icons.email_outlined, validator: _emailCheck),
              _f('website', 'Website', kb: TextInputType.url, icon: Icons.language),
              _f('linkedin', 'LinkedIn', kb: TextInputType.url, icon: Icons.link),
              _f('address', 'Address',
                  kb: TextInputType.multiline, lines: 3, icon: Icons.location_on_outlined),
              if (_isProfile)
                _f('bio', 'Short bio', kb: TextInputType.multiline, lines: 4, icon: Icons.notes),
              const SizedBox(height: 8),
              if (_isProfile)
                FilledButton(onPressed: _saveProfile, child: const Text('SAVE MY CARD'))
              else ...[
                FilledButton(onPressed: _saveToContacts, child: const Text('SAVE TO CONTACTS')),
                const SizedBox(height: 10),
                OutlinedButton(onPressed: _saveForLater, child: const Text('SAVE FOR LATER')),
                const SizedBox(height: 6),
                TextButton(onPressed: () => context.go('/scan'), child: const Text('Scan another card')),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
}
