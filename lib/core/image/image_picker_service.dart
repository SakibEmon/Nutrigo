import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  ImagePickerService._();

  static final ImagePicker _picker = ImagePicker();

  /// Pick image from Gallery
  static Future<File?> pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // সাইজ কমানো হয়েছে
      maxWidth: 600, // রেজুলেশন লিমিট করা হয়েছে
      maxHeight: 600,
    );

    if (image == null) return null;
    return File(image.path);
  }

  /// Capture image from Camera
  static Future<File?> pickFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50, // সাইজ কমানো হয়েছে
      maxWidth: 600, // রেজুলেশন লিমিট করা হয়েছে
      maxHeight: 600,
    );

    if (image == null) return null;
    return File(image.path);
  }
}
