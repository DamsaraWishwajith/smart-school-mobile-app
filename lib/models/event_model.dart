class EventModel {
  final int id;
  final String title;
  final String description;
  final DateTime eventDate;
  final String startTime;
  final String endTime;
  final String location;
  final String? whatToBring;
  final String? whatToDo;
  final String? learningGoals;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.eventDate,
    required this.startTime,
    required this.endTime,
    required this.location,
    this.whatToBring,
    this.whatToDo,
    this.learningGoals,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      eventDate: DateTime.parse(json['event_date']),
      startTime: json['start_time'],
      endTime: json['end_time'],
      location: json['location'],
      whatToBring: json['what_to_bring'],
      whatToDo: json['what_to_do'],
      learningGoals: json['learning_goals'],
    );
  }
}
