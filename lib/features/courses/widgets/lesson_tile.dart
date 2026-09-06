import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LessonTile extends StatelessWidget {
  final String title;
  final bool unlocked;
  final VoidCallback? onTap;

  const LessonTile({
    super.key,
    required this.title,
    required this.unlocked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: unlocked ? onTap : null,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: unlocked
                  ? const Color(0xff4CAF50)
                  : Colors.grey.shade300,
              child: Icon(
                unlocked ? Icons.play_arrow_rounded : Icons.lock_outline,
                color: Colors.white,
              ),
            ),

            const SizedBox(width: 18),

            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: unlocked ? Colors.black54 : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
