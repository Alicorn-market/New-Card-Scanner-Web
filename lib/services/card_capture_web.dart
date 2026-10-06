import 'card_photo_web.dart';

/// Kept so the shared code compiles; the web scan screen uses the crop step instead.
Future<String?> captureAndReadCard({bool fromGallery = false}) async {
  final bytes = await pickPhotoBytes(fromGallery: fromGallery);
  if (bytes == null) return null;
  return (await readCardPhoto(bytes)).text;
}
