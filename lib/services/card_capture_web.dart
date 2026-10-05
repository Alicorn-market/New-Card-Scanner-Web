import 'package:image_picker/image_picker.dart';
import 'web_ocr.dart';

/// Web version: asks for a photo (camera on a phone, file chooser on a computer)
/// and reads the text inside the browser. Returns null if cancelled.
Future<String?> captureAndReadCard({bool fromGallery = false}) async {
  XFile? picked;
  try {
    picked = await ImagePicker().pickImage(
      source: fromGallery ? ImageSource.gallery : ImageSource.camera,
      maxWidth: 1800,
      imageQuality: 90,
    );
  } catch (e) {
    throw Exception('photo step: $e');
  }
  if (picked == null) return null;
  try {
    final bytes = await picked.readAsBytes();
    return await webOcr(bytes);
  } catch (e) {
    throw Exception('reading step: $e');
  }
}
