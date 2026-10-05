import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/contact_data.dart';
import '../services/share_helper.dart';
import '../services/storage.dart';
import '../theme.dart';

class MyCardScreen extends StatelessWidget {
  const MyCardScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('My Digital Card')),
        body: ValueListenableBuilder<int>(
          valueListenable: Storage.changes,
          builder: (context, _, __) => FutureBuilder<ContactData?>(
            future: Storage.loadProfile(),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final p = snap.data;
              if (p == null || p.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.badge_outlined, size: 84, color: teal),
                      const SizedBox(height: 16),
                      const Text('Create your digital card',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: deepBlue)),
                      const SizedBox(height: 8),
                      const Text('Add your details once, then share them with a QR code.',
                          textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () => context.push('/edit-card', extra: ContactData()),
                        child: const Text('CREATE MY DIGITAL CARD'),
                      ),
                    ],
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _CardPreview(p: p),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => context.push('/qr'),
                    icon: const Icon(Icons.qr_code_2),
                    label: const Text('SHOW QR CODE'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => shareVCard(p),
                    icon: const Icon(Icons.ios_share),
                    label: const Text('SHARE CARD'),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () => context.push('/edit-card', extra: p),
                    child: const Text('Edit profile'),
                  ),
                ],
              );
            },
          ),
        ),
      );
}

class _CardPreview extends StatelessWidget {
  const _CardPreview({required this.p});
  final ContactData p;

  @override
  Widget build(BuildContext context) {
    final rows = <(IconData, String)>[
      if (p.mobile.isNotEmpty) (Icons.smartphone, p.mobile),
      if (p.whatsapp.isNotEmpty) (Icons.chat_outlined, p.whatsapp),
      if (p.phone.isNotEmpty) (Icons.phone_outlined, p.phone),
      if (p.email.isNotEmpty) (Icons.email_outlined, p.email),
      if (p.website.isNotEmpty) (Icons.language, p.website),
      if (p.linkedin.isNotEmpty) (Icons.link, p.linkedin),
      if (p.address.isNotEmpty) (Icons.location_on_outlined, p.address),
    ];
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [deepBlue, Color(0xFF0E5A7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 8))],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: teal,
            child: Text(initialsOf(p.name.isNotEmpty ? p.name : p.company),
                style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 16),
          Text(p.name.isNotEmpty ? p.name : p.company,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
          if (p.title.isNotEmpty)
            Text(p.title, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          if (p.company.isNotEmpty && p.name.isNotEmpty)
            Text(p.company, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          if (p.bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(p.bio, style: const TextStyle(color: Colors.white)),
          ],
          const SizedBox(height: 16),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(children: [
                Icon(r.$1, color: Colors.white70, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(r.$2, style: const TextStyle(color: Colors.white))),
              ]),
            ),
        ],
      ),
    );
  }
}
