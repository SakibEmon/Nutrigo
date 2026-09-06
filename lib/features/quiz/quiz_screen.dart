import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'quiz_model.dart';

class QuizScreen extends StatefulWidget {
  final int weekNumber;
  final int dayNumber;

  const QuizScreen({
    super.key,
    required this.weekNumber,
    required this.dayNumber,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentQuestion = 0;
  int? selectedAnswer;
  int score = 0;

  bool answered = false;

  final List<QuizQuestion> questions = const [
    QuizQuestion(
      question: "Which food group is a good source of protein?",
      options: ["Eggs", "Soft drinks", "Candy", "Sugar"],
      correctAnswer: 0,
    ),

    QuizQuestion(
      question: "Which is a healthy drink choice?",
      options: ["Water", "Energy drink", "Soft drink", "Sugary juice"],
      correctAnswer: 0,
    ),

    QuizQuestion(
      question: "Which food is generally rich in fiber?",
      options: ["Vegetables", "Candy", "Soda", "Ice cream"],
      correctAnswer: 0,
    ),

    QuizQuestion(
      question: "Why is a balanced diet important?",
      options: [
        "It provides different nutrients",
        "It only provides sugar",
        "It replaces the need for water",
        "It means eating only one food",
      ],
      correctAnswer: 0,
    ),
  ];

  void selectAnswer(int index) {
    if (answered) return;

    setState(() {
      selectedAnswer = index;
      answered = true;

      if (index == questions[currentQuestion].correctAnswer) {
        score++;
      }
    });
  }

  void nextQuestion() {
    if (!answered) return;

    if (currentQuestion < questions.length - 1) {
      setState(() {
        currentQuestion++;
        selectedAnswer = null;
        answered = false;
      });
    } else {
      _showResult();
    }
  }

  void _showResult() {
    final percentage = (score / questions.length) * 100;
    final passed = percentage >= 70;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Column(
            children: [
              Icon(
                passed ? Icons.celebration_rounded : Icons.refresh_rounded,
                size: 60,
                color: passed ? const Color(0xff4CAF50) : Colors.orange,
              ),
              const SizedBox(height: 12),
              Text(
                passed ? "Quiz Passed! 🎉" : "Try Again",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            "Your score: $score/${questions.length}\n"
            "${percentage.toInt()}%",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 16, height: 1.6),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            if (!passed)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);

                  setState(() {
                    currentQuestion = 0;
                    selectedAnswer = null;
                    score = 0;
                    answered = false;
                  });
                },
                child: Text(
                  "Try Again",
                  style: GoogleFonts.poppins(
                    color: const Color(0xff4CAF50),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            if (passed)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff4CAF50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  "Continue",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
          ],
        );
      },
    );
  }

  Color optionColor(int index) {
    if (!answered) {
      return Colors.white;
    }

    final correct = questions[currentQuestion].correctAnswer;

    if (index == correct) {
      return Colors.green.shade50;
    }

    if (index == selectedAnswer) {
      return Colors.red.shade50;
    }

    return Colors.grey.shade100;
  }

  Color optionBorderColor(int index) {
    if (!answered) {
      return Colors.grey.shade200;
    }

    final correct = questions[currentQuestion].correctAnswer;

    if (index == correct) {
      return Colors.green;
    }

    if (index == selectedAnswer) {
      return Colors.red;
    }

    return Colors.grey.shade200;
  }

  @override
  Widget build(BuildContext context) {
    final question = questions[currentQuestion];

    final progress = (currentQuestion + 1) / questions.length;

    return Scaffold(
      backgroundColor: const Color(0xffF8FBF8),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        title: Text(
          "Nutrition Quiz",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // =====================================================
            // Quiz Header
            // =====================================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [
                Text(
                  "Question ${currentQuestion + 1}",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  "${questions.length} Questions",
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // =====================================================
            // Progress
            // =====================================================
            ClipRRect(
              borderRadius: BorderRadius.circular(20),

              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                color: const Color(0xff4CAF50),
                backgroundColor: Colors.grey.shade300,
              ),
            ),

            const SizedBox(height: 35),

            // =====================================================
            // Question Card
            // =====================================================
            Container(
              width: double.infinity,

              padding: const EdgeInsets.all(24),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.04),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Icon(
                    Icons.help_outline_rounded,
                    color: Color(0xff4CAF50),
                    size: 32,
                  ),

                  const SizedBox(height: 18),

                  Text(
                    question.question,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // =====================================================
            // Options
            // =====================================================
            ...question.options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;

              return GestureDetector(
                onTap: () => selectAnswer(index),

                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),

                  margin: const EdgeInsets.only(bottom: 14),

                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),

                  decoration: BoxDecoration(
                    color: optionColor(index),
                    borderRadius: BorderRadius.circular(18),

                    border: Border.all(
                      color: optionBorderColor(index),
                      width: 1.5,
                    ),
                  ),

                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,

                        alignment: Alignment.center,

                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: answered
                              ? optionBorderColor(index).withOpacity(.1)
                              : const Color(0xffE8F5E9),
                        ),

                        child: Text(
                          String.fromCharCode(65 + index),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: answered
                                ? optionBorderColor(index)
                                : const Color(0xff4CAF50),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: Text(
                          option,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      if (answered && index == question.correctAnswer)
                        const Icon(Icons.check_circle, color: Colors.green),

                      if (answered &&
                          index == selectedAnswer &&
                          index != question.correctAnswer)
                        const Icon(Icons.cancel, color: Colors.red),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            // =====================================================
            // Feedback
            // =====================================================
            if (answered)
              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: selectedAnswer == question.correctAnswer
                      ? Colors.green.shade50
                      : Colors.orange.shade50,

                  borderRadius: BorderRadius.circular(18),
                ),

                child: Row(
                  children: [
                    Icon(
                      selectedAnswer == question.correctAnswer
                          ? Icons.check_circle
                          : Icons.info_outline,

                      color: selectedAnswer == question.correctAnswer
                          ? Colors.green
                          : Colors.orange,
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        selectedAnswer == question.correctAnswer
                            ? "Correct answer! Great job. 🎉"
                            : "Not quite. The correct answer is highlighted.",
                        style: GoogleFonts.poppins(fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 25),

            // =====================================================
            // Next Button
            // =====================================================
            SizedBox(
              width: double.infinity,
              height: 56,

              child: ElevatedButton(
                onPressed: answered ? nextQuestion : null,

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff4CAF50),

                  disabledBackgroundColor: Colors.grey.shade300,

                  foregroundColor: Colors.white,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),

                child: Text(
                  currentQuestion == questions.length - 1
                      ? "Finish Quiz"
                      : "Next Question",

                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
