import 'dart:io';

class ImageValidator {
  ImageValidator._();

  /// Maximum image size: 10 MB
  static const int maxFileSize = 10 * 1024 * 1024;

  /// Validate image before sending to Gemini
  static Future<String?> validate(File image) async {
    // File exists?
    if (!await image.exists()) {
      return "Image file not found.";
    }

    // File size
    final fileSize = await image.length();

    if (fileSize > maxFileSize) {
      return "Image must be smaller than 10 MB.";
    }

    // Extension
    final path = image.path.toLowerCase();

    if (!(path.endsWith(".jpg") ||
        path.endsWith(".jpeg") ||
        path.endsWith(".png") ||
        path.endsWith(".webp"))) {
      return "Only JPG, PNG and WEBP images are supported.";
    }

    return null;
  }
}
