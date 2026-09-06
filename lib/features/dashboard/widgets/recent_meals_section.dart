import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/ai/nutrition_parser.dart';
import '../../../models/meal_history.dart';
import '../../../services/meal_history_service.dart';
import '../../history/meal_history_screen.dart';
import '../../tasks/nutrition_result_screen.dart';

class RecentMealsSection extends StatefulWidget {
  const RecentMealsSection({super.key});

  @override
  State<RecentMealsSection> createState() => _RecentMealsSectionState();
}

class _RecentMealsSectionState extends State<RecentMealsSection> {
  List<MealHistory> meals = [];

  bool _loading = true;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  // ============================================================
  // LOAD MEALS
  // ============================================================

  Future<void> _loadMeals() async {
    try {
      final data = await MealHistoryService.loadMeals();

      if (!mounted) return;

      setState(() {
        meals = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      debugPrint('Error loading recent meals: $e');
    }
  }

  // ============================================================
  // OPEN MEAL HISTORY
  // ============================================================

  Future<void> _openHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MealHistoryScreen()),
    );

    if (!mounted) return;

    await _loadMeals();
  }

  // ============================================================
  // OPEN MEAL RESULT
  // ============================================================

  Future<void> _openMeal(MealHistory meal) async {
    final nutrition = NutritionResult(
      mealName: meal.mealName,
      healthy: meal.healthy,
      confidence: meal.confidence,
      calories: meal.calories,
      protein: meal.protein,
      carbs: meal.carbs,
      fat: meal.fat,
      fiber: meal.fiber,
      feedback: meal.feedback,
      suggestions: meal.suggestions,

      // Old/history meals were already saved after analysis.
      // Therefore, treat them as matched when opening history.
      mealMatched: true,
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NutritionResultScreen(
          image: File(meal.imagePath),
          result: nutrition,
        ),
      ),
    );
  }

  // ============================================================
  // DELETE CONFIRMATION
  // ============================================================

  Future<bool> _showDeleteConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'Delete Meal',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete this meal?',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text('Cancel', style: GoogleFonts.poppins()),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // ============================================================
  // SHOW UNDO SNACKBAR
  // ============================================================

  void _showUndoSnackbar(MealHistory deletedMeal) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${deletedMeal.mealName} deleted',
          style: GoogleFonts.poppins(),
        ),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            await MealHistoryService.saveMeal(deletedMeal);

            if (!mounted) return;

            await _loadMeals();
          },
        ),
      ),
    );
  }

  // ============================================================
  // BUILD MEAL CARD
  // ============================================================

  Widget _buildMealCard(BuildContext context, MealHistory meal, int index) {
    final imageFile = File(meal.imagePath);

    return Dismissible(
      key: ValueKey('${meal.scannedAt.toIso8601String()}_$index'),

      direction: DismissDirection.endToStart,

      // ========================================================
      // DELETE BACKGROUND
      // ========================================================
      background: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.only(right: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 30),
      ),

      // ========================================================
      // CONFIRM DELETE
      // ========================================================
      confirmDismiss: (_) async {
        return await _showDeleteConfirmation();
      },

      // ========================================================
      // DELETE
      // ========================================================
      onDismissed: (_) async {
        final deletedMeal = meal;

        await MealHistoryService.deleteMeal(index);

        if (!mounted) return;

        setState(() {
          meals.removeAt(index);
        });

        _showUndoSnackbar(deletedMeal);
      },

      // ========================================================
      // MEAL CARD
      // ========================================================
      child: InkWell(
        borderRadius: BorderRadius.circular(20),

        onTap: () {
          _openMeal(meal);
        },

        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),

          child: Row(
            children: [
              // ==================================================
              // IMAGE
              // ==================================================
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: imageFile.existsSync()
                    ? Image.file(
                        imageFile,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 70,
                        height: 70,
                        color: const Color(0xffE8F5E9),
                        child: const Icon(
                          Icons.restaurant_rounded,
                          color: Color(0xff4CAF50),
                          size: 30,
                        ),
                      ),
              ),

              const SizedBox(width: 16),

              // ==================================================
              // MEAL INFORMATION
              // ==================================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.mealName.isEmpty ? 'Unknown Meal' : meal.mealName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      '${meal.calories} kcal',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        Icon(
                          meal.healthy
                              ? Icons.check_circle_rounded
                              : Icons.warning_amber_rounded,
                          size: 18,
                          color: meal.healthy ? Colors.green : Colors.orange,
                        ),

                        const SizedBox(width: 6),

                        Flexible(
                          child: Text(
                            meal.healthy ? 'Healthy' : 'Needs Improvement',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: meal.healthy
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ==================================================
              // ARROW
              // ==================================================
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // ============================================================
    // LOADING
    // ============================================================

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xff4CAF50)),
        ),
      );
    }

    // ============================================================
    // EMPTY STATE
    // ============================================================

    if (meals.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xffE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant_rounded,
                color: Color(0xff4CAF50),
                size: 30,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'No meals scanned yet 🍽️',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              'Your analysed meals will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    // ============================================================
    // ONLY SHOW 2 RECENT MEALS
    // ============================================================

    final recentMeals = meals.take(2).toList();

    // ============================================================
    // RECENT MEALS SECTION
    // ============================================================

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ========================================================
        // HEADER
        // ========================================================
        Row(
          children: [
            Text(
              'Recent Meals',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Spacer(),

            TextButton(
              onPressed: _openHistory,
              child: Text(
                'View All',
                style: GoogleFonts.poppins(
                  color: const Color(0xff4CAF50),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // ========================================================
        // RECENT MEAL CARDS
        // ========================================================
        ...recentMeals.asMap().entries.map((entry) {
          final index = entry.key;
          final meal = entry.value;

          return _buildMealCard(context, meal, index);
        }),
      ],
    );
  }
}
