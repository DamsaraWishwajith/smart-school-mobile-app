class AttendanceModel {
  final int id;
  final int studentId;
  final DateTime date;
  final String status;
  final String? entryTime;
  final String? exitTime;
  final String? gate;

  AttendanceModel({
    required this.id,
    required this.studentId,
    required this.date,
    required this.status,
    this.entryTime,
    this.exitTime,
    this.gate,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    // Handle different date formats
    String dateStr = json['date'].toString().replaceAll('/', '-');
    
    return AttendanceModel(
      id: json['id'],
      studentId: json['student_id'] ?? json['user_id'] ?? 0,
      date: DateTime.parse(dateStr),
      status: json['status'],
      entryTime: json['entry_time'] ?? json['in_time'],
      exitTime: json['exit_time'] ?? json['out_time'],
      gate: json['gate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'date': date.toIso8601String(),
      'status': status,
      'entry_time': entryTime,
      'exit_time': exitTime,
      'gate': gate,
    };
  }
}
