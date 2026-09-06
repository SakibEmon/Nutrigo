import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class NutritionScoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const int pointsPerMeal = 1;
  static const int pointsCourseLesson = 3;
  static const int pointsAiChat = 1;
  static const int pointsMealAnalysis = 1;
  static const int maxQuarterPoints = 100; // টেস্ট ও সহজ হিসাবের জন্য 100

  static Map<String, dynamic> getScoreDetails(int percentage) {
    if (percentage >= 75) {
      return {
        'status': 'Excellent!',
        'subtitle': "You're doing great. Keep maintaining healthy habits.",
      };
    } else if (percentage >= 50) {
      return {
        'status': 'Good!',
        'subtitle': 'Steady progress! Keep logging your meals daily.',
      };
    } else if (percentage >= 25) {
      return {
        'status': 'Improving',
        'subtitle': 'On the right track! Complete daily tasks to level up.',
      };
    } else {
      return {
        'status': 'Needs Focus',
        'subtitle': 'Start completing your meals & lessons to boost score.',
      };
    }
  }

  static Future<void> addPoints(int earnedPoints, String reason) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDocRef = _firestore.collection('users').doc(user.uid);

    try {
      final doc = await userDocRef.get();

      if (!doc.exists || doc.data()?['nutrition_points'] == null) {
        await userDocRef.set({
          'nutrition_points': earnedPoints,
          'score_cycle_start': FieldValue.serverTimestamp(),
          'last_point_reason': reason,
        }, SetOptions(merge: true));
        debugPrint("✅ Initialized Nutrition Score: $earnedPoints pts");
        return;
      }

      final data = doc.data()!;
      DateTime cycleStart = DateTime.now();
      if (data['score_cycle_start'] != null) {
        cycleStart = (data['score_cycle_start'] as Timestamp).toDate();
      }

      final daysPassed = DateTime.now().difference(cycleStart).inDays;

      // ৯০ দিন পূর্ণ হলে রিসেট
      if (daysPassed >= 90) {
        final currentPoints = (data['nutrition_points'] ?? 0) as int;
        final currentPercent = ((currentPoints / maxQuarterPoints) * 100)
            .clamp(0, 100)
            .toInt();

        await userDocRef.collection('score_history').add({
          'cycle_start': cycleStart,
          'cycle_end': DateTime.now(),
          'final_score': currentPercent,
          'final_status': getScoreDetails(currentPercent)['status'],
          'total_points': currentPoints,
          'archived_at': FieldValue.serverTimestamp(),
        });

        await userDocRef.update({
          'score_cycle_start': FieldValue.serverTimestamp(),
          'nutrition_points': earnedPoints,
          'last_point_reason': reason,
        });
        return;
      }

      // সাধারণ পয়েন্ট যোগ
      await userDocRef.update({
        'nutrition_points': FieldValue.increment(earnedPoints),
        'last_point_reason': reason,
        'last_updated_at': FieldValue.serverTimestamp(),
      });
      debugPrint("✅ Added $earnedPoints points for: $reason");
    } catch (e) {
      debugPrint("❌ Score Update Error: $e");
    }
  }
}
