import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/image/image_picker_service.dart';
import '../../services/gamification_service.dart';
import '../../services/notification_service.dart';
import '../notifications/notification_screen.dart';
import '../tasks/meal_preview_screen.dart';

import 'widgets/ai_command_center.dart';
import 'widgets/continue_learning_card.dart';
import 'widgets/greeting_section.dart';
import 'widgets/mission_section.dart';
import 'widgets/nutrition_card.dart';
import 'widgets/recent_meals_section.dart';
import 'widgets/stats_section.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // ============================================================
  // STAND-ALONE MEAL SCANNER (ONLY FOOD GIVES +5 XP)
  // ============================================================

  Future<void> _scanMeal(BuildContext context) async {
    try {
      final File? image = await ImagePickerService.pickFromCamera();

      if (image == null) return;

      if (!context.mounted) return;

      // MealPreviewScreen-এ কোনো স্পেসিফিক টাস্কের সাথে যুক্ত না করে সাধারণ ফুড স্ক্যানার হিসেবে ওপেন হবে
      final bool? isFoodValid = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => MealPreviewScreen(
            image: image,
            targetMeal: "Food item", // Stand-alone analysis
          ),
        ),
      );

      if (!context.mounted) return;

      // যদি AI কনফার্ম করে এটি সত্যিকারের খাবার, তবেই +5 XP যোগ হবে
      if (isFoodValid == true) {
        await GamificationService.addXp(5, reason: "Valid Food Scanned");

        // খাবার স্ক্যান সম্পূর্ণ হলে পুশ নোটিফিকেশন পাঠানো ও হিস্ট্রিতে সেভ করা
        await NotificationService.showAndSaveNotification(
          title: "Meal Scan Complete! 🍽️",
          body: "Your nutritional analysis is ready. Check your recent meals!",
          type: "meal",
          payload: "recent_meals",
        );

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Nutritional analysis complete! +5 XP earned ⭐"),
            backgroundColor: Color(0xff4CAF50),
          ),
        );
      } else if (isFoodValid == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No food detected! Scan a valid meal to earn XP."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Could not scan meal: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FBF8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // TOP BAR (Nutrigo Brand & Notification Bell)
              // ==================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Nutrigo",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: IconButton(
                      tooltip: "Notifications",
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        color: Color(0xff4CAF50),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Greeting
              const GreetingSection(),

              const SizedBox(height: 35),

              // Nutrition
              const NutritionCard(),

              const SizedBox(height: 35),

              // Today's Mission
              const MissionSection(),

              const SizedBox(height: 35),

              // Continue Learning
              const ContinueLearningCard(),

              const SizedBox(height: 35),

              // STATS (Day Streak & XP only)
              const StatsSection(),

              const SizedBox(height: 35),

              // AI Command Center
              AiCommandCenter(onScanMeal: () => _scanMeal(context)),

              const SizedBox(height: 35),

              // Recent Meals
              const RecentMealsSection(),

              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }
}
