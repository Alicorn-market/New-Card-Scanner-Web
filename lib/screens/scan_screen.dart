import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../demo_data.dart';
import '../models/contact_data.dart';
import '../services/card_capture.dart';
import '../services/card_photo.dart';
import '../services/card_parser.dart';
import '../theme.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _busy = false;

  void _msg(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(text),
        duration: const Duration(seconds: 12),
        showCloseIcon: true,
      ));

  Future<void> _scan({bool fromGallery = false}) async {
    setState(() => _busy = true);
    try {
      ContactData data;
      if (kIsWeb) {
        // 1. take or choose a photo, 2. frame the card, 3. read it
        final photo = await pickPhotoBytes(fromGallery: fromGallery);
        if (photo == null) return;
        if (!mounted) return;
        setState(() => _busy = false);
        final cropped = await context.push<Uint8List>('/crop', extra: photo);
        if (cropped == null) return;
        if (!mounted) return;
        setState(() => _busy = true);
        final result = await readCardPhoto(cropped);
        if (!mounted) return;
        if (result.text.trim().length < 5) {
          _msg('We could not read any text. Try better light, hold the phone steady, and frame only the card.');
          return;
        }
        data = CardParser.parseResult(result);
      } else {
        final text = await captureAndReadCard(fromGallery: fromGallery);
        if (text == null) return;
        if (!mounted) return;
        if (text.trim().length < 5) {
          _msg('We could not read any text. Try better light, hold the phone steady, and fill the frame with the card.');
          return;
        }
        data = CardParser.parse(text);
      }
      if (!mounted) return;
      context.push('/review', extra: data);
    } catch (e) {
      if (mounted) {
        final detail = e.toString().replaceFirst('Exception: ', '');
        final short = detail.length > 240 ? detail.substring(0, 240) : detail;
        _msg(kIsWeb
            ? 'Something went wrong while reading the card. Please check your internet connection and try again. (Details: $short)'
            : 'Something went wrong while scanning. Please try again.');
      }
    } finally {
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
                    SizedBox(height: 6),
                    Text('The first time can take a little longer.',
                        style: TextStyle(fontSize: 12)),
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
                    Text(
                      kIsWeb
                          ? 'Tips: good light, card lying flat, fill the frame.\n'
                              'The photo is read in your browser and is not uploaded or kept.'
                          : 'Tips: good light, card lying flat, fill the frame.\n'
                              'The photo is read on your phone and is not uploaded or kept.',
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () => _scan(),
                      icon: const Icon(Icons.photo_camera),
                      label: Text(kIsWeb ? 'TAKE A PHOTO' : 'OPEN CAMERA'),
                    ),
                    if (kIsWeb) ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => _scan(fromGallery: true),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('CHOOSE A PHOTO'),
                      ),
                    ],
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
