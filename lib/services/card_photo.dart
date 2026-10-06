// Web only features (phones use the document scanner instead).
export 'ocr_result.dart';
export 'card_photo_io.dart' if (dart.library.js_interop) 'card_photo_web.dart';
