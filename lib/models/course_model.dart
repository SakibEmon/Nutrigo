class CourseModel {
  final String id;
  final String title;
  final String description;
  final String image;
  final ColorTag colorTag;
  final int totalLessons;
  final int completedLessons;
  final Duration estimatedTime;

  const CourseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.colorTag,
    required this.totalLessons,
    required this.completedLessons,
    required this.estimatedTime,
  });

  double get progress =>
      totalLessons == 0 ? 0 : completedLessons / totalLessons;
}

enum ColorTag { green, orange, blue, purple }

// ===============================
// Lesson Model
// ===============================

class Lesson {
  final String title;
  bool completed;

  Lesson({required this.title, required this.completed});

  Map<String, dynamic> toJson() {
    return {"title": title, "completed": completed};
  }

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      title: json["title"] ?? "",
      completed: json["completed"] ?? false,
    );
  }
}

// ===============================
// Week Model
// ===============================

class Week {
  final int weekNumber;
  bool unlocked;
  List<Lesson> lessons;

  Week({
    required this.weekNumber,
    required this.unlocked,
    required this.lessons,
  });

  Map<String, dynamic> toJson() {
    return {
      "weekNumber": weekNumber,
      "unlocked": unlocked,
      "lessons": lessons.map((e) => e.toJson()).toList(),
    };
  }

  factory Week.fromJson(Map<String, dynamic> json) {
    return Week(
      weekNumber: json["weekNumber"] ?? 1,
      unlocked: json["unlocked"] ?? false,
      lessons: (json["lessons"] as List? ?? [])
          .map((e) => Lesson.fromJson(e))
          .toList(),
    );
  }
}
