class DayModel {
  final int dayNumber;

  final String title;

  final bool completed;

  DayModel({
    required this.dayNumber,
    required this.title,
    required this.completed,
  });

  Map<String, dynamic> toJson() {
    return {"dayNumber": dayNumber, "title": title, "completed": completed};
  }

  factory DayModel.fromJson(Map<String, dynamic> json) {
    return DayModel(
      dayNumber: json["dayNumber"],
      title: json["title"],
      completed: json["completed"],
    );
  }
}
