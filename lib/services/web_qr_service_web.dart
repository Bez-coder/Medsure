import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';

@JS('decodeQRFromImageData')
external JSString? _decodeQRFromImageData(JSArray<JSNumber> imageData, int width, int height);

/// Web-specific QR decoder using jsQR library
class WebQRService {
  /// Decode QR code from image bytes (JPEG/PNG)
  static Future<String?> decodeFromBytes(Uint8List bytes) async {
    try {
      // Decode the image
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      
      // Get image data as RGBA
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) {
        debugPrint('Failed to get image byte data');
        return null;
      }
      
      final width = image.width;
      final height = image.height;
      final rgbaData = byteData.buffer.asUint8List();
      
      // Convert to JSArray
      final jsArray = rgbaData.map((e) => e.toJS).toList().toJS;
      
      // Call JavaScript function
      final result = _decodeQRFromImageData(jsArray, width, height);
      
      if (result != null) {
        return result.toDart;
      }
      
      return null;
    } catch (e) {
      debugPrint('WebQRService error: $e');
      return null;
    }
  }
}
