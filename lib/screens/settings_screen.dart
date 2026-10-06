import 'package:flutter/material.dart';
import '../services/storage.dart';
import '../theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _deleteAll(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete all my data?'),
        content: const Text(
            'This removes your saved scans and your digital card from this phone. Contacts you already saved to your phone are not affected.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await Storage.clearAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All data deleted.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: teal.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Privacy: business-card photos are read on your phone, are not uploaded, and are deleted right after scanning. '
                'Your saved scans and digital card are stored only on this phone in this version.',
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete all my data'),
              onTap: () => _deleteAll(context),
            ),
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('QARDIVO'),
              subtitle: Text('Version 0.1.0 (MVP)'),
            ),
          ],
        ),
      );
}
