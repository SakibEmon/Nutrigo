import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/splash/splash_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // Initialize notifications & schedule meal/inactivity alerts
  await NotificationService.initialize();

  runApp(const ProviderScope(child: NutrigoApp()));
}

class NutrigoApp extends StatelessWidget {
  const NutrigoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NotificationService.navigatorKey,
      title: "Nutrigo",
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xffFFFDF8),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff4CAF50)),
      ),

      home: const SplashScreen(),
    );
  }
}
