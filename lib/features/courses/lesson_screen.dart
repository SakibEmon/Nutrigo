import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../tasks/daily_task_screen.dart';
import 'course_model.dart';

class LessonScreen extends StatelessWidget {
  final String lessonTitle;
  final int weekNumber;
  final int dayNumber;

  final String courseId;
  final List<Lesson> defaultLessons;

  const LessonScreen({
    super.key,
    required this.lessonTitle,
    required this.weekNumber,
    required this.dayNumber,
    required this.courseId,
    required this.defaultLessons,
  });

  // ============================================================
  // COURSE & DAY SPECIFIC MEAL + MULTI-LANGUAGE CONTENT
  // ============================================================
  Map<String, String> _getLessonContent() {
    // ------------------------------------------------------------
    // 1. HEALTHY EATING BASICS (nutrition101)
    // ------------------------------------------------------------
    if (courseId == "nutrition101") {
      switch (dayNumber) {
        case 1:
          return {
            "title_bn": "ডিম ও মিক্সড সবজি দিয়ে স্বাস্থ্যকর ভাত",
            "title_en": "Vegetable Egg Fried Rice",
            "benefits_bn":
                "ডিমের প্রোটিন এবং সবজির ফাইবার হজমশক্তি ঠিক রাখে এবং দীর্ঘক্ষণ শক্তি জোগায়।",
            "benefits_en":
                "Egg protein combined with dietary fiber from mixed vegetables supports smooth digestion and provides sustained energy.",
            "steps_bn":
                "১. সামান্য তেলে পেঁয়াজ, রসুন ও গাজর-মটরশুঁটি ভাজুন।\n২. ২টি ডিম দিয়ে স্ক্র্যাম্বল করুন।\n৩. রান্না করা ভাত ও গোলমরিচ দিয়ে নেড়ে নামিয়ে নিন।",
            "steps_en":
                "1. Sauté onion, garlic, carrots, and peas in 1 tsp oil.\n2. Add 2 eggs and scramble well.\n3. Add cooked rice and black pepper, toss over medium heat and serve.",
            "videoId": "vAtwx4ifKv8", // Atanur Rannaghar Veg Egg Fried Rice
          };
        case 2:
          return {
            "title_bn": "ডিম ও শসার ফ্রেশ সালাদ",
            "title_en": "Boiled Egg & Vegetable Salad",
            "benefits_bn":
                "উচ্চমাত্রার প্রোটিন এবং কম ক্যালোরি থাকায় শরীরের বাড়তি ওজন নিয়ন্ত্রণে কার্যকর।",
            "benefits_en":
                "High protein and low calorie profile make it ideal for weight management and lean muscle retention.",
            "steps_bn":
                "১. ২টি ডিম ৯ মিনিট সিদ্ধ করে টুকরো করুন।\n২. শসা, টমেটো ও লেটুস পাতা কুচিয়ে নিন।\n৩. লেবুর রস, লবণ ও অলিভ অয়েল দিয়ে মিশিয়ে পরিবেশন করুন।",
            "steps_en":
                "1. Boil 2 eggs for 9 minutes, peel and slice.\n2. Dice cucumber, tomatoes, and lettuce.\n3. Drizzle with olive oil, lemon juice, and a pinch of black pepper.",
            "videoId": "Ljv21I1kJx4", // Healthy Egg Salad
          };
        case 3:
          return {
            "title_bn": "পাতলা মসুর ডাল, ভাত ও সবজি ভাজি",
            "title_en": "Rice, Lentils (Dal) & Veggies",
            "benefits_bn":
                "ডাল ও ভাত মিলে সম্পূর্ণ প্রোটিন তৈরি করে যা পেশি গঠনে সহায়তা করে।",
            "benefits_en":
                "Lentils and rice form a complete protein with balanced amino acids, iron, and slow-burning carbs.",
            "steps_bn":
                "১. হলুদ ও রসুন দিয়ে মসুর ডাল সিদ্ধ করুন।\n২. জিরে ও পেঁয়াজ দিয়ে হালকা বাগার দিন।\n৩. মৌসুমি সবজির সাথে গরম ভাতে পরিবেশন করুন।",
            "steps_en":
                "1. Boil red lentils with turmeric, garlic, and green chilies.\n2. Temper lightly with cumin seeds and sliced onion.\n3. Serve hot alongside steamed seasonal greens and rice.",
            "videoId": "n5ujXCscPRE", // Banglar Rannaghor Basic Dal
          };
        case 4:
          return {
            "title_bn": "চিকেন ব্রেস্ট ও লাল চালের ভাত",
            "title_en": "Chicken with Sautéed Veggies & Brown Rice",
            "benefits_bn":
                "কমপ্লেক্স কার্বোহাইড্রেট ও প্রোটিনের মেলবন্ধন, যা রক্তে চিনি হঠাৎ বাড়তে দেয় না।",
            "benefits_en":
                "Complex carbs paired with lean poultry protein repair muscle fibers and prevent insulin spikes.",
            "steps_bn":
                "১. চিকেন আদা-রসুন ও গোলমরিচ দিয়ে ম্যারিনেট করুন।\n২. প্যানে হালকা আঁচে সেঁকে নিন।\n৩. লাল চালের ভাত ও সেদ্ধ ব্রকলি দিয়ে পরিবেশন করুন।",
            "steps_en":
                "1. Marinate chicken breast with ginger, garlic, and black pepper.\n2. Pan-sear on medium heat for 6-8 minutes.\n3. Serve with steamed brown rice and tender broccoli.",
            "videoId": "2LbWQCnqWHE", // Healthy Chicken Fried Brown Rice
          };
        case 5:
          return {
            "title_bn": "টক দই ও ফ্রুট বাটি",
            "title_en": "Fresh Fruit Bowl & Probiotic Yogurt",
            "benefits_bn":
                "দইয়ের প্রোবায়োটিক পেটের স্বাস্থ্য রক্ষা করে এবং ফলমূল প্রয়োজনীয় ভিটামিন সরবরাহ করে।",
            "benefits_en":
                "Active probiotics nurture gut microbiota while fresh fruits supply essential Vitamin C and antioxidants.",
            "steps_bn":
                "১. এক কাপ টক দই বাটিতে নিন।\n২. আপেল ও পেঁপে কুচি করে মেশান।\n৩. উপরে বাদাম কুচি ছড়িয়ে দিন।",
            "steps_en":
                "1. Scoop 1 cup plain curd or Greek yogurt into a bowl.\n2. Top with chopped papaya, apple, and pomegranate.\n3. Sprinkle crushed almonds and seeds before serving.",
            "videoId": "H7G8Z4tW5f8", // Fruit & Yogurt Bowl
          };
        case 6:
          return {
            "title_bn": "লাল আটার ভেজিটেবল স্যান্ডউইচ",
            "title_en": "Whole Grain Vegetable Sandwich",
            "benefits_bn":
                "স্বাস্থ্যকর ফ্যাট ও উচ্চমাত্রার আঁশ যা হার্ট ভালো রাখে এবং ক্ষুধা কমায়।",
            "benefits_en":
                "Heart-healthy unsaturated fats and high dietary fiber curb appetite and maintain steady metabolism.",
            "steps_bn":
                "১. ব্রাউন ব্রেডে শসা, টমেটো ও সেদ্ধ ডিমের স্লাইস দিন।\n২. সামান্য গোলমরিচ গুঁড়ো দিয়ে টোস্ট করে নিন।",
            "steps_en":
                "1. Layer whole grain bread with sliced cucumber, tomato, and boiled egg.\n2. Sprinkle black pepper and toast lightly until crisp.",
            "videoId": "Uq2oOaN8dZ8", // Healthy Veg Sandwich
          };
        case 7:
          return {
            "title_bn": "পালং শাক ভাজি ও ডাল-ভাত",
            "title_en": "Steamed Greens & Balanced Nutrition Plate",
            "benefits_bn":
                "প্রচুর পরিমাণে আয়রন, ভিটামিন সি এবং জিংক সরবরাহ করে।",
            "benefits_en":
                "Supplies abundant bioavailable iron, magnesium, and zinc for overall immune defense.",
            "steps_bn":
                "১. রসুন ও কাঁচামরিচ দিয়ে তাজা শাক হালকা ভেজে নিন।\n২. ডাল ও ভাতের সাথে পরিবেশন করুন।",
            "steps_en":
                "1. Lightly sauté dark leafy spinach with garlic and green chilies.\n2. Plate alongside a warm portion of lentils and steamed rice.",
            "videoId": "f68iN991v64", // Palong Shak Bhaji
          };
        case 8:
          return {
            "title_bn": "দুধ ও ওটমিলের স্বাস্থ্যকর নাস্তা",
            "title_en": "Oatmeal with Nuts & Sliced Fruits",
            "benefits_bn":
                "বিটা-গ্লুকান ফাইবার হজম ত্বরান্বিত করে এবং কোষ্ঠকাঠিন্য দূর করে।",
            "benefits_en":
                "Beta-glucan soluble fiber reduces LDL cholesterol and supports regular bowel regularity.",
            "steps_bn":
                "১. ওটস দুধে ৫ মিনিট ফুটিয়ে নিন।\n২. কলা বা আপেলের টুকরো এবং বাদাম ছড়িয়ে দিন।",
            "steps_en":
                "1. Simmer 1/2 cup rolled oats in milk or water for 5 minutes.\n2. Garnish with sliced banana, apples, and crushed nuts.",
            "videoId": "lMQMEJFgz7Y", // Healthy Oats Recipe
          };
        case 9:
          return {
            "title_bn": "লেবু ও ভেষজ দিয়ে ভাপা মাছ",
            "title_en": "Steamed Fish with Greens & Lemon",
            "benefits_bn":
                "ওমেগা-৩ ফ্যাটি অ্যাসিড যা মস্তিষ্কের সতেজতা ও হার্ট সুস্থ রাখে।",
            "benefits_en":
                "Rich in anti-inflammatory EPA/DHA omega-3 fatty acids for cardiovascular and brain longevity.",
            "steps_bn":
                "১. মাছের ফিলেতে লেবু, লবণ ও গোলমরিচ মাখান।\n২. স্টিমারে ৮-১০ মিনিট ভাপিয়ে নিন।",
            "steps_en":
                "1. Rub fresh fish fillet with lemon juice, salt, and crushed pepper.\n2. Steam over medium heat for 8-10 minutes until flaky.",
            "videoId": "Q65_rXF9Tx0", // Traditional Bhapa Fish
          };
        case 10:
          return {
            "title_bn": "ডিম ও সবজির ক্লিয়ার স্যুপ",
            "title_en": "Boiled Egg & Vegetable Clear Soup",
            "benefits_bn": "সকালে সহজে হজমযোগ্য হালকা ও পুষ্টিকর খাবার।",
            "benefits_en":
                "Light, easily digestible, and hydrating soup enriched with vital trace minerals.",
            "steps_bn":
                "১. সবজি কুচি পানিতে সেদ্ধ করে স্যুপের স্টক তৈরি করুন।\n২. সেদ্ধ ডিম টুকরো করে দিয়ে পরিবেশন করুন।",
            "steps_en":
                "1. Simmer finely chopped vegetables in water with black pepper.\n2. Slice a hard-boiled egg on top and serve hot.",
            "videoId": "WqIvhYvG028", // Clear Veg Soup with Egg
          };
        default:
          return {
            "title_bn": "সম্পূর্ণ সুষম পুষ্টির প্লেট",
            "title_en": "Balanced Nutrition Plate",
            "benefits_bn": "সব ধরনের পুষ্টি উপাদানের পারফেক্ট ব্যালান্স।",
            "benefits_en":
                "Maintains optimum balance of 50% fiber, 25% protein, and 25% complex carbs.",
            "steps_bn":
                "১. অর্ধেক প্লেট সবজি, বাকি অর্ধেক প্রোটিন ও শর্করা রাখুন।",
            "steps_en":
                "1. Fill 50% plate with vegetables, 25% lean protein, and 25% whole grains.",
            "videoId": "vAtwx4ifKv8",
          };
      }
    }

    // ------------------------------------------------------------
    // 2. PROTEIN & BODY GROWTH (protein)
    // ------------------------------------------------------------
    if (courseId == "protein") {
      switch (dayNumber) {
        case 1:
          return {
            "title_bn": "২টি সেদ্ধ ডিম ও শসার টুকরো",
            "title_en": "2 Boiled Eggs with Cucumber Slices",
            "benefits_bn": "প্রথম শ্রেণীর প্রোটিন যা দ্রুত শরীরে শোষিত হয়।",
            "benefits_en":
                "Top-tier bioavailability protein that repairs muscular breakdown quickly.",
            "steps_bn": "১. ডিম সেদ্ধ করে শসা কেটে গোলমরিচ দিয়ে পরিবেশন করুন।",
            "steps_en":
                "1. Boil 2 eggs, quarter them, and serve with crisp cucumber slices.",
            "videoId": "Ljv21I1kJx4",
          };
        case 2:
          return {
            "title_bn": "গ্রিল্ড চিকেন ও স্টিমড ব্রকলি",
            "title_en": "Grilled Chicken Breast with Steamed Broccoli",
            "benefits_bn": "টিস্যু মেরামতে এবং পেশি বৃদ্ধিতে সহায়তা করে।",
            "benefits_en":
                "Dense lean poultry protein paired with sulforaphane-rich cruciferous vegetables.",
            "steps_bn": "১. চিকেন সেঁকে নিন এবং ব্রকলি ভাপিয়ে নিন।",
            "steps_en":
                "1. Grill seasoned chicken breast and steam broccoli florets for 4 minutes.",
            "videoId": "2LbWQCnqWHE",
          };
        case 3:
          return {
            "title_bn": "ঘন মসুর ডাল ও কাঁচা সালাদ",
            "title_en": "Thick Lentil (Dal) Bowl with Green Salad",
            "benefits_bn":
                "উচ্চমাত্রার উদ্ভিজ্জ প্রোটিন ও রক্তের হিমোগ্লোবিন বৃদ্ধির উপাদান।",
            "benefits_en":
                "Plant-based protein packed with folate and iron for red blood cell health.",
            "steps_bn": "১. ঘন করে ডাল রান্না করে সালাদের সাথে খান।",
            "steps_en":
                "1. Cook lentils thick with mild spices and pair with fresh garden salad.",
            "videoId": "n5ujXCscPRE",
          };
        case 5:
          return {
            "title_bn": "সেদ্ধ ছোলার সালাদ",
            "title_en": "Boiled Chickpea (Chola) Salad",
            "benefits_bn":
                "দীর্ঘক্ষণ শক্তি ধরে রাখে এবং রক্তের সুগার স্বাভাবিক রাখে।",
            "benefits_en":
                "Low-glycemic complex carbohydrates and fiber keep fullness intact.",
            "steps_bn":
                "১. ছোলা সেদ্ধ করে পেঁয়াজ, কাঁচামরিচ, শসা ও লেবু দিয়ে মাখুন।",
            "steps_en":
                "1. Toss boiled chickpeas with diced tomatoes, onions, chilies, and lemon.",
            "videoId": "YdY-Lp8Zeq8", // Chola Salad
          };
        default:
          return {
            "title_bn": "হাই-প্রোটিন রিকভারি প্লেট",
            "title_en": "High-Protein Recovery Plate",
            "benefits_bn":
                "শরীরচর্চা ও পরিশ্রমের পর দ্রুত রিকভারিতে সাহায্য করে।",
            "benefits_en":
                "A balanced combination of lean protein and essential electrolytes.",
            "steps_bn": "১. ডিম, ছোলা ও চিকেন দিয়ে সমন্বিত প্লেট তৈরি করুন।",
            "steps_en":
                "1. Combine boiled eggs, chickpeas, and lean grilled meat on one plate.",
            "videoId": "2LbWQCnqWHE",
          };
      }
    }

    // ------------------------------------------------------------
    // 3. VITAMINS & MINERALS (vitamins)
    // ------------------------------------------------------------
    if (courseId == "vitamins") {
      switch (dayNumber) {
        case 1:
          return {
            "title_bn": "গাজর ও কমলার তাজা সালাদ",
            "title_en": "Carrot & Orange Citrus Salad",
            "benefits_bn": "চোখের দৃষ্টিশক্তি ও ত্বকের উজ্জ্বলতা বৃদ্ধি করে।",
            "benefits_en":
                "Loaded with beta-carotene and Vitamin C for eye health and collagen support.",
            "steps_bn":
                "১. গাজর কুচি ও কমলার কোয়া একসাথে লেবুর রস দিয়ে মাখুন।",
            "steps_en":
                "1. Toss grated carrot with fresh orange segments and lemon dressing.",
            "videoId": "Ljv21I1kJx4",
          };
        case 2:
          return {
            "title_bn": "পালং শাক ও মসুর ডাল",
            "title_en": "Steamed Spinach with Lentils",
            "benefits_bn": "ভিটামিন এ এবং আয়রনের প্রাকৃতিক ভাণ্ডার।",
            "benefits_en":
                "Powerhouse of dietary iron and Vitamin A to fight fatigue and anaemia.",
            "steps_bn": "১. শাক ও ডাল হালকা আঁচে একসাথে রান্না করুন।",
            "steps_en":
                "1. Simmer washed spinach leaves alongside seasoned red lentils.",
            "videoId": "f68iN991v64",
          };
        default:
          return {
            "title_bn": "রংধনু পুষ্টি সালাদ",
            "title_en": "Multi-Vitamin Rainbow Salad",
            "benefits_bn": "সব ধরনের ফাইটোনিউট্রিয়েন্ট এক বাটিতে।",
            "benefits_en":
                "Delivers diverse phytonutrients and minerals through colorful produce.",
            "steps_bn": "১. বিভিন্ন রঙের ফল ও সবজি একত্রিত করে পরিবেশন করুন।",
            "steps_en":
                "1. Mix purple cabbage, carrots, greens, and fruits in a single bowl.",
            "videoId": "Ljv21I1kJx4",
          };
      }
    }

    // ------------------------------------------------------------
    // 4. SMART MEAL PLANNING (meal)
    // ------------------------------------------------------------
    return {
      "title_bn": "৫০-২৫-২৫ আদর্শ সুষম খাবার",
      "title_en": "Balanced 50-25-25 Meal Plate",
      "benefits_bn": "খাবারের ভারসাম্য বজায় রেখে শরীর মেদহীন রাখার সহজ উপায়।",
      "benefits_en":
          "The easiest framework to maintain lean mass and prevent fat gain.",
      "steps_bn":
          "১. প্লেটের অর্ধেক সবজি, বাকি অর্ধেক ভাত ও মাছ বা ডিম দিয়ে সাজান।",
      "steps_en":
          "1. Arrange 50% of the plate with greens, 25% with protein, and 25% with grains.",
      "videoId": "vAtwx4ifKv8",
    };
  }

  // ============================================================
  // OPEN DAILY TASK
  // ============================================================
  Future<void> _openDailyTask(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DailyTaskScreen(
          weekNumber: weekNumber,
          dayNumber: dayNumber,
          courseId: courseId,
          defaultLessons: defaultLessons,
        ),
      ),
    );

    if (result == true) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Lesson completed successfully!'),
          backgroundColor: Color(0xff4CAF50),
        ),
      );

      Navigator.pop(context, true);
    }
  }

  // ============================================================
  // READ LESSON MODAL (WITH BANGLA / ENGLISH SWITCH BUTTON)
  // ============================================================
  void _showLessonInfo(BuildContext context) {
    final details = _getLessonContent();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _LessonInfoSheet(
          lessonTitle: lessonTitle,
          weekNumber: weekNumber,
          dayNumber: dayNumber,
          details: details,
        );
      },
    );
  }

  // ============================================================
  // WATCH VIDEO (IN-APP DEDICATED PLAYER SCREEN)
  // ============================================================
  void _openInAppVideo(BuildContext context) {
    final details = _getLessonContent();
    final videoId = details["videoId"] ?? "vAtwx4ifKv8";
    final title = details["title_en"] ?? "Recipe Video";

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InAppVideoScreen(videoId: videoId, mealTitle: title),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FBF8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: Text(
          "Lesson",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _smallTag(
                  icon: Icons.calendar_today_rounded,
                  text: "Week $weekNumber",
                ),
                const SizedBox(width: 10),
                _smallTag(icon: Icons.today_rounded, text: "Day $dayNumber"),
              ],
            ),

            const SizedBox(height: 20),

            // HERO BANNER
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xff4CAF50), Color(0xff81C784)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff4CAF50).withOpacity(.20),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -25,
                    top: -25,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(.10),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -35,
                    bottom: -45,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(.08),
                      ),
                    ),
                  ),
                  const Center(
                    child: Icon(
                      Icons.restaurant_menu_rounded,
                      color: Colors.white,
                      size: 85,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Text(
              lessonTitle,
              style: GoogleFonts.poppins(
                fontSize: 27,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "Learn something useful today and put it "
              "into practice with your daily nutrition task.",
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.grey.shade700,
                height: 1.7,
              ),
            ),

            const SizedBox(height: 28),

            // PROGRESS
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xffE8F5E9),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Color(0xff4CAF50),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Learning",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "Learn → Practice → Complete",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.check_circle_outline,
                    color: Color(0xff4CAF50),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Text(
              "Today's Learning",
              style: GoogleFonts.poppins(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // READ LESSON
            _lessonSection(
              context: context,
              icon: Icons.menu_book_rounded,
              title: "Read Lesson",
              subtitle: "Learn the nutrition concept for today.",
              onTap: () {
                _showLessonInfo(context);
              },
            ),

            // WATCH VIDEO
            _lessonSection(
              context: context,
              icon: Icons.play_circle_fill_rounded,
              title: "Watch Video",
              subtitle: "Understand today's topic visually.",
              onTap: () {
                _openInAppVideo(context);
              },
            ),

            // DAILY ACTIVITY
            _lessonSection(
              context: context,
              icon: Icons.assignment_rounded,
              title: "Daily Activity",
              subtitle: "Apply what you learned today.",
              onTap: () {
                _openDailyTask(context);
              },
            ),

            const SizedBox(height: 30),

            // TASK PREVIEW
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xffE8F5E9),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.restaurant_rounded,
                      color: Color(0xff4CAF50),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Practical Task",
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "After learning today's topic, complete "
                          "your nutrition activity to continue your journey.",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 35),

            // CONTINUE BUTTON
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton.icon(
                onPressed: () {
                  _openDailyTask(context);
                },
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                ),
                label: Text(
                  "Continue to Daily Task",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff4CAF50),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Center(
              child: Text(
                "Complete today's task to continue learning.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallTag({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xffE8F5E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xff4CAF50)),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xff388E3C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lessonSection({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xffE8F5E9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: const Color(0xff4CAF50), size: 25),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STATEFUL READ LESSON SHEET (BANGLA <-> ENGLISH TOGGLE)
// ============================================================
class _LessonInfoSheet extends StatefulWidget {
  final String lessonTitle;
  final int weekNumber;
  final int dayNumber;
  final Map<String, String> details;

  const _LessonInfoSheet({
    required this.lessonTitle,
    required this.weekNumber,
    required this.dayNumber,
    required this.details,
  });

  @override
  State<_LessonInfoSheet> createState() => _LessonInfoSheetState();
}

class _LessonInfoSheetState extends State<_LessonInfoSheet> {
  bool _isEnglish = false;

  @override
  Widget build(BuildContext context) {
    final title = _isEnglish
        ? (widget.details["title_en"] ?? "")
        : (widget.details["title_bn"] ?? "");

    final benefits = _isEnglish
        ? (widget.details["benefits_en"] ?? "")
        : (widget.details["benefits_bn"] ?? "");

    final steps = _isEnglish
        ? (widget.details["steps_en"] ?? "")
        : (widget.details["steps_bn"] ?? "");

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // HEADER & LANGUAGE SWITCH BUTTON
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xffE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Color(0xff4CAF50),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.lessonTitle,
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          "Week ${widget.weekNumber} • Day ${widget.dayNumber}",
                          style: GoogleFonts.poppins(
                            color: const Color(0xff4CAF50),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // TOGGLE BUTTON (বাংলা / ENG)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isEnglish = !_isEnglish;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xffE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xff81C784)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.translate_rounded,
                            size: 16,
                            color: Color(0xff2E7D32),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _isEnglish ? "ENG" : "বাংলা",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xff2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 10),

              // TARGET MEAL
              Text(
                _isEnglish ? "Target Meal: $title" : "টার্গেট খাবার: $title",
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff2E7D32),
                ),
              ),
              const SizedBox(height: 10),

              // BENEFITS
              Text(
                _isEnglish
                    ? "Nutritional Impact & Benefits:"
                    : "পুষ্টিগুণ ও উপকারিতা:",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                benefits,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),

              // PREPARATION STEPS
              Text(
                _isEnglish
                    ? "Preparation & Recipe Steps:"
                    : "রান্নার সহজ ধাপসমূহ:",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xffF9FBE7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xffE6EE9C)),
                ),
                child: Text(
                  steps,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff4CAF50),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _isEnglish ? "Got it, Let's Prepare" : "বুঝেছি, তৈরি করি",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DEDICATED IN-APP FULL VIDEO SCREEN + DIRECT YOUTUBE ACTION
// ============================================================
class InAppVideoScreen extends StatefulWidget {
  final String videoId;
  final String mealTitle;

  const InAppVideoScreen({
    super.key,
    required this.videoId,
    required this.mealTitle,
  });

  @override
  State<InAppVideoScreen> createState() => _InAppVideoScreenState();
}

class _InAppVideoScreenState extends State<InAppVideoScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    final htmlContent =
        '''
      <!DOCTYPE html>
      <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
          <style>
            html, body {
              margin: 0;
              padding: 0;
              width: 100%;
              height: 100%;
              background-color: #000000;
              display: flex;
              justify-content: center;
              align-items: center;
              overflow: hidden;
            }
            .video-box {
              position: relative;
              width: 100%;
              height: 0;
              padding-bottom: 56.25%;
            }
            .video-box iframe {
              position: absolute;
              top: 0;
              left: 0;
              width: 100%;
              height: 100%;
              border: 0;
            }
          </style>
        </head>
        <body>
          <div class="video-box">
            <iframe 
              src="https://www.youtube.com/embed/${widget.videoId}?autoplay=1&playsinline=1&rel=0&modestbranding=1&enablejsapi=1" 
              allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" 
              allowfullscreen>
            </iframe>
          </div>
        </body>
      </html>
    ''';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36",
      )
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
        ),
      )
      ..loadHtmlString(htmlContent, baseUrl: 'https://www.youtube.com');
  }

  Future<void> _openExternalApp() async {
    final uri = Uri.parse("https://www.youtube.com/watch?v=${widget.videoId}");
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          widget.mealTitle,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 16:9 IN-APP VIDEO FRAME
            Container(
              color: Colors.black,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  children: [
                    WebViewWidget(controller: _controller),
                    if (_isLoading)
                      const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xff4CAF50),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // RECIPE INFO & FALLBACK ACTION CARD
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.mealTitle,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "The video is loading inside the app. If playback gets stuck due to network or device player restrictions, tap the button below to watch the recipe directly in the YouTube app.",
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                    const Spacer(),

                    // DIRECT "WATCH ON YOUTUBE" BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _openExternalApp,
                        icon: const Icon(
                          Icons.play_circle_filled_rounded,
                          size: 24,
                        ),
                        label: Text(
                          "Watch on YouTube App",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xffE53935,
                          ), // YouTube Red
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
