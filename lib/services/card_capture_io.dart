import 'dart:io';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'ocr_service.dart';

/// Opens the phone's document scanner, reads the text on the card and
/// returns it. Returns null if the person cancelled.
/// [fromGallery] is only used by the web version.
Future<String?> captureAndReadCard({bool fromGallery = false}) async {
  final pics =
      await CunningDocumentScanner.getPictures(noOfPages: 1, isGalleryImportAllowed: true);
  if (pics == null || pics.isEmpty) return null;
  final path = pics.first;
  try {
    return await MlKitOcrService().extractText(path);
  } finally {
    // Privacy: we do not keep the card photo.
    try {
      await File(path).delete();
    } catch (_) {}
  }
}
