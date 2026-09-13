import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/meal_history.dart';
import '../../services/meal_history_service.dart';

class MonthlyReportData {
  final String userName;
  final String email;
  final int age;
  final String gender;
  final double weight;
  final double heightFeet;
  final double heightInch;
  final double bmi;
  final String bmiStatus;
  final int breakfastCount;
  final int dinnerCount;
  final int tasksCompletedCount;
  final int healthScore;
  final List<String> scannedFoods;
  final int courseCompleted;
  final List<List<String>> daywiseLogs;
  final int year;
  final int month;

  MonthlyReportData({
    required this.userName,
    required this.email,
    required this.age,
    required this.gender,
    required this.weight,
    required this.heightFeet,
    required this.heightInch,
    required this.bmi,
    required this.bmiStatus,
    required this.breakfastCount,
    required this.dinnerCount,
    required this.tasksCompletedCount,
    required this.healthScore,
    required this.scannedFoods,
    required this.courseCompleted,
    required this.daywiseLogs,
    required this.year,
    required this.month,
  });
}

class HealthReportService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<MonthlyReportData> fetchMonthlyData({
    required int year,
    required int month,
  }) async {
    final user = _auth.currentUser;
    final prefs = await SharedPreferences.getInstance();

    String name = "Nutrigo Member";
    String email = user?.email ?? "N/A";
    int age = 0;
    String gender = "Not Specified";
    double weight = 0.0;
    double heightFeet = 0.0;
    double heightInch = 0.0;
    int healthScore = 0;

    // ১. ইউজার প্রোফাইল ও আসল নিউট্রিশন স্কোর লোড
    if (user != null) {
      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data()!;
          name = (data['name'] ?? user.displayName ?? "Nutrigo Member")
              .toString();
          email = (data['email'] ?? user.email ?? "N/A").toString();
          age = int.tryParse(data['age']?.toString() ?? '0') ?? 0;
          gender = (data['gender'] ?? "Not Specified").toString();
          weight = double.tryParse(data['weightKg']?.toString() ?? '0') ?? 0.0;
          heightFeet =
              double.tryParse(data['heightFeet']?.toString() ?? '0') ?? 0.0;
          heightInch =
              double.tryParse(data['heightInch']?.toString() ?? '0') ?? 0.0;

          final rawPoints = data['nutrition_points'] ?? 0;
          healthScore = (rawPoints is num)
              ? rawPoints.toInt().clamp(0, 100)
              : 0;
        }
      } catch (_) {}
    }

    // BMI হিসাব
    final double totalInches = (heightFeet * 12) + heightInch;
    double bmi = 0.0;
    String bmiStatus = "N/A";
    if (totalInches > 0 && weight > 0) {
      final meters = totalInches * 0.0254;
      bmi = weight / (meters * meters);
      if (bmi < 18.5) {
        bmiStatus = "Underweight";
      } else if (bmi < 24.9) {
        bmiStatus = "Normal Weight";
      } else if (bmi < 29.9) {
        bmiStatus = "Overweight";
      } else {
        bmiStatus = "Obese";
      }
    }

    // ২. MealHistoryService থেকে স্ক্যান করা খাবারের তালিকা ও মিল ট্র্যাকিং লোড
    final List<MealHistory> allMeals = await MealHistoryService.loadMeals();
    final List<String> scannedFoods = [];

    final int daysInMonth = DateTime(year, month + 1, 0).day;
    final Map<int, Map<String, bool>> monthActivities = {};
    for (int day = 1; day <= daysInMonth; day++) {
      monthActivities[day] = {
        'breakfast': false,
        'dinner': false,
        'task': false,
      };
    }

    int breakfastCount = 0;
    int dinnerCount = 0;
    int tasksCompletedCount = 0;

    for (final meal in allMeals) {
      final dt = meal.scannedAt; // আপনার মডেলের আসল ডেট ফিল্ড
      if (dt.year == year && dt.month == month) {
        final day = dt.day;

        // আসল মিলের নাম যুক্ত করা
        final foodName = meal.mealName.trim();
        if (foodName.isNotEmpty && !scannedFoods.contains(foodName)) {
          scannedFoods.add(foodName);
        }

        // সময়ের ভিত্তিতে ব্রেকফাস্ট ও ডিনার ট্র্যাকিং
        final isBreakfastTime = dt.hour >= 5 && dt.hour <= 11;
        final isDinnerTime = dt.hour >= 18 && dt.hour <= 23;

        final mealNameLower = foodName.toLowerCase();
        final isBreakfast =
            isBreakfastTime || mealNameLower.contains("breakfast");
        final isDinner = isDinnerTime || mealNameLower.contains("dinner");

        if (monthActivities.containsKey(day)) {
          if (isBreakfast && !monthActivities[day]!['breakfast']!) {
            monthActivities[day]!['breakfast'] = true;
            breakfastCount++;
          }
          if (isDinner && !monthActivities[day]!['dinner']!) {
            monthActivities[day]!['dinner'] = true;
            dinnerCount++;
          }
          // খাবার স্ক্যান হলে ওই দিনের টাস্ক সম্পন্ন
          if (!monthActivities[day]!['task']!) {
            monthActivities[day]!['task'] = true;
            tasksCompletedCount++;
          }
        }
      }
    }

    // ৩. SharedPreferences থেকে কোর্সের অগ্রগতি লোড
    int courseCompleted = 0;
    if (user != null) {
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith("nutrition_course_${user.uid}_")) {
          final rawCourseData = prefs.getString(key);
          if (rawCourseData != null) {
            try {
              final List decoded = jsonDecode(rawCourseData);
              for (final lesson in decoded) {
                if (lesson is Map && lesson['completed'] == true) {
                  courseCompleted++;
                }
              }
            } catch (_) {}
          }
        }
      }
    }

    final monthNames = [
      "",
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    final String currentMonthShort = monthNames[month];

    final List<List<String>> daywiseLogs = [];
    for (int day = 1; day <= daysInMonth; day++) {
      final record = monthActivities[day]!;
      final dateStr = "$day $currentMonthShort";
      final weekdayName = _getWeekdayShort(DateTime(year, month, day).weekday);

      daywiseLogs.add([
        dateStr,
        weekdayName,
        record['breakfast']! ? "Done" : "Missed",
        record['dinner']! ? "Done" : "Missed",
        record['task']! ? "Done" : "Pending",
      ]);
    }

    return MonthlyReportData(
      userName: name,
      email: email,
      age: age,
      gender: gender,
      weight: weight,
      heightFeet: heightFeet,
      heightInch: heightInch,
      bmi: bmi,
      bmiStatus: bmiStatus,
      breakfastCount: breakfastCount,
      dinnerCount: dinnerCount,
      tasksCompletedCount: tasksCompletedCount,
      healthScore: healthScore,
      scannedFoods: scannedFoods,
      courseCompleted: courseCompleted,
      daywiseLogs: daywiseLogs,
      year: year,
      month: month,
    );
  }

  static Future<Uint8List> generateMonthlyPdf({
    required int year,
    required int month,
  }) async {
    final data = await fetchMonthlyData(year: year, month: month);
    final pdf = pw.Document();

    final monthNames = [
      "",
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    final String currentMonthName = monthNames[data.month];

    // ==========================================
    // PAGE 1: OVERVIEW, BIOMETRICS & HABITS
    // ==========================================
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "NUTRIGO HEALTH REPORT",
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex("#2E7D32"),
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        "Monthly Performance & Habit Overview",
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex("#E8F5E9"),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text(
                      "$currentMonthName ${data.year}",
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex("#2E7D32"),
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 12),

              pw.Text(
                "User Biometrics & Health Condition",
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          "Name: ${data.userName}",
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          "Email: ${data.email}",
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          "Demographics: ${data.age} Yrs | ${data.gender}",
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          "Height: ${data.heightFeet.toInt()}ft ${data.heightInch.toInt()}in",
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          "Weight: ${data.weight.toStringAsFixed(1)} kg",
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          "BMI: ${data.bmi > 0 ? data.bmi.toStringAsFixed(1) : '--'} (${data.bmiStatus})",
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex("#2E7D32"),
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex("#F1F8E9"),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            "Score",
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                          pw.Text(
                            "${data.healthScore}/100",
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex("#2E7D32"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              pw.Text(
                "Monthly Activity Summary",
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                children: [
                  _statBox("Breakfast Logged", "${data.breakfastCount} Days"),
                  pw.SizedBox(width: 8),
                  _statBox("Dinner Logged", "${data.dinnerCount} Days"),
                  pw.SizedBox(width: 8),
                  _statBox(
                    "Daily Tasks Done",
                    "${data.tasksCompletedCount} Days",
                  ),
                  pw.SizedBox(width: 8),
                  _statBox(
                    "Foods Scanned",
                    "${data.scannedFoods.length} Items",
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            "Scanned Foods (${data.scannedFoods.length})",
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            data.scannedFoods.isEmpty
                                ? "No foods scanned this month."
                                : data.scannedFoods.take(6).join(", "),
                            style: const pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            "Nutrition Course Progress",
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            "Completed Lessons: ${data.courseCompleted}",
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            "Track: Nutrition 101 Basics",
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.Spacer(),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "NutriGo Health Companion",
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    "Page 1 of 2 (Turn over for Daily Activity Logs)",
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // ==========================================
    // PAGE 2: DAY-BY-DAY COMPLETE TABLE
    // ==========================================
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "Daily Activity Logs ($currentMonthName ${data.year})",
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex("#2E7D32"),
                    ),
                  ),
                  pw.Text(
                    "Page 2 of 2",
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),

              pw.TableHelper.fromTextArray(
                headers: ["Date", "Day", "Breakfast", "Dinner", "Daily Task"],
                data: data.daywiseLogs,
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                ),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColor.fromHex("#E8F5E9"),
                ),
                cellStyle: const pw.TextStyle(fontSize: 7.5),
                cellAlignment: pw.Alignment.center,
                cellPadding: const pw.EdgeInsets.symmetric(
                  vertical: 2.2,
                  horizontal: 4,
                ),
              ),
              pw.Spacer(),

              pw.Center(
                child: pw.Text(
                  "Keep logging daily on Nutrigo to build healthy habits!",
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }

  static pw.Widget _statBox(String title, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: const pw.TextStyle(
                fontSize: 7.5,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex("#2E7D32"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _getWeekdayShort(int weekday) {
    switch (weekday) {
      case 1:
        return "Mon";
      case 2:
        return "Tue";
      case 3:
        return "Wed";
      case 4:
        return "Thu";
      case 5:
        return "Fri";
      case 6:
        return "Sat";
      case 7:
        return "Sun";
      default:
        return "";
    }
  }
}
