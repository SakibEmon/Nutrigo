import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../main/main_screen.dart';
import '../onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Wait 3 seconds, then check Firebase login status
    _timer = Timer(const Duration(seconds: 3), _checkUser);
  }

  // ============================================================
  // CHECK FIREBASE LOGIN STATUS
  // ============================================================

  void _checkUser() {
    if (!mounted) return;

    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // ========================================================
      // USER IS ALREADY LOGGED IN
      // ========================================================

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      // ========================================================
      // USER IS NOT LOGGED IN
      // ========================================================

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  void dispose() {
    // Cancel timer if the screen is removed before 3 seconds
    _timer?.cancel();
    super.dispose();
  }

  // ============================================================
  // SPLASH UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4CAF50),

      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Icon(Icons.restaurant_menu, color: Colors.white, size: 80),

            SizedBox(height: 20),

            // App Name
            Text(
              "NUTRIGO",
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),

            SizedBox(height: 10),

            // Subtitle
            Text(
              "Adaptive Nutrition Learning",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
