import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/mission_service.dart';
import 'mission_card.dart';

class MissionSection extends StatefulWidget {
  const MissionSection({super.key});

  @override
  State<MissionSection> createState() => _MissionSectionState();
}

class _MissionSectionState extends State<MissionSection> {
  MissionModel? _todayMission;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final mission = await MissionService.getMission(
      MissionService.getTodayKey(),
    );
    if (mounted) {
      setState(() {
        _todayMission = mission;
        _loading = false;
      });
    }
  }

  void _openCalendarHistory() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xff4CAF50),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate == null || !mounted) return;

    final dateKey =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
    final history = await MissionService.getMission(dateKey);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Missions on $dateKey",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _historyItem("Breakfast (7 AM - 10 AM)", history.breakfast),
              const Divider(),
              _historyItem("Lunch (1 PM - 3 PM)", history.lunch),
              const Divider(),
              _historyItem("Dinner (8 PM - 10 PM)", history.dinner),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "Close",
                style: GoogleFonts.poppins(color: const Color(0xff4CAF50)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _historyItem(String title, bool isDone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          isDone
              ? const Icon(Icons.check_circle, color: Colors.green, size: 22)
              : const Icon(Icons.cancel, color: Colors.redAccent, size: 22),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xff4CAF50)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Today's Mission",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.calendar_month_rounded,
                color: Color(0xff4CAF50),
                size: 28,
              ),
              tooltip: "Check History",
              onPressed: _openCalendarHistory,
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 190,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // 1. BREAKFAST
              MissionCard(
                mealType: "Breakfast",
                targetMeal: "Oatmeal with Boiled Egg & Fruits",
                timeRange: "7:00 AM - 10:00 AM",
                recipe:
                    "1. Boil 1 cup of oats with milk/water.\n2. Add 1 boiled egg on the side.\n3. Top with sliced banana or apple.",
                icon: Icons.breakfast_dining,
                color: const Color(0xff66BB6A),
                isCompleted: _todayMission?.breakfast ?? false,
                onRefresh: _loadData,
              ),

              // 2. LUNCH
              MissionCard(
                mealType: "Lunch",
                targetMeal: "Brown Rice, Mixed Vegetables & Lentils",
                timeRange: "1:00 PM - 3:00 PM",
                recipe:
                    "1. Prepare 1 small bowl of steamed brown rice.\n2. Add cooked mixed vegetable curry.\n3. Take 1 thick cup of lentil (dal) soup.",
                icon: Icons.lunch_dining,
                color: const Color(0xff42A5F5),
                isCompleted: _todayMission?.lunch ?? false,
                onRefresh: _loadData,
              ),

              // 3. DINNER
              MissionCard(
                mealType: "Dinner",
                targetMeal: "Grilled Chicken Salad / Veg Soup",
                timeRange: "8:00 PM - 10:00 PM",
                recipe:
                    "1. Take 100g light-grilled chicken or paneer.\n2. Mix with cucumber, tomato, and lettuce.\n3. Dress with lemon juice and olive oil.",
                icon: Icons.dinner_dining,
                color: const Color(0xffAB47BC),
                isCompleted: _todayMission?.dinner ?? false,
                onRefresh: _loadData,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
