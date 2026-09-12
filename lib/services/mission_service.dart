import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MissionModel {
  final String dateKey; // Format: YYYY-MM-DD
  final bool breakfast;
  final bool lunch;
  final bool dinner;

  MissionModel({
    required this.dateKey,
    this.breakfast = false,
    this.lunch = false,
    this.dinner = false,
  });

  Map<String, dynamic> toJson() => {
    'dateKey': dateKey,
    'breakfast': breakfast,
    'lunch': lunch,
    'dinner': dinner,
  };

  factory MissionModel.fromJson(Map<String, dynamic> json) => MissionModel(
    dateKey: json['dateKey'] ?? '',
    breakfast: json['breakfast'] ?? false,
    lunch: json['lunch'] ?? false,
    dinner: json['dinner'] ?? false,
  );
}

class MissionService {
  static String get _userId {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid ?? 'guest';
  }

  static String _key(String dateKey) => "daily_mission_${_userId}_$dateKey";

  static String getTodayKey() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  /// Selected date mission retrieval
  static Future<MissionModel> getMission(String dateKey) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key(dateKey));
    if (data == null) {
      return MissionModel(dateKey: dateKey);
    }
    return MissionModel.fromJson(jsonDecode(data));
  }

  /// নির্দিষ্ট মিল সম্পন্ন হিসেবে সেভ করা
  static Future<void> completeMeal(String mealType) async {
    final dateKey = getTodayKey();
    final current = await getMission(dateKey);

    bool b = current.breakfast;
    bool l = current.lunch;
    bool d = current.dinner;

    if (mealType.toLowerCase() == 'breakfast') b = true;
    if (mealType.toLowerCase() == 'lunch') l = true;
    if (mealType.toLowerCase() == 'dinner') d = true;

    final updated = MissionModel(
      dateKey: dateKey,
      breakfast: b,
      lunch: l,
      dinner: d,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(dateKey), jsonEncode(updated.toJson()));
  }

  /// Meal validation based on time window
  static bool isWithinTimeWindow(String mealType) {
    final hour = DateTime.now().hour;

    if (mealType.toLowerCase() == 'breakfast') {
      // Mornning 7:00 AM to 11:00 AM
      return hour >= 7 && hour < 11;
    } else if (mealType.toLowerCase() == 'lunch') {
      // Afternoon 12:00 PM to 3:00 PM
      return hour >= 12 && hour < 15;
    } else if (mealType.toLowerCase() == 'dinner') {
      // Night 8:00 PM to 10:00 PM
      return hour >= 20 && hour < 22;
    }
    return false;
  }
}
