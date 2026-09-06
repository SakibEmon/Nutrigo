import 'dart:convert';
import 'dart:io';

class ImageConverter {
  ImageConverter._();

  /// Converts image file to Base64 String
  static Future<String> toBase64(File image) async {
    final bytes = await image.readAsBytes();

    return base64Encode(bytes);
  }
}
