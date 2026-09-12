// ======================================================
// COURSE MODEL
// ======================================================

class CourseModel {
  final String id;
  final String title;
  final String description;
  final String image;
  final ColorTag colorTag;
  final int totalLessons;
  final int completedLessons;
  final Duration estimatedTime;

  final List<Lesson> lessons;

  const CourseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.colorTag,
    required this.totalLessons,
    required this.completedLessons,
    required this.estimatedTime,
    required this.lessons,
  });

  double get progress {
    if (totalLessons == 0) return 0;
    return completedLessons / totalLessons;
  }
}

// ======================================================
// COLOR TAG
// ======================================================

enum ColorTag { green, orange, blue, purple }

// ======================================================
// LESSON MODEL
// ======================================================

class Lesson {
  final String title;
  bool completed;
  bool unlocked;
  final String readingContent;
  final String videoUrl;

  Lesson({
    required this.title,
    required this.completed,
    required this.unlocked,
    this.readingContent = "",
    this.videoUrl = "",
  });

  Map<String, dynamic> toJson() {
    return {
      "title": title,
      "completed": completed,
      "unlocked": unlocked,
      "readingContent": readingContent,
      "videoUrl": videoUrl,
    };
  }

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      title: json["title"] as String? ?? "",
      completed: json["completed"] as bool? ?? false,
      unlocked: json["unlocked"] as bool? ?? false,
      readingContent: json["readingContent"] as String? ?? "",
      videoUrl: json["videoUrl"] as String? ?? "",
    );
  }
}

// ======================================================
// WEEK MODEL
// ======================================================

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
      "lessons": lessons.map((lesson) => lesson.toJson()).toList(),
    };
  }

  factory Week.fromJson(Map<String, dynamic> json) {
    return Week(
      weekNumber: json["weekNumber"] as int? ?? 1,
      unlocked: json["unlocked"] as bool? ?? false,
      lessons: (json["lessons"] as List<dynamic>? ?? [])
          .map(
            (lesson) =>
                Lesson.fromJson(Map<String, dynamic>.from(lesson as Map)),
          )
          .toList(),
    );
  }
}
