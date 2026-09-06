import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/course_service.dart';
import 'course_model.dart';
import 'lesson_screen.dart';

class CourseDetailsScreen extends StatefulWidget {
  final CourseModel course;

  const CourseDetailsScreen({super.key, required this.course});

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  List<Lesson> lessons = [];
  bool isJoined = false;
  int remainingCooldownMinutes = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadCourseData();
  }

  // ============================================================
  // LOAD COURSE & STATUS
  // ============================================================

  Future<void> _loadCourseData() async {
    final joined = await CourseService.isCourseJoined(widget.course.id);
    final cooldown = await CourseService.getRemainingCooldownMinutes(
      widget.course.id,
    );
    final data = await CourseService.loadCourse(
      courseId: widget.course.id,
      defaultLessons: widget.course.lessons,
    );

    if (!mounted) return;

    setState(() {
      isJoined = joined;
      remainingCooldownMinutes = cooldown;
      lessons = data;
      loading = false;
    });
  }

  // ============================================================
  // JOIN COURSE ACTION
  // ============================================================

  Future<void> _joinCourse() async {
    await CourseService.joinCourse(widget.course.id);
    await _loadCourseData();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "🎉 Enrolled in ${widget.course.title} successfully!",
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: const Color(0xff4CAF50),
      ),
    );
  }

  // ============================================================
  // COURSE COLOR
  // ============================================================

  Color get courseColor {
    switch (widget.course.colorTag) {
      case ColorTag.green:
        return const Color(0xff4CAF50);
      case ColorTag.orange:
        return const Color(0xffFF9800);
      case ColorTag.blue:
        return const Color(0xff2196F3);
      case ColorTag.purple:
        return const Color(0xff9C27B0);
    }
  }

  // ============================================================
  // PROGRESS
  // ============================================================

  double get progress {
    if (lessons.isEmpty) return 0;
    final completed = lessons.where((lesson) => lesson.completed).length;
    return completed / lessons.length;
  }

  int get completedCount {
    return lessons.where((lesson) => lesson.completed).length;
  }

  int? get nextLessonIndex {
    for (int i = 0; i < lessons.length; i++) {
      if (!lessons[i].completed && lessons[i].unlocked) {
        return i;
      }
    }
    return null;
  }

  // ============================================================
  // OPEN LESSON
  // ============================================================

  Future<void> _openLesson(int index) async {
    if (!isJoined) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please Join / Enroll in this course first!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final lesson = lessons[index];

    if (!lesson.unlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Complete previous lessons to unlock this one."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!lesson.completed && remainingCooldownMinutes > 0) {
      final hours = remainingCooldownMinutes ~/ 60;
      final minutes = remainingCooldownMinutes % 60;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Cooldown Active ⏳",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "You can complete only 1 lesson every 6 hours per course.\n\nPlease wait ${hours}h ${minutes}m to access the next lesson.",
            style: GoogleFonts.poppins(),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: courseColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Got It"),
            ),
          ],
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonScreen(
          lessonTitle: lesson.title,
          weekNumber: 1,
          dayNumber: index + 1,
          courseId: widget.course.id,
          defaultLessons: widget.course.lessons,
        ),
      ),
    );

    await _loadCourseData();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final nextIndex = nextLessonIndex;

    return Scaffold(
      backgroundColor: const Color(0xffF8FBF8),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: courseColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: widget.course.id,
                child: Image.asset(widget.course.image, fit: BoxFit.cover),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.course.title,
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      StreamBuilder<int>(
                        stream: CourseService.getCourseMembersStream(
                          widget.course.id,
                        ),
                        builder: (context, snapshot) {
                          final count = snapshot.data ?? 0;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: courseColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.people_alt_rounded,
                                  size: 16,
                                  color: courseColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "$count Enrolled",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    color: courseColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.course.description,
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ==================================================
                  // JOIN COURSE BUTTON
                  // ==================================================
                  if (!isJoined) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: courseColor.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: courseColor.withOpacity(0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Join this course to unlock all lessons!",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: courseColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _joinCourse,
                              icon: const Icon(Icons.add_circle_outline),
                              label: Text(
                                "Join Course Now",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ==================================================
                  // COOLDOWN NOTICE
                  // ==================================================
                  if (isJoined && remainingCooldownMinutes > 0) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Next lesson unlocks in ${remainingCooldownMinutes ~/ 60}h ${remainingCooldownMinutes % 60}m (1 lesson / 6h)",
                              style: GoogleFonts.poppins(
                                color: Colors.orange.shade900,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ==================================================
                  // PROGRESS
                  // ==================================================
                  Text(
                    "Course Progress",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      color: courseColor,
                      backgroundColor: Colors.grey.shade300,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$completedCount of ${lessons.length} lessons completed",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 25),

                  // ==================================================
                  // LESSON LIST
                  // ==================================================
                  Text(
                    "Course Content",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...lessons.asMap().entries.map((entry) {
                    return _buildLessonTile(
                      index: entry.key,
                      lesson: entry.value,
                    );
                  }),
                  const SizedBox(height: 25),

                  // ==================================================
                  // CONTINUE BUTTON
                  // ==================================================
                  if (isJoined)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: nextIndex == null
                            ? null
                            : () => _openLesson(nextIndex),
                        icon: Icon(
                          nextIndex == null
                              ? Icons.check_circle
                              : Icons.play_arrow,
                        ),
                        label: Text(
                          nextIndex == null
                              ? "Course Completed"
                              : "Continue Learning",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: courseColor,
                          disabledBackgroundColor: Colors.grey.shade400,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LESSON TILE
  // ============================================================

  Widget _buildLessonTile({required int index, required Lesson lesson}) {
    final dayNumber = index + 1;
    final isLocked = !isJoined || !lesson.unlocked;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: lesson.completed
            ? Colors.green.shade50
            : (!isLocked ? Colors.white : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: lesson.completed
              ? Colors.green.shade200
              : (!isLocked ? Colors.grey.shade200 : Colors.grey.shade300),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: lesson.completed
                ? Colors.green.shade100
                : (!isLocked
                      ? courseColor.withOpacity(.1)
                      : Colors.grey.shade200),
            shape: BoxShape.circle,
          ),
          child: Icon(
            lesson.completed
                ? Icons.check_circle
                : (!isLocked ? Icons.play_arrow : Icons.lock),
            color: lesson.completed
                ? Colors.green
                : (!isLocked ? courseColor : Colors.grey),
          ),
        ),
        title: Text(
          "Lesson $dayNumber",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: !isLocked ? Colors.black87 : Colors.grey,
          ),
        ),
        subtitle: Text(
          lesson.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: lesson.completed ? Colors.green : Colors.grey.shade600,
          ),
        ),
        trailing: Icon(
          lesson.completed
              ? Icons.check
              : (!isLocked ? Icons.arrow_forward_ios : Icons.lock),
          size: 17,
          color: lesson.completed
              ? Colors.green
              : (!isLocked ? courseColor : Colors.grey),
        ),
        onTap: () => _openLesson(index),
      ),
    );
  }
}
