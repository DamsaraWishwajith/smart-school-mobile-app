class MealPlanModel {
  final int id;
  final String day;
  final String? meal;
  final String? notes;
  final DateTime? updatedAt;

  MealPlanModel({
    required this.id,
    required this.day,
    this.meal,
    this.notes,
    this.updatedAt,
  });

  factory MealPlanModel.fromJson(Map<String, dynamic> json) {
    return MealPlanModel(
      id: json['id'],
      day: json['day'],
      meal: json['meal'],
      notes: json['notes'],
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  bool get isEmpty => meal == null || meal!.trim().isEmpty;
}
