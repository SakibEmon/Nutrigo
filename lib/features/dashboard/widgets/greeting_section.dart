import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GreetingSection extends StatelessWidget {
  const GreetingSection({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return "Good Morning ☀️";
    } else if (hour < 17) {
      return "Good Afternoon 🌤️";
    } else {
      return "Good Evening 🌙";
    }
  }

  /// ইউজারের নাম বের করার ফাংশন
  String _getUserName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
        return user.displayName!;
      } else if (user.email != null && user.email!.isNotEmpty) {
        // ইমেইলের @ এর আগের অংশ নাম হিসেবে নেবে
        final nameFromEmail = user.email!.split('@').first;
        return nameFromEmail[0].toUpperCase() + nameFromEmail.substring(1);
      }
    }
    return "User";
  }

  @override
  Widget build(BuildContext context) {
    final userName = _getUserName();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getGreeting(),
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade600),
        ),

        const SizedBox(height: 8),

        Text(
          "$userName 👋",
          style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700),
        ),

        const SizedBox(height: 8),

        Text(
          "Let's make today healthier.",
          style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
