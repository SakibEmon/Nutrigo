import 'package:flutter/material.dart';

class FloatingAiMenu extends StatelessWidget {
  final VoidCallback onTap;

  const FloatingAiMenu({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 82,
        height: 82,
        decoration: BoxDecoration(
          color: const Color(0xff4CAF50),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff4CAF50).withOpacity(.35),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, color: Colors.white, size: 30),
            SizedBox(height: 5),
            Text(
              "Nutrigo AI",
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
