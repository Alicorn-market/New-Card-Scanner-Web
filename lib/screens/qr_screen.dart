import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/contact_data.dart';
import '../services/share_helper.dart';
import '../services/storage.dart';
import '../services/vcard.dart';
import '../theme.dart';

/// The QR code contains the contact details themselves (a standard vCard),
/// so it works with any phone camera, needs no internet and no website.
class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  final _boundaryKey = GlobalKey();
  late final Future<ContactData?> _profile = Storage.loadProfile();

  Future<void> _shareImage() async {
    try {
      final boundary =
          _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await shareImageBytes(bytes!.buffer.asUint8List(), 'my_card_qr.png',
          text: 'Scan to save my contact');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('The QR image could not be shared. Please try again.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('My QR Code')),
        body: FutureBuilder<ContactData?>(
          future: _profile,
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
                    const Text('Create your digital card first, then your QR code will appear here.',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => context.pushReplacement('/edit-card', extra: ContactData()),
                      child: const Text('CREATE MY DIGITAL CARD'),
                    ),
                  ],
                ),
              );
            }

            final data = buildVCard(p, compact: true);
            final dense = data.length > 450;

            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text('Scan to save my contact',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: deepBlue)),
                const SizedBox(height: 20),
                LayoutBuilder(builder: (context, cons) {
                  final size = (cons.maxWidth - 32).clamp(200.0, 320.0).toDouble();
                  return Center(
                    child: RepaintBoundary(
                      key: _boundaryKey,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.white,
                        child: QrImageView(
                          data: data,
                          version: QrVersions.auto,
                          errorCorrectionLevel: QrErrorCorrectLevel.L,
                          size: size,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: deepBlue),
                          dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square, color: deepBlue),
                          errorStateBuilder: (context, error) => const Center(
                            child: Text(
                              'Too much information for one QR code. Please shorten your details.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 14),
                const Text(
                  'Works with the normal camera on any phone. No app, no internet needed.',
                  textAlign: TextAlign.center,
                ),
                if (dense) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4E0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'This QR holds a lot of details, so it may be harder to scan. '
                      'For a simpler QR, remove the LinkedIn or address in Edit profile.',
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: _shareImage,
                  icon: const Icon(Icons.qr_code_2),
                  label: Text(kIsWeb ? 'DOWNLOAD QR IMAGE' : 'SHARE QR IMAGE'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => shareVCard(p),
                  icon: const Icon(Icons.contact_page_outlined),
                  label: Text(kIsWeb ? 'DOWNLOAD CONTACT FILE (.VCF)' : 'SHARE CONTACT FILE (.VCF)'),
                ),
              ],
            );
          },
        ),
      );
}
