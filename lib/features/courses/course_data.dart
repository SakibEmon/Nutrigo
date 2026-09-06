import 'course_model.dart';

final List<CourseModel> courses = [
  // ======================================================
  // COURSE 1: 14 Lessons (৬ ঘণ্টার নিয়মে প্রায় ৩.৫ থেকে ৭ দিন)
  // ======================================================
  CourseModel(
    id: "nutrition101",
    title: "Healthy Eating Basics",
    description: "Learn the fundamentals of balanced nutrition.",
    image: "assets/images/course1.png",
    colorTag: ColorTag.green,
    totalLessons: 14,
    completedLessons: 0,
    estimatedTime: const Duration(days: 7), // ৭ দিন

    lessons: [
      Lesson(
        title: "Introduction to Healthy Eating",
        completed: false,
        unlocked: true,
      ),
      Lesson(
        title: "Understanding a Balanced Diet",
        completed: false,
        unlocked: false,
      ),
      Lesson(title: "Food Groups", completed: false, unlocked: false),
      Lesson(title: "Carbohydrates", completed: false, unlocked: false),
      Lesson(title: "Protein", completed: false, unlocked: false),
      Lesson(title: "Healthy Fats", completed: false, unlocked: false),
      Lesson(title: "Vitamins and Minerals", completed: false, unlocked: false),
      Lesson(title: "Fiber and Digestion", completed: false, unlocked: false),
      Lesson(title: "Importance of Water", completed: false, unlocked: false),
      Lesson(title: "Healthy Breakfast", completed: false, unlocked: false),
      Lesson(title: "Healthy Lunch", completed: false, unlocked: false),
      Lesson(title: "Healthy Dinner", completed: false, unlocked: false),
      Lesson(title: "Healthy Snacks", completed: false, unlocked: false),
      Lesson(
        title: "Healthy Eating Challenge",
        completed: false,
        unlocked: false,
      ),
    ],
  ),

  // ======================================================
  // COURSE 2: 10 Lessons (প্রায় ৫ দিন)
  // ======================================================
  CourseModel(
    id: "protein",
    title: "Protein & Body Growth",
    description: "Understand why protein matters.",
    image: "assets/images/course2.png",
    colorTag: ColorTag.orange,
    totalLessons: 10,
    completedLessons: 0,
    estimatedTime: const Duration(days: 5), // ৫ দিন

    lessons: [
      Lesson(title: "What is Protein?", completed: false, unlocked: true),
      Lesson(
        title: "Why Our Body Needs Protein",
        completed: false,
        unlocked: false,
      ),
      Lesson(title: "Protein and Growth", completed: false, unlocked: false),
      Lesson(
        title: "Animal Sources of Protein",
        completed: false,
        unlocked: false,
      ),
      Lesson(
        title: "Plant Sources of Protein",
        completed: false,
        unlocked: false,
      ),
      Lesson(title: "Protein-Rich Meals", completed: false, unlocked: false),
      Lesson(
        title: "Protein for Adolescents",
        completed: false,
        unlocked: false,
      ),
      Lesson(
        title: "Healthy Protein Choices",
        completed: false,
        unlocked: false,
      ),
      Lesson(title: "Protein Myths", completed: false, unlocked: false),
      Lesson(title: "Protein Challenge", completed: false, unlocked: false),
    ],
  ),

  // ======================================================
  // COURSE 3: 12 Lessons (প্রায় ৬ দিন)
  // ======================================================
  CourseModel(
    id: "vitamins",
    title: "Vitamins & Minerals",
    description: "Essential nutrients for daily life.",
    image: "assets/images/course3.png",
    colorTag: ColorTag.blue,
    totalLessons: 12,
    completedLessons: 0,
    estimatedTime: const Duration(days: 6), // ৬ দিন

    lessons: [
      Lesson(
        title: "Introduction to Vitamins",
        completed: false,
        unlocked: true,
      ),
      Lesson(title: "Vitamin A", completed: false, unlocked: false),
      Lesson(title: "Vitamin B", completed: false, unlocked: false),
      Lesson(title: "Vitamin C", completed: false, unlocked: false),
      Lesson(title: "Vitamin D", completed: false, unlocked: false),
      Lesson(title: "Vitamin E", completed: false, unlocked: false),
      Lesson(title: "Iron", completed: false, unlocked: false),
      Lesson(title: "Calcium", completed: false, unlocked: false),
      Lesson(title: "Zinc", completed: false, unlocked: false),
      Lesson(title: "Mineral-Rich Foods", completed: false, unlocked: false),
      Lesson(title: "Healthy Food Choices", completed: false, unlocked: false),
      Lesson(
        title: "Vitamins & Minerals Challenge",
        completed: false,
        unlocked: false,
      ),
    ],
  ),

  // ======================================================
  // COURSE 4: 8 Lessons (প্রায় ৪ দিন)
  // ======================================================
  CourseModel(
    id: "meal",
    title: "Smart Meal Planning",
    description: "Build healthy meals every day.",
    image: "assets/images/course4.png",
    colorTag: ColorTag.purple,
    totalLessons: 8,
    completedLessons: 0,
    estimatedTime: const Duration(days: 4), // ৪ দিন

    lessons: [
      Lesson(title: "What is Meal Planning?", completed: false, unlocked: true),
      Lesson(
        title: "Building a Balanced Plate",
        completed: false,
        unlocked: false,
      ),
      Lesson(title: "Planning Breakfast", completed: false, unlocked: false),
      Lesson(title: "Planning Lunch", completed: false, unlocked: false),
      Lesson(title: "Planning Dinner", completed: false, unlocked: false),
      Lesson(title: "Healthy Snacks", completed: false, unlocked: false),
      Lesson(
        title: "Budget-Friendly Healthy Meals",
        completed: false,
        unlocked: false,
      ),
      Lesson(
        title: "Smart Meal Planning Challenge",
        completed: false,
        unlocked: false,
      ),
    ],
  ),
];
