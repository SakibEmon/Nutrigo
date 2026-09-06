import 'dart:convert';

class NutritionResult {
  final String mealName;
  final bool healthy;
  final bool mealMatched;
  final int confidence;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final int fiber;
  final String feedback;
  final List<String> suggestions;

  NutritionResult({
    required this.mealName,
    required this.healthy,
    required this.mealMatched,
    required this.confidence,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.feedback,
    required this.suggestions,
  });

  factory NutritionResult.fromJson(String jsonString) {
    dynamic decoded;

    try {
      decoded = jsonDecode(jsonString);
    } catch (_) {
      throw Exception('AI returned invalid JSON.');
    }

    if (decoded is! Map) {
      throw Exception('AI returned an invalid nutrition result.');
    }

    final Map<String, dynamic> data = Map<String, dynamic>.from(decoded);

    final rawSuggestions = data['suggestions'];

    List<String> parsedSuggestions = [];

    if (rawSuggestions is List) {
      parsedSuggestions = rawSuggestions
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList();
    }

    return NutritionResult(
      mealName: data['meal_name']?.toString() ?? '',

      healthy: data['healthy'] == true,

      mealMatched: data['meal_matched'] == true,

      confidence: _toInt(data['confidence']),

      calories: _toInt(data['calories']),

      protein: _toInt(data['protein']),

      carbs: _toInt(data['carbs']),

      fat: _toInt(data['fat']),

      fiber: _toInt(data['fiber']),

      feedback: data['feedback']?.toString() ?? '',

      suggestions: parsedSuggestions,
    );
  }

  static int _toInt(dynamic value) {
    if (value is num) {
      return value.round();
    }

    if (value is String) {
      return double.tryParse(value)?.round() ?? 0;
    }

    return 0;
  }
}
