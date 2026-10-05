import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/storage.dart';
import '../theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _go(BuildContext context, String path) async {
    await Storage.markWelcomeSeen();
    if (context.mounted) context.go(path);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: () => _go(context, '/home'), child: const Text('Skip')),
                ),
                const Spacer(),
                const Icon(Icons.contact_page_rounded, size: 84, color: teal),
                const SizedBox(height: 24),
                const Text('Scan. Share. Connect.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: deepBlue)),
                const SizedBox(height: 12),
                const Text(
                  'Turn paper business cards into contacts, and share your own card with a single QR code.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const Spacer(),
                FilledButton(
                    onPressed: () => _go(context, '/scan'), child: const Text('SCAN BUSINESS CARD')),
                const SizedBox(height: 12),
                OutlinedButton(
                    onPressed: () => _go(context, '/card'),
                    child: const Text('CREATE MY DIGITAL CARD')),
              ],
            ),
          ),
        ),
      );
}
