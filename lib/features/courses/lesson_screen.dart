import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tasks/daily_task_screen.dart';
import 'course_model.dart';

class LessonScreen extends StatelessWidget {
  final String lessonTitle;
  final int weekNumber;
  final int dayNumber;

  // Course information
  final String courseId;
  final List<Lesson> defaultLessons;

  const LessonScreen({
    super.key,
    required this.lessonTitle,
    required this.weekNumber,
    required this.dayNumber,
    required this.courseId,
    required this.defaultLessons,
  });

  // ============================================================
  // OPEN DAILY TASK
  // ============================================================

  Future<void> _openDailyTask(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DailyTaskScreen(
          weekNumber: weekNumber,
          dayNumber: dayNumber,

          // IMPORTANT:
          // Pass course information to DailyTaskScreen.
          courseId: courseId,
          defaultLessons: defaultLessons,
        ),
      ),
    );

    // ==========================================================
    // DAILY TASK COMPLETED
    // ==========================================================

    if (result == true) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Lesson completed successfully!'),
          backgroundColor: Color(0xff4CAF50),
        ),
      );

      // Return to CourseDetailsScreen.
      Navigator.pop(context, true);
    }
  }

  // ============================================================
  // READ LESSON
  // ============================================================

  void _showLessonInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  lessonTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Week $weekNumber • Day $dayNumber",
                  style: GoogleFonts.poppins(
                    color: const Color(0xff4CAF50),
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  "This lesson is part of your adaptive nutrition "
                  "learning journey. Complete the learning activity "
                  "and then continue to today's practical nutrition task.",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.7,
                  ),
                ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff4CAF50),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      "Got it",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FBF8),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: Text(
          "Lesson",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // WEEK / DAY
            // ==================================================
            Row(
              children: [
                _smallTag(
                  icon: Icons.calendar_today_rounded,
                  text: "Week $weekNumber",
                ),
                const SizedBox(width: 10),
                _smallTag(icon: Icons.today_rounded, text: "Day $dayNumber"),
              ],
            ),

            const SizedBox(height: 20),

            // ==================================================
            // HERO
            // ==================================================
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xff4CAF50), Color(0xff81C784)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff4CAF50).withOpacity(.20),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -25,
                    top: -25,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(.10),
                      ),
                    ),
                  ),

                  Positioned(
                    left: -35,
                    bottom: -45,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(.08),
                      ),
                    ),
                  ),

                  const Center(
                    child: Icon(
                      Icons.restaurant_menu_rounded,
                      color: Colors.white,
                      size: 85,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ==================================================
            // TITLE
            // ==================================================
            Text(
              lessonTitle,
              style: GoogleFonts.poppins(
                fontSize: 27,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "Learn something useful today and put it "
              "into practice with your daily nutrition task.",
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.grey.shade700,
                height: 1.7,
              ),
            ),

            const SizedBox(height: 28),

            // ==================================================
            // LESSON PROGRESS
            // ==================================================
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xffE8F5E9),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Color(0xff4CAF50),
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Learning",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          "Learn → Practice → Complete",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons.check_circle_outline,
                    color: Color(0xff4CAF50),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ==================================================
            // LEARNING CONTENT
            // ==================================================
            Text(
              "Today's Learning",
              style: GoogleFonts.poppins(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // READ
            _lessonSection(
              context: context,
              icon: Icons.menu_book_rounded,
              title: "Read Lesson",
              subtitle: "Learn the nutrition concept for today.",
              onTap: () {
                _showLessonInfo(context);
              },
            ),

            // VIDEO
            _lessonSection(
              context: context,
              icon: Icons.play_circle_fill_rounded,
              title: "Watch Video",
              subtitle: "Understand today's topic visually.",
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Video content will be added here.",
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: const Color(0xff4CAF50),
                  ),
                );
              },
            ),

            // DAILY ACTIVITY
            _lessonSection(
              context: context,
              icon: Icons.assignment_rounded,
              title: "Daily Activity",
              subtitle: "Apply what you learned today.",
              onTap: () {
                _openDailyTask(context);
              },
            ),

            const SizedBox(height: 30),

            // ==================================================
            // TASK PREVIEW
            // ==================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xffE8F5E9),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.restaurant_rounded,
                      color: Color(0xff4CAF50),
                    ),
                  ),

                  const SizedBox(width: 15),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Practical Task",
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          "After learning today's topic, complete "
                          "your nutrition activity to continue your journey.",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 35),

            // ==================================================
            // CONTINUE
            // ==================================================
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton.icon(
                onPressed: () {
                  _openDailyTask(context);
                },
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                ),
                label: Text(
                  "Continue to Daily Task",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff4CAF50),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Center(
              child: Text(
                "Complete today's task to continue learning.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SMALL TAG
  // ============================================================

  Widget _smallTag({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xffE8F5E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xff4CAF50)),

          const SizedBox(width: 6),

          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xff388E3C),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LESSON SECTION CARD
  // ============================================================

  Widget _lessonSection({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xffE8F5E9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: const Color(0xff4CAF50), size: 25),
                ),

                const SizedBox(width: 15),

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
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
