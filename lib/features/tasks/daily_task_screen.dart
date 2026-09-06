import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/course_service.dart';
import '../courses/course_model.dart';
import '../quiz/quiz_screen.dart';
import 'meal_preview_screen.dart';
import 'widgets/task_header.dart';
import 'widgets/task_requirement.dart';

class DailyTaskScreen extends StatefulWidget {
  final int weekNumber;
  final int dayNumber;

  // Course information
  final String courseId;
  final List<Lesson> defaultLessons;

  const DailyTaskScreen({
    super.key,
    required this.weekNumber,
    required this.dayNumber,
    required this.courseId,
    required this.defaultLessons,
  });

  @override
  State<DailyTaskScreen> createState() => _DailyTaskScreenState();
}

class _DailyTaskScreenState extends State<DailyTaskScreen> {
  bool _completing = false;
  bool _mealScanned = false;
  bool _quizPassed = false;

  final ImagePicker _picker = ImagePicker();

  // ============================================================
  // TODAY'S ASSIGNED MEAL (Course & Day Specific)
  // ============================================================

  String get _targetMeal {
    // ------------------------------------------------------------
    // 1. HEALTHY EATING BASICS (nutrition101)
    // ------------------------------------------------------------
    if (widget.courseId == "nutrition101") {
      switch (widget.dayNumber) {
        case 1:
          return "Rice with vegetables and egg";
        case 2:
          return "Vegetable salad with egg";
        case 3:
          return "Rice, lentils (dal) and mixed vegetables";
        case 4:
          return "Chicken with sauteed vegetables and brown rice";
        case 5:
          return "Fresh fruit bowl and yogurt";
        case 6:
          return "Whole grain vegetable sandwich";
        case 7:
          return "Balanced nutrition plate with mixed greens";
        case 8:
          return "Oatmeal with nuts and sliced fruits";
        case 9:
          return "Steamed fish with lemon and leafy vegetables";
        case 10:
          return "Healthy boiled egg and vegetable soup";
        default:
          return "Healthy balanced meal";
      }
    }

    // ------------------------------------------------------------
    // 2. PROTEIN & BODY GROWTH (protein)
    // ------------------------------------------------------------
    if (widget.courseId == "protein") {
      switch (widget.dayNumber) {
        case 1:
          return "2 Boiled eggs with cucumber slices";
        case 2:
          return "Grilled chicken breast with steamed broccoli";
        case 3:
          return "Thick lentil (dal) bowl with green salad";
        case 4:
          return "Fish curry with light brown rice";
        case 5:
          return "Boiled chickpeas (chola) salad with tomatoes";
        case 6:
          return "Paneer / Tofu stir fry with bell peppers";
        case 7:
          return "Chicken and egg vegetable stew";
        case 8:
          return "Soybean chunk curry with sauteed greens";
        case 9:
          return "Egg white omelette with spinach";
        case 10:
          return "High-protein recovery plate";
        default:
          return "High-protein balanced meal";
      }
    }

    // ------------------------------------------------------------
    // 3. VITAMINS & MINERALS (vitamins)
    // ------------------------------------------------------------
    if (widget.courseId == "vitamins") {
      switch (widget.dayNumber) {
        case 1:
          return "Fresh carrot and orange citrus salad (Vitamin A & C)";
        case 2:
          return "Steamed spinach (palak) with lentils (Iron rich)";
        case 3:
          return "Milk / Curd bowl with banana (Calcium & Potassium)";
        case 4:
          return "Mixed bell pepper and broccoli stir-fry";
        case 5:
          return "Pumpkin and sweet potato mash (Vitamin A)";
        case 6:
          return "Lemon herb fish or green salad (Vitamin C & Zinc)";
        case 7:
          return "Almonds, walnuts and sunflower seed mix (Vitamin E)";
        case 8:
          return "Dark leafy green vegetables (shak) with lemon";
        case 9:
          return "Papaya and pomegranate fruit bowl";
        case 10:
          return "Multi-vitamin colorful rainbow salad";
        default:
          return "Vitamin & mineral rich plate";
      }
    }

    // ------------------------------------------------------------
    // 4. SMART MEAL PLANNING (meal)
    // ------------------------------------------------------------
    if (widget.courseId == "meal") {
      switch (widget.dayNumber) {
        case 1:
          return "Balanced 50-25-25 plate (50% Veggies, 25% Protein, 25% Carbs)";
        case 2:
          return "Energy breakfast: Overnight oats with chia seeds";
        case 3:
          return "Smart lunch box: Grilled chicken, quinoa and salad";
        case 4:
          return "Light dinner: Mixed vegetable soup with boiled egg";
        case 5:
          return "Healthy smart snack: Apple slices with peanut butter";
        case 6:
          return "Budget meal: Rice with mixed egg-dal-vegetable khichuri";
        case 7:
          return "Meal prep platter for active metabolism";
        case 8:
          return "Complete smart meal planning challenge plate";
        default:
          return "Custom planned healthy meal";
      }
    }

    return "Healthy balanced meal";
  }

  // ============================================================
  // SCAN MEAL
  // ============================================================

  Future<void> _scanMeal() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        return;
      }

      if (!mounted) {
        return;
      }

      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => MealPreviewScreen(
            image: File(pickedFile.path),
            targetMeal: _targetMeal,
          ),
        ),
      );

      if (!mounted) {
        return;
      }

      if (result == true) {
        setState(() {
          _mealScanned = true;
          _quizPassed = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Today's meal matched successfully! ✅",
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: const Color(0xff4CAF50),
          ),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Could not open camera: $e",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ============================================================
  // START QUIZ
  // ============================================================

  Future<void> _startQuiz() async {
    if (!_mealScanned) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please complete today's meal task first 📷",
            style: GoogleFonts.poppins(),
          ),
        ),
      );

      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          weekNumber: widget.weekNumber,
          dayNumber: widget.dayNumber,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (result == true) {
      setState(() {
        _quizPassed = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Quiz passed successfully! 🎉",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: const Color(0xff4CAF50),
        ),
      );
    }
  }

  // ============================================================
  // COMPLETE LESSON
  // ============================================================

  Future<void> completeLesson() async {
    if (_completing) {
      return;
    }

    // ----------------------------------------------------------
    // CHECK MEAL
    // ----------------------------------------------------------

    if (!_mealScanned) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please complete today's meal task first 📷",
            style: GoogleFonts.poppins(),
          ),
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // CHECK QUIZ
    // ----------------------------------------------------------

    if (!_quizPassed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please complete the quiz first 📝",
            style: GoogleFonts.poppins(),
          ),
        ),
      );

      return;
    }

    setState(() {
      _completing = true;
    });

    try {
      // ========================================================
      // SAVE COMPLETED DAY
      // ========================================================

      await CourseService.completeDay(
        courseId: widget.courseId,
        defaultLessons: widget.defaultLessons,
        dayNumber: widget.dayNumber,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Day ${widget.dayNumber} completed successfully! 🎉",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: const Color(0xff4CAF50),
        ),
      );

      // Return true to LessonScreen
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Could not complete lesson: $e",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _completing = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FBF8),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        title: Text(
          "Today's Mission",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // =====================================================
            // TASK HEADER
            // =====================================================
            const TaskHeader(),

            const SizedBox(height: 30),

            // =====================================================
            // TASK REQUIREMENT
            // =====================================================
            const TaskRequirement(),

            const SizedBox(height: 30),

            // =====================================================
            // TODAY'S ASSIGNED MEAL
            // =====================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.04),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,

                        decoration: const BoxDecoration(
                          color: Color(0xffE8F5E9),
                          shape: BoxShape.circle,
                        ),

                        child: const Icon(
                          Icons.restaurant_menu,
                          color: Color(0xff4CAF50),
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Text(
                              "Today's Meal",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),

                            const SizedBox(height: 3),

                            Text(
                              _targetMeal,
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Text(
                    "Prepare this meal and take a clear photo for AI verification.",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // =====================================================
            // MEAL SCANNER
            // =====================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),

              decoration: BoxDecoration(
                color: const Color(0xff4CAF50),
                borderRadius: BorderRadius.circular(28),

                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff4CAF50).withOpacity(.25),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),

              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,

                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.18),
                      shape: BoxShape.circle,
                    ),

                    child: Icon(
                      _mealScanned
                          ? Icons.check_circle_rounded
                          : Icons.camera_alt_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    _mealScanned
                        ? "Meal Verified Successfully"
                        : "Scan Your Meal",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    _mealScanned
                        ? "Your meal matched today's assigned meal."
                        : "Take a photo of your prepared meal and let AI verify it.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(.95),
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 26),

                  SizedBox(
                    width: double.infinity,
                    height: 56,

                    child: ElevatedButton.icon(
                      onPressed: _scanMeal,

                      icon: Icon(
                        _mealScanned ? Icons.refresh : Icons.camera_alt,
                      ),

                      label: Text(
                        _mealScanned ? "Scan Again" : "Open Camera",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xff4CAF50),
                        elevation: 0,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // =====================================================
            // QUIZ
            // =====================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius: BorderRadius.circular(22),

                border: Border.all(
                  color: _quizPassed
                      ? Colors.green.shade200
                      : Colors.grey.shade200,
                ),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.04),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),

              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,

                        decoration: BoxDecoration(
                          color: _quizPassed
                              ? Colors.green.shade50
                              : const Color(0xffE8F5E9),
                          shape: BoxShape.circle,
                        ),

                        child: Icon(
                          _quizPassed ? Icons.check_circle : Icons.quiz_rounded,
                          color: _quizPassed
                              ? Colors.green
                              : const Color(0xff4CAF50),
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _quizPassed ? "Quiz Completed" : "Nutrition Quiz",
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              _quizPassed
                                  ? "You passed today's quiz."
                                  : "Test what you learned today.",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 52,

                    child: ElevatedButton.icon(
                      onPressed: _mealScanned ? _startQuiz : null,

                      icon: Icon(_quizPassed ? Icons.replay : Icons.play_arrow),

                      label: Text(
                        _quizPassed ? "Retake Quiz" : "Start Quiz",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),

                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff4CAF50),
                        disabledBackgroundColor: Colors.grey.shade300,
                        foregroundColor: Colors.white,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // =====================================================
            // COMPLETE LESSON
            // =====================================================
            SizedBox(
              width: double.infinity,
              height: 58,

              child: ElevatedButton.icon(
                onPressed: _completing || !_mealScanned || !_quizPassed
                    ? null
                    : completeLesson,

                icon: _completing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),

                label: Text(
                  _completing ? "Saving..." : "Complete Lesson",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff4CAF50),

                  disabledBackgroundColor: Colors.grey.shade300,

                  foregroundColor: Colors.white,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
