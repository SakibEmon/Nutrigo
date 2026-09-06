import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/courses/course_model.dart';

class CourseService {
  // ============================================================
  // CURRENT USER UID
  // ============================================================

  static String get _currentUserId {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("No user is currently logged in.");
    }

    return user.uid;
  }

  // ============================================================
  // KEYS
  // ============================================================

  static String _courseKey(String courseId) {
    return "nutrition_course_${_currentUserId}_$courseId";
  }

  static String _joinedKey(String courseId) {
    return "nutrition_joined_${_currentUserId}_$courseId";
  }

  static String _lastCompletedTimeKey(String courseId) {
    return "nutrition_last_completed_${_currentUserId}_$courseId";
  }

  // ============================================================
  // CLOUD FIRESTORE REAL-TIME MEMBER COUNT
  // ============================================================

  /// কোর্সের রিয়েল-টাইম মেম্বার স্ট্রিম
  static Stream<int> getCourseMembersStream(String courseId) {
    return FirebaseFirestore.instance
        .collection('course_stats')
        .doc(courseId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            final data = snapshot.data()!;
            if (data.containsKey('membersCount')) {
              return (data['membersCount'] as num).toInt();
            }
          }
          return 0;
        });
  }

  /// জয়েন করলে ক্লাউড Firestore এবং লোকাল স্টোরেজে সঠিকভাবে আপডেট করা
  static Future<void> joinCourse(String courseId) async {
    final prefs = await SharedPreferences.getInstance();

    // ১. লোকাল স্টোরেজে স্ট্যাটাস সেভ
    await prefs.setBool(_joinedKey(courseId), true);

    // ২. ক্লাউড Firestore-এ সরাসরি মেম্বার যুক্ত ও সংখ্যা বৃদ্ধি
    try {
      final docRef = FirebaseFirestore.instance
          .collection('course_stats')
          .doc(courseId);

      final docSnap = await docRef.get();

      if (!docSnap.exists) {
        await docRef.set({
          'membersCount': 1,
          'joinedUsers': [_currentUserId],
        });
      } else {
        final List<dynamic> joinedUsers = docSnap.data()?['joinedUsers'] ?? [];
        if (!joinedUsers.contains(_currentUserId)) {
          await docRef.update({
            'membersCount': FieldValue.increment(1),
            'joinedUsers': FieldValue.arrayUnion([_currentUserId]),
          });
        }
      }
    } catch (e) {
      // Offline fallback
    }
  }

  // ============================================================
  // LOCAL JOIN STATUS CHECK
  // ============================================================

  static Future<bool> isCourseJoined(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_joinedKey(courseId)) ?? false;
  }

  // ============================================================
  // 6 HOURS COOLDOWN CHECK
  // ============================================================

  static Future<int> getRemainingCooldownMinutes(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final lastTimeStr = prefs.getString(_lastCompletedTimeKey(courseId));

    if (lastTimeStr == null) return 0;

    final lastTime = DateTime.parse(lastTimeStr);
    final difference = DateTime.now().difference(lastTime);

    const cooldownMinutes = 6 * 60;

    if (difference.inMinutes < cooldownMinutes) {
      return cooldownMinutes - difference.inMinutes;
    }

    return 0;
  }

  // ============================================================
  // INITIALIZE COURSE
  // ============================================================

  static Future<List<Lesson>> initializeCourse({
    required String courseId,
    required List<Lesson> lessons,
  }) async {
    final List<Lesson> initialLessons = lessons
        .map(
          (lesson) =>
              Lesson(title: lesson.title, completed: false, unlocked: false),
        )
        .toList();

    if (initialLessons.isNotEmpty) {
      initialLessons[0].unlocked = true;
    }

    await saveCourse(courseId: courseId, lessons: initialLessons);
    return initialLessons;
  }

  // ============================================================
  // LOAD COURSE
  // ============================================================

  static Future<List<Lesson>> loadCourse({
    required String courseId,
    required List<Lesson> defaultLessons,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _courseKey(courseId);

    final data = prefs.getString(key);

    if (data == null) {
      return await initializeCourse(
        courseId: courseId,
        lessons: defaultLessons,
      );
    }

    final decoded = jsonDecode(data);

    final lessons = (decoded as List<dynamic>)
        .map((item) => Lesson.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();

    _syncUnlockStates(lessons);

    return lessons;
  }

  // ============================================================
  // SYNC UNLOCK STATES
  // ============================================================

  static void _syncUnlockStates(List<Lesson> lessons) {
    for (int i = 0; i < lessons.length; i++) {
      if (i == 0) {
        lessons[i].unlocked = true;
      } else {
        lessons[i].unlocked = lessons[i - 1].completed;
      }
    }
  }

  // ============================================================
  // SAVE COURSE
  // ============================================================

  static Future<void> saveCourse({
    required String courseId,
    required List<Lesson> lessons,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    _syncUnlockStates(lessons);

    final jsonString = jsonEncode(
      lessons.map((lesson) => lesson.toJson()).toList(),
    );

    await prefs.setString(_courseKey(courseId), jsonString);
  }

  // ============================================================
  // COMPLETE LESSON
  // ============================================================

  static Future<void> completeLesson({
    required String courseId,
    required List<Lesson> defaultLessons,
    required int lessonIndex,
  }) async {
    final lessons = await loadCourse(
      courseId: courseId,
      defaultLessons: defaultLessons,
    );

    if (lessonIndex < 0 || lessonIndex >= lessons.length) {
      throw Exception("Invalid lesson number.");
    }

    final lesson = lessons[lessonIndex];

    if (!lesson.unlocked) {
      throw Exception(
        "This lesson is locked. Complete the previous lesson first.",
      );
    }

    if (lesson.completed) {
      return;
    }

    lesson.completed = true;

    if (lessonIndex + 1 < lessons.length) {
      lessons[lessonIndex + 1].unlocked = true;
    }

    await saveCourse(courseId: courseId, lessons: lessons);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _lastCompletedTimeKey(courseId),
      DateTime.now().toIso8601String(),
    );
  }

  // ============================================================
  // COMPLETE LESSON BY DAY NUMBER
  // ============================================================

  static Future<void> completeDay({
    required String courseId,
    required List<Lesson> defaultLessons,
    required int dayNumber,
  }) async {
    await completeLesson(
      courseId: courseId,
      defaultLessons: defaultLessons,
      lessonIndex: dayNumber - 1,
    );
  }
}
