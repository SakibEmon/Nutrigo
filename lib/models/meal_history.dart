class MealHistory {
  final String imagePath;

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

  final DateTime scannedAt;

  MealHistory({
    required this.imagePath,
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
    required this.scannedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'imagePath': imagePath,
      'mealName': mealName,
      'healthy': healthy,
      'mealMatched': mealMatched,
      'confidence': confidence,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'feedback': feedback,
      'suggestions': suggestions,
      'scannedAt': scannedAt.toIso8601String(),
    };
  }

  factory MealHistory.fromJson(Map<String, dynamic> json) {
    final rawSuggestions = json['suggestions'];

    List<String> parsedSuggestions = [];

    if (rawSuggestions is List) {
      parsedSuggestions = rawSuggestions
          .map((item) => item.toString())
          .toList();
    }

    return MealHistory(
      imagePath: json['imagePath']?.toString() ?? '',

      mealName: json['mealName']?.toString() ?? '',

      healthy: json['healthy'] == true,

      mealMatched: json['mealMatched'] == true,

      confidence: _toInt(json['confidence']),

      calories: _toInt(json['calories']),

      protein: _toInt(json['protein']),

      carbs: _toInt(json['carbs']),

      fat: _toInt(json['fat']),

      fiber: _toInt(json['fiber']),

      feedback: json['feedback']?.toString() ?? '',

      suggestions: parsedSuggestions,

      scannedAt:
          DateTime.tryParse(json['scannedAt']?.toString() ?? '') ??
          DateTime.now(),
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
