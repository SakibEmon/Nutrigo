import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static void Function(String? payload)? onNotificationClick;

  // ============================================================
  // INITIALIZATION
  // ============================================================
  static Future<void> initialize() async {
    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload != null && onNotificationClick != null) {
            onNotificationClick!(response.payload);
          }
        },
      );

      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();

        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'nutrigo_instant_alerts_v2',
          'NutriGo Instant Alerts',
          description: 'Instant alerts, meal scans, and XP updates',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );

        await androidImplementation.createNotificationChannel(channel);
      }

      await scheduleDailyMealReminders();
      await scheduleInactivityReminder();
    } catch (e) {
      debugPrint("Notification init error: $e");
    }
  }

  // ============================================================
  // SHOW & SAVE NOTIFICATION
  // ============================================================
  static Future<void> showAndSaveNotification({
    required String title,
    required String body,
    String type = "xp",
    String? payload,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'nutrigo_instant_alerts_v2',
            'NutriGo Instant Alerts',
            channelDescription: 'Instant alerts, meal scans, and XP updates',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      final int notificationId = DateTime.now().millisecondsSinceEpoch
          .remainder(100000);

      await _notificationsPlugin.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .add({
              'title': title,
              'body': body,
              'type': type,
              'payload': payload ?? '',
              'timestamp': FieldValue.serverTimestamp(),
              'isRead': false,
            });
      }
    } catch (e) {
      debugPrint("Error showing notification: $e");
    }
  }

  // ============================================================
  // SCHEDULED REMINDERS (Updated Times)
  // ============================================================
  static Future<void> scheduleDailyMealReminders() async {
    // Breakfast window: 7:00 AM - 11:00 AM (Alert at 8:00 AM)
    await _scheduleMealAlert(
      id: 101,
      hour: 8,
      minute: 0,
      title: "Breakfast Time (7 AM - 11 AM) 🍳",
      body: "Start your day right! Scan your breakfast before 11:00 AM.",
    );

    // Lunch window: 12:00 PM - 3:00 PM (Alert at 12:30 PM)
    await _scheduleMealAlert(
      id: 102,
      hour: 12,
      minute: 30,
      title: "Lunch Window is Open (12 PM - 3 PM) 🥗",
      body: "Refuel your body! Scan and verify your lunch before 3:00 PM.",
    );

    // Dinner window: 8:00 PM - 10:00 PM (Alert at 8:15 PM)
    await _scheduleMealAlert(
      id: 103,
      hour: 20,
      minute: 15,
      title: "Dinner Window is Open (8 PM - 10 PM) 🍲",
      body:
          "Keep it light and healthy! Complete your dinner scan before 10:00 PM.",
    );
  }

  static Future<void> _scheduleMealAlert({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    try {
      final tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'nutrigo_meals',
            'Meal Reminders',
            channelDescription:
                'Reminders for daily breakfast, lunch, and dinner',
            importance: Importance.high,
            priority: Priority.high,
          );

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint("Error scheduling meal reminder ($id): $e");
    }
  }

  static Future<void> scheduleInactivityReminder() async {
    try {
      final tz.TZDateTime scheduledDate = tz.TZDateTime.now(
        tz.local,
      ).add(const Duration(hours: 24));

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'nutrigo_streak',
            'Inactivity Alert',
            channelDescription: 'Reminders to maintain daily streaks',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          );

      await _notificationsPlugin.zonedSchedule(
        201,
        "We Miss You on NutriGo! 🌱",
        "Consistency is the secret to good health! Log in to maintain your streak and finish today's tasks.",
        scheduledDate,
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint("Error scheduling inactivity reminder: $e");
    }
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
