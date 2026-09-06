import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/meal_history.dart';
import '../../services/meal_history_service.dart';
import '../../core/ai/nutrition_parser.dart';
import '../tasks/nutrition_result_screen.dart';

class MealHistoryScreen extends StatefulWidget {
  const MealHistoryScreen({super.key});

  @override
  State<MealHistoryScreen> createState() => _MealHistoryScreenState();
}

class _MealHistoryScreenState extends State<MealHistoryScreen> {
  List<MealHistory> meals = [];

  @override
  void initState() {
    super.initState();
    loadMeals();
  }

  Future<void> loadMeals() async {
    final data = await MealHistoryService.loadMeals();

    if (!mounted) return;

    setState(() {
      meals = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7F4),

      appBar: AppBar(
        title: Text(
          "Meal History",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),

      body: meals.isEmpty
          ? Center(
              child: Text(
                "No meal history found 🍽️",
                style: GoogleFonts.poppins(fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: meals.length,
              itemBuilder: (context, index) {
                final meal = meals[index];

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      final nutrition = NutritionResult(
                        mealName: meal.mealName,
                        mealMatched: meal.mealMatched,
                        healthy: meal.healthy,
                        confidence: meal.confidence,
                        calories: meal.calories,
                        protein: meal.protein,
                        carbs: meal.carbs,
                        fat: meal.fat,
                        fiber: meal.fiber,
                        feedback: meal.feedback,
                        suggestions: meal.suggestions,
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NutritionResultScreen(
                            result: nutrition,
                            image: File(meal.imagePath),
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(
                              File(meal.imagePath),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),

                          const SizedBox(width: 16),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  meal.mealName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  "${meal.calories} kcal",
                                  style: GoogleFonts.poppins(),
                                ),

                                const SizedBox(height: 8),

                                Row(
                                  children: [
                                    Icon(
                                      meal.healthy
                                          ? Icons.check_circle
                                          : Icons.warning_amber_rounded,
                                      color: meal.healthy
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      meal.healthy
                                          ? "Healthy"
                                          : "Needs Improvement",
                                      style: GoogleFonts.poppins(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const Icon(Icons.arrow_forward_ios, size: 18),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
