import 'dart:io';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../demo_data.dart';
import '../services/card_parser.dart';
import '../services/ocr_service.dart';
import '../theme.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final OcrService _ocr = MlKitOcrService();
  bool _busy = false;

  void _msg(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _scan() async {
    setState(() => _busy = true);
    String? path;
    try {
      final pics =
          await CunningDocumentScanner.getPictures(noOfPages: 1, isGalleryImportAllowed: true);
      if (pics == null || pics.isEmpty) return;
      path = pics.first;
      final text = await _ocr.extractText(path);
      if (!mounted) return;
      if (text.trim().length < 5) {
        _msg('We could not read any text. Try better light, hold the phone steady, and fill the frame with the card.');
        return;
      }
      context.push('/review', extra: CardParser.parse(text));
    } catch (_) {
      if (mounted) _msg('Something went wrong while scanning. Please try again.');
    } finally {
      // Privacy: we do not keep the card photo.
      if (path != null) {
        try {
          await File(path).delete();
        } catch (_) {}
      }
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Scan Business Card')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: _busy
              ? const Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Reading card…'),
                  ]),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    const Icon(Icons.credit_card, size: 90, color: teal),
                    const SizedBox(height: 20),
                    const Text('Capture a paper business card',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: deepBlue)),
                    const SizedBox(height: 12),
                    const Text(
                      'Tips: good light, card lying flat, fill the frame.\n'
                      'The photo is read on your phone and is not uploaded or kept.',
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _scan,
                      icon: const Icon(Icons.photo_camera),
                      label: const Text('OPEN CAMERA'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.push('/review', extra: CardParser.parse(demoCardText)),
                      child: const Text('Try a sample card (demo)'),
                    ),
                  ],
                ),
        ),
      );
}
