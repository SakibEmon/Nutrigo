import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/meal_history.dart';

class MealHistoryService {
  static const String _baseKey = "meal_history";

  /// প্রতিটি ইউজারের জন্য আলাদা এবং ইউনিক Key তৈরি করে
  static String _getUserKey() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return "${_baseKey}_${user.uid}";
    }
    return _baseKey; // ইউজার লগইন না থাকলে ফলব্যাক
  }

  /// Save new meal for current user
  static Future<void> saveMeal(MealHistory meal) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getUserKey();

    final List<String> meals = prefs.getStringList(key) ?? [];

    meals.insert(0, jsonEncode(meal.toJson()));

    await prefs.setStringList(key, meals);
  }

  /// Load meals only for current user
  static Future<List<MealHistory>> loadMeals() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getUserKey();

    final List<String> meals = prefs.getStringList(key) ?? [];

    return meals.map((e) => MealHistory.fromJson(jsonDecode(e))).toList();
  }

  /// Delete one meal for current user
  static Future<void> deleteMeal(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getUserKey();

    final List<String> meals = prefs.getStringList(key) ?? [];

    if (index >= 0 && index < meals.length) {
      meals.removeAt(index);
      await prefs.setStringList(key, meals);
    }
  }

  /// Delete all meals for current user
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getUserKey();

    await prefs.remove(key);
  }
}
