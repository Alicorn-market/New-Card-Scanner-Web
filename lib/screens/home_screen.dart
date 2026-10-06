import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/contact_data.dart';
import '../services/storage.dart';
import '../theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('QARDIVO')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Scan. Share. Connect.',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: deepBlue)),
            const SizedBox(height: 24),
            _BigCard(
              icon: Icons.document_scanner,
              title: 'Scan Business Card',
              subtitle: 'Capture a paper business card and save it to your contacts.',
              color: deepBlue,
              onTap: () => context.go('/scan'),
            ),
            const SizedBox(height: 16),
            _BigCard(
              icon: Icons.qr_code_2,
              title: 'My Digital Card',
              subtitle: 'Share your contact details instantly using QR.',
              color: teal,
              onTap: () => context.go('/card'),
            ),
            const SizedBox(height: 28),
            const Text('Recent scans', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ValueListenableBuilder<int>(
              valueListenable: Storage.changes,
              builder: (context, _, __) => FutureBuilder<List<ContactData>>(
                future: Storage.loadRecent(),
                builder: (context, snap) {
                  final items = snap.data ?? const <ContactData>[];
                  if (items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No scanned cards yet.'),
                    );
                  }
                  return Column(
                    children: [
                      for (final c in items.take(20))
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: teal.withOpacity(0.15),
                            foregroundColor: deepBlue,
                            child: Text(initialsOf(c.name.isNotEmpty ? c.name : c.company)),
                          ),
                          title: Text(c.name.isNotEmpty
                              ? c.name
                              : (c.company.isNotEmpty ? c.company : 'Unnamed contact')),
                          subtitle: Text(
                            [c.title, c.company].where((s) => s.isNotEmpty).join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => Storage.deleteRecent(c.id),
                          ),
                          onTap: () => context.push('/review', extra: c),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      );
}

class _BigCard extends StatelessWidget {
  const _BigCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: color,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Row(children: [
              Icon(icon, color: Colors.white, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.white70)),
                ]),
              ),
            ]),
          ),
        ),
      );
}
