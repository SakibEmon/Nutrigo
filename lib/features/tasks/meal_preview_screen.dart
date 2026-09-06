import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/ai/gemini_api.dart';
import '../../core/ai/nutrition_parser.dart';
import '../../core/image/image_converter.dart';
import '../../core/image/image_validator.dart';
import '../../models/meal_history.dart';
import '../../services/meal_history_service.dart';
import '../../services/nutrition_score_service.dart';
import 'nutrition_result_screen.dart';

class MealPreviewScreen extends StatefulWidget {
  final File image;
  final String targetMeal;

  const MealPreviewScreen({
    super.key,
    required this.image,
    required this.targetMeal,
  });

  @override
  State<MealPreviewScreen> createState() => _MealPreviewScreenState();
}

class _MealPreviewScreenState extends State<MealPreviewScreen> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FBF8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        title: Text(
          'Meal Preview',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ====================================================
            // ASSIGNED MEAL
            // ====================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xffE8F5E9),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.restaurant_menu,
                    color: Color(0xff4CAF50),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Assigned Meal",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.targetMeal,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ====================================================
            // IMAGE
            // ====================================================
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.file(
                  widget.image,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ====================================================
            // RETAKE
            // ====================================================
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _loading ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.refresh),
                label: Text('Retake', style: GoogleFonts.poppins()),
              ),
            ),
            const SizedBox(height: 14),

            // ====================================================
            // ANALYSE
            // ====================================================
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _analyseMeal,
                icon: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  _loading ? 'Analysing...' : 'Analyse Meal',
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
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ANALYSE MEAL
  // ============================================================
  Future<void> _analyseMeal() async {
    if (_loading) return;

    setState(() {
      _loading = true;
    });

    try {
      final validationError = await ImageValidator.validate(widget.image);
      if (validationError != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(validationError)));
        return;
      }

      final base64Image = await ImageConverter.toBase64(widget.image);

      final aiResponse = await GeminiApi.analyzeMeal(
        base64Image: base64Image,
        targetMeal: widget.targetMeal,
      );

      final nutrition = NutritionResult.fromJson(aiResponse);

      await MealHistoryService.saveMeal(
        MealHistory(
          imagePath: widget.image.path,
          mealName: nutrition.mealName,
          healthy: nutrition.healthy,
          mealMatched: nutrition.mealMatched,
          confidence: nutrition.confidence,
          calories: nutrition.calories,
          protein: nutrition.protein,
          carbs: nutrition.carbs,
          fat: nutrition.fat,
          fiber: nutrition.fiber,
          feedback: nutrition.feedback,
          suggestions: nutrition.suggestions,
          scannedAt: DateTime.now(),
        ),
      );

      // পয়েন্ট যোগ (+১ পয়েন্ট)
      await NutritionScoreService.addPoints(
        NutritionScoreService.pointsMealAnalysis,
        "Meal Analysis",
      );

      if (!mounted) return;

      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              NutritionResultScreen(result: nutrition, image: widget.image),
        ),
      );

      if (!mounted) return;
      Navigator.pop(context, result == true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ $e')));
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }
}
