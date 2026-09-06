import 'day_model.dart';

class WeekModel {
  final int weekNumber;
  final bool unlocked;
  final List<DayModel> days;

  WeekModel({
    required this.weekNumber,
    required this.unlocked,
    required this.days,
  });

  Map<String, dynamic> toJson() {
    return {
      "weekNumber": weekNumber,
      "unlocked": unlocked,
      "days": days.map((e) => e.toJson()).toList(),
    };
  }

  factory WeekModel.fromJson(Map<String, dynamic> json) {
    return WeekModel(
      weekNumber: json["weekNumber"],
      unlocked: json["unlocked"],
      days: (json["days"] as List).map((e) => DayModel.fromJson(e)).toList(),
    );
  }
}
