import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../courses/course_data.dart';
import '../../courses/course_screen.dart';
import '../../../services/course_service.dart';

class ContinueLearningCard extends StatefulWidget {
  const ContinueLearningCard({super.key});

  @override
  State<ContinueLearningCard> createState() => _ContinueLearningCardState();
}

class _ContinueLearningCardState extends State<ContinueLearningCard> {
  double _overallProgress = 0.0;
  int _completedLessons = 0;
  int _totalLessons = 0;
  String _activeTitle = "Healthy Eating Basics";
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _calculateProgress();
  }

  Future<void> _calculateProgress() async {
    int total = 0;
    int completed = 0;
    String currentCourse = "Healthy Eating Basics";

    for (final course in courses) {
      total += course.lessons.length;
      final lessons = await CourseService.loadCourse(
        courseId: course.id,
        defaultLessons: course.lessons,
      );

      final done = lessons.where((l) => l.completed).length;
      completed += done;

      if (done > 0 && done < lessons.length) {
        currentCourse = course.title;
      }
    }

    if (!mounted) return;

    setState(() {
      _totalLessons = total > 0 ? total : 44;
      _completedLessons = completed;
      _overallProgress = _totalLessons > 0
          ? (_completedLessons / _totalLessons)
          : 0.0;
      _activeTitle = currentCourse;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final int percentage = (_overallProgress * 100).toInt();

    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CourseScreen()),
        );
        // কোর্স স্ক্রিন থেকে ফিরে এলে প্রগ্রেস রিফ্রেশ হবে
        _calculateProgress();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xffE8F5E9),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: Color(0xff4CAF50),
                size: 34,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _completedLessons > 0
                        ? "Continue Learning"
                        : "Start Learning",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _activeTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: _overallProgress,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation(
                        Color(0xff4CAF50),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _loading
                        ? "Calculating..."
                        : "$percentage% Completed ($_completedLessons/$_totalLessons Lessons)",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xff4CAF50),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
