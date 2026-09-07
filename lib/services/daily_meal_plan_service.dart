class DailyMealPlanService {
  static final List<String> _breakfastOptions = [
    "Oatmeal with banana and nuts",
    "Boiled eggs with whole wheat toast",
    "Vegetable khichuri with boiled egg",
    "Roti with mixed vegetable curry",
    "Fruit bowl with yogurt and seeds",
    "Egg omelette with brown bread and cucumber",
    "Poha with peanuts and green peas",
  ];

  static final List<String> _lunchOptions = [
    "Steamed rice, mixed vegetables, and lentils (dal)",
    "Brown rice, grilled fish, and green salad",
    "Steamed rice, chicken curry, and sautéed spinach",
    "Rice, mashed potato (alu bhorta), and thick lentil soup",
    "Roti with chicken stew and cucumber salad",
    "Steamed rice with egg curry and mixed vegetable bhaji",
    "Khichuri with tomato chutney and fried eggplant",
  ];

  static final List<String> _dinnerOptions = [
    "Roti with daal and vegetable stew",
    "Grilled chicken breast with steamed broccoli and carrots",
    "Light vegetable soup with whole wheat toast",
    "Boiled chickpeas with cucumber and tomato salad",
    "Roti with mixed vegetable curry and curd",
    "Steamed fish with sautéed beans and carrots",
    "Oats vegetable porridge with boiled egg",
  ];

  /// আজকের দিনের জন্য ব্রেকফাস্ট
  static String getTodayBreakfast() {
    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year, 1, 1))
        .inDays;
    return _breakfastOptions[dayOfYear % _breakfastOptions.length];
  }

  /// আজকের দিনের জন্য লাঞ্চ
  static String getTodayLunch() {
    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year, 1, 1))
        .inDays;
    return _lunchOptions[dayOfYear % _lunchOptions.length];
  }

  /// আজকের দিনের জন্য ডিনার
  static String getTodayDinner() {
    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year, 1, 1))
        .inDays;
    return _dinnerOptions[dayOfYear % _dinnerOptions.length];
  }
}
