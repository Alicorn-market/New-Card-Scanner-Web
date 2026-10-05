import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// The app only talks to this interface, so the OCR engine can be swapped later
/// (for example for a cloud OCR service) without touching any screens.
abstract class OcrService {
  Future<String> extractText(String imagePath);
}

/// Free, on-device OCR (Google ML Kit). The photo never leaves the phone.
class MlKitOcrService implements OcrService {
  @override
  Future<String> extractText(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(InputImage.fromFilePath(imagePath));
      return result.text;
    } finally {
      await recognizer.close();
    }
  }
}
