import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TaskRequirement extends StatelessWidget {
  const TaskRequirement({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Mission Requirements",
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 20),

        _item(
          icon: Icons.egg_alt_rounded,
          title: "Protein Source",
          subtitle: "Egg, fish, chicken, lentils or beans",
          color: const Color(0xff4CAF50),
        ),

        _item(
          icon: Icons.eco_rounded,
          title: "Fresh Vegetables",
          subtitle: "Include at least one vegetable",
          color: const Color(0xff43A047),
        ),

        _item(
          icon: Icons.apple_rounded,
          title: "Fresh Fruit",
          subtitle: "One seasonal fruit is required",
          color: const Color(0xffFF9800),
        ),
      ],
    );
  }

  Widget _item({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withOpacity(.15),
            child: Icon(icon, color: color),
          ),

          const SizedBox(width: 18),

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
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const Icon(Icons.check_circle_outline_rounded, color: Colors.green),
        ],
      ),
    );
  }
}
