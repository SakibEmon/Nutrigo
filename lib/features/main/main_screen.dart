import 'package:flutter/material.dart';

import '../dashboard/dashboard_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xffF8FBF8),
      body: DashboardScreen(),
    );
  }
}
