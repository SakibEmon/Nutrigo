import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/theme_provider.dart';
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
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeProvider.themeModeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          navigatorKey: NotificationService.navigatorKey,
          title: "Nutrigo",
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,

          // Light Theme
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xffFFFDF8),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xff4CAF50),
              brightness: Brightness.light,
            ),
          ),

          // Dark Theme
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xff121212),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xff4CAF50),
              brightness: Brightness.dark,
            ),
          ),

          home: const SplashScreen(),
        );
      },
    );
  }
}
