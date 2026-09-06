import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'notification_service.dart';

class GamificationService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // ============================================================
  // DAILY STREAK & MEAL LOGIN XP CHECK
  // ============================================================
  static Future<void> checkDailyLoginAndStreak() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDocRef = _firestore.collection('users').doc(user.uid);

    try {
      final doc = await userDocRef.get();
      final data = doc.data() ?? {};

      final now = DateTime.now();
      final todayDateStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      int currentStreak = data['streakCount'] ?? 0;
      int currentXp = data['xp'] ?? 0;
      String? lastActiveDate = data['lastActiveDate'];
      Map<String, dynamic> mealLogins = Map<String, dynamic>.from(
        data['mealLoginsToday'] ?? {},
      );
      String? lastMealLoginDate = data['lastMealLoginDate'];

      // ১. STREAK CALCULATION
      if (lastActiveDate == null) {
        currentStreak = 1;
      } else {
        final lastDate = DateTime.parse(lastActiveDate);
        final differenceInDays = DateTime(now.year, now.month, now.day)
            .difference(DateTime(lastDate.year, lastDate.month, lastDate.day))
            .inDays;

        if (differenceInDays == 1) {
          currentStreak += 1;
        } else if (differenceInDays > 1) {
          currentStreak = 1;
        }
      }

      // ২. MEAL TIME LOGIN XP CHECK (Breakfast, Lunch, Dinner)
      if (lastMealLoginDate != todayDateStr) {
        mealLogins = {"breakfast": false, "lunch": false, "dinner": false};
      }

      int earnedMealXp = 0;
      String mealName = "";
      final hour = now.hour;

      // Breakfast Window (6:00 AM - 11:00 AM)
      if (hour >= 6 && hour < 11 && mealLogins['breakfast'] != true) {
        mealLogins['breakfast'] = true;
        earnedMealXp += 15;
        mealName = "Breakfast Check-in";
      }
      // Lunch Window (12:00 PM - 4:00 PM)
      else if (hour >= 12 && hour < 16 && mealLogins['lunch'] != true) {
        mealLogins['lunch'] = true;
        earnedMealXp += 15;
        mealName = "Lunch Check-in";
      }
      // Dinner Window (7:00 PM - 11:00 PM)
      else if (hour >= 19 && hour < 23 && mealLogins['dinner'] != true) {
        mealLogins['dinner'] = true;
        earnedMealXp += 15;
        mealName = "Dinner Check-in";
      }

      currentXp += earnedMealXp;

      await userDocRef.set({
        'streakCount': currentStreak,
        'xp': currentXp,
        'lastActiveDate': todayDateStr,
        'lastMealLoginDate': todayDateStr,
        'mealLoginsToday': mealLogins,
      }, SetOptions(merge: true));

      if (earnedMealXp > 0) {
        await NotificationService.showAndSaveNotification(
          title: "Meal Check-in Bonus! ⭐",
          body: "Great job! You earned +$earnedMealXp XP for $mealName.",
          type: "xp",
        );
      }
    } catch (e) {
      debugPrint("Gamification update error: $e");
    }
  }

  // ============================================================
  // ADD XP FOR ANY COMPLETED TASK
  // ============================================================
  static Future<void> addXp(int points, {String reason = ""}) async {
    final user = _auth.currentUser;
    if (user == null || points <= 0) return;

    try {
      final userDocRef = _firestore.collection('users').doc(user.uid);
      await userDocRef.set({
        'xp': FieldValue.increment(points),
      }, SetOptions(merge: true));
      debugPrint("Earned $points XP for: $reason");

      await NotificationService.showAndSaveNotification(
        title: "XP Earned! ⭐",
        body: reason.isNotEmpty
            ? "Awesome! You earned +$points XP for $reason."
            : "Awesome! You earned +$points XP.",
        type: "xp",
      );
    } catch (e) {
      debugPrint("Error adding XP: $e");
    }
  }
}
