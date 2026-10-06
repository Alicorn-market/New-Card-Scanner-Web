import 'dart:typed_data';
import 'ocr_result.dart';

Future<Uint8List?> pickPhotoBytes({bool fromGallery = false}) async =>
    throw UnsupportedError('Only used by the web version.');

Future<OcrResult> readCardPhoto(Uint8List bytes) async =>
    throw UnsupportedError('Only used by the web version.');
