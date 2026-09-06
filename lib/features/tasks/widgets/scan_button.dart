import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../meal_preview_screen.dart';

class ScanButton extends StatefulWidget {
  final String targetMeal;

  const ScanButton({super.key, required this.targetMeal});

  @override
  State<ScanButton> createState() => _ScanButtonState();
}

class _ScanButtonState extends State<ScanButton> {
  final ImagePicker _picker = ImagePicker();

  bool _openingCamera = false;

  // ============================================================
  // OPEN CAMERA
  // ============================================================

  Future<void> _openCamera() async {
    if (_openingCamera) return;

    setState(() {
      _openingCamera = true;
    });

    try {
      final XFile? pickedImage = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (pickedImage == null) {
        return;
      }

      if (!mounted) return;

      final imageFile = File(pickedImage.path);

      // ========================================================
      // OPEN MEAL PREVIEW
      // ========================================================

      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => MealPreviewScreen(
            image: imageFile,
            targetMeal: widget.targetMeal,
          ),
        ),
      );

      if (!mounted) return;

      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Meal task completed successfully! ✅",
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: const Color(0xff4CAF50),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Could not open camera: $e",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _openingCamera = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _openingCamera ? null : _openCamera,

        icon: _openingCamera
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.camera_alt_rounded),

        label: Text(
          _openingCamera ? "Opening Camera..." : "Scan Your Meal",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),

        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff4CAF50),
          foregroundColor: Colors.white,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
