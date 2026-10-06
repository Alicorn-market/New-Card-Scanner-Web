import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'ocr_result.dart';
import 'web_ocr.dart';

/// Asks for a photo (camera on a phone, file chooser on a computer).
/// Returns null if the person cancelled.
Future<Uint8List?> pickPhotoBytes({bool fromGallery = false}) async {
  XFile? picked;
  try {
    picked = await ImagePicker().pickImage(
      source: fromGallery ? ImageSource.gallery : ImageSource.camera,
      maxWidth: 2400,
      imageQuality: 92,
    );
  } catch (e) {
    throw Exception('photo step: $e');
  }
  if (picked == null) return null;
  return picked.readAsBytes();
}

Future<OcrResult> readCardPhoto(Uint8List bytes) async {
  try {
    return await webOcr(bytes);
  } catch (e) {
    throw Exception('reading step: $e');
  }
}
