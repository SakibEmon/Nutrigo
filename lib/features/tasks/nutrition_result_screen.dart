import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/ai/nutrition_parser.dart';
import 'widgets/nutrition_card.dart';

class NutritionResultScreen extends StatelessWidget {
  final NutritionResult result;
  final File image;

  const NutritionResultScreen({
    super.key,
    required this.result,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    final bool matched = result.mealMatched;

    return Scaffold(
      backgroundColor: const Color(0xffF5F7F4),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black,
        title: Text(
          "Nutrition Analysis",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ============================================================
          // MEAL IMAGE + BASIC RESULT
          // ============================================================
          Container(
            decoration: BoxDecoration(
              color: matched
                  ? const Color(0xff4CAF50)
                  : const Color(0xffE65100),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  child: Image.file(
                    image,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        result.mealName.isEmpty
                            ? "Unknown Meal"
                            : result.mealName,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ==================================================
                      // MATCHED / NOT MATCHED CHIP
                      // ==================================================
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              matched
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              color: matched
                                  ? const Color(0xff2E7D32)
                                  : const Color(0xffD84315),
                              size: 22,
                            ),

                            const SizedBox(width: 8),

                            Text(
                              matched
                                  ? "Assigned Meal Matched"
                                  : "Meal Not Matched",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: matched
                                    ? const Color(0xff2E7D32)
                                    : const Color(0xffD84315),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ==================================================
                      // HEALTH STATUS
                      // ==================================================
                      Chip(
                        backgroundColor: result.healthy
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        label: Text(
                          result.healthy ? "Healthy Meal" : "Needs Improvement",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      Text(
                        "AI Confidence",
                        style: GoogleFonts.poppins(color: Colors.white70),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "${result.confidence}%",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // ============================================================
          // MATCH STATUS MESSAGE
          // ============================================================
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: matched
                  ? const Color(0xffE8F5E9)
                  : const Color(0xfffff3e0),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: matched
                    ? const Color(0xffA5D6A7)
                    : const Color(0xffffcc80),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  matched ? Icons.task_alt_rounded : Icons.info_outline_rounded,
                  color: matched
                      ? const Color(0xff2E7D32)
                      : const Color(0xffE65100),
                  size: 28,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        matched
                            ? "Task Completed!"
                            : "Today's meal was not matched",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: matched
                              ? const Color(0xff2E7D32)
                              : const Color(0xffE65100),
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        matched
                            ? "Great job! You completed today's meal task successfully."
                            : "Please prepare or capture the assigned meal and try again.",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          height: 1.5,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // ============================================================
          // NUTRITION CARDS
          // ============================================================
          Row(
            children: [
              Expanded(
                child: NutritionCard(
                  icon: Icons.local_fire_department,
                  color: Colors.orange,
                  title: "Calories",
                  value: "${result.calories}",
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: NutritionCard(
                  icon: Icons.fitness_center,
                  color: Colors.blue,
                  title: "Protein",
                  value: "${result.protein} g",
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: NutritionCard(
                  icon: Icons.rice_bowl,
                  color: Colors.brown,
                  title: "Carbs",
                  value: "${result.carbs} g",
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: NutritionCard(
                  icon: Icons.opacity,
                  color: Colors.red,
                  title: "Fat",
                  value: "${result.fat} g",
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          NutritionCard(
            icon: Icons.eco,
            color: Colors.green,
            title: "Fiber",
            value: "${result.fiber} g",
          ),

          const SizedBox(height: 30),

          // ============================================================
          // AI FEEDBACK
          // ============================================================
          Text(
            "AI Feedback",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              result.feedback.isEmpty
                  ? "No additional feedback available."
                  : result.feedback,
              style: GoogleFonts.poppins(fontSize: 15, height: 1.6),
            ),
          ),

          const SizedBox(height: 28),

          // ============================================================
          // SUGGESTIONS
          // ============================================================
          Text(
            "Suggestions",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: result.suggestions.isEmpty
                  ? [
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          "No suggestions available.",
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ]
                  : result.suggestions.map((suggestion) {
                      return ListTile(
                        leading: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        title: Text(suggestion, style: GoogleFonts.poppins()),
                      );
                    }).toList(),
            ),
          ),

          const SizedBox(height: 35),

          // ============================================================
          // ACTION BUTTON
          // ============================================================
          SizedBox(
            height: 58,
            child: ElevatedButton.icon(
              onPressed: () {
                if (matched) {
                  // ================================================
                  // MATCHED → TASK COMPLETE
                  // ================================================

                  Navigator.pop(context, true);
                } else {
                  // ================================================
                  // NOT MATCHED → RETRY
                  // ================================================

                  Navigator.pop(context, false);
                }
              },

              icon: Icon(
                matched ? Icons.check_circle_outline : Icons.refresh_rounded,
              ),

              label: Text(
                matched ? "Complete Task" : "Retry",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),

              style: ElevatedButton.styleFrom(
                backgroundColor: matched
                    ? const Color(0xff4CAF50)
                    : const Color(0xffE65100),
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
    );
  }
}
