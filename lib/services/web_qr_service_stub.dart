import 'dart:typed_data';

/// Stub implementation for non-web platforms
class WebQRService {
  /// Stub method that always returns null
  static Future<String?> decodeFromBytes(Uint8List bytes) async {
    return null;
  }
}
