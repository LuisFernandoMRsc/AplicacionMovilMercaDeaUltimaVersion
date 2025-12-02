import 'dart:typed_data';

import 'package:flutter/services.dart';

class NativeGalleryService {
  static const MethodChannel _channel = MethodChannel('com.mercadea/gallery_saver');

  Future<String?> saveImage(Uint8List bytes, String fileName) async {
    try {
      final result = await _channel.invokeMethod<String>('saveImage', {
        'bytes': bytes,
        'fileName': fileName,
        'mimeType': 'image/png',
      });
      return result;
    } on PlatformException {
      return null;
    }
  }
}
