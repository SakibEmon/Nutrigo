import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'course_data.dart';
import 'widgets/course_card.dart';

class CourseScreen extends StatelessWidget {
  const CourseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FBF8),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Nutrition Courses",
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(22),
        itemCount: courses.length,
        itemBuilder: (_, index) {
          return CourseCard(course: courses[index]);
        },
      ),
    );
  }
}
