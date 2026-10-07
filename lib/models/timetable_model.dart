class TimetableModel {
  final int id;
  final int gradeId;
  final int subjectId;
  final int teacherId;
  final String day;
  final String startTime;
  final String endTime;
  final String room;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Subject subject;
  final Teacher teacher;
  final Grade grade;

  TimetableModel({
    required this.id,
    required this.gradeId,
    required this.subjectId,
    required this.teacherId,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.createdAt,
    required this.updatedAt,
    required this.subject,
    required this.teacher,
    required this.grade,
  });

  factory TimetableModel.fromJson(Map<String, dynamic> json) {
    return TimetableModel(
      id: json['id'] ?? 0,
      gradeId: json['grade_id'] ?? 0,
      subjectId: json['subject_id'] ?? 0,
      teacherId: json['teacher_id'] ?? 0,
      day: json['day'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      room: json['room'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      subject: json['subject'] != null
          ? Subject.fromJson(json['subject'])
          : Subject(id: 0, name: 'Unknown'),
      teacher: json['teacher'] != null
          ? Teacher.fromJson(json['teacher'])
          : Teacher(id: 0, employeeId: ''),
      grade: json['grade'] != null
          ? Grade.fromJson(json['grade'])
          : Grade(id: 0, name: 'Unknown'),
    );
  }
}

class Subject {
  final int id;
  final String name;
  final String? code;
  final String? description;

  Subject({required this.id, required this.name, this.code, this.description});

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown Subject',
      code: json['code'],
      description: json['description'],
    );
  }
}

class Teacher {
  final int id;
  final String employeeId;
  final User? user;

  Teacher({required this.id, required this.employeeId, this.user});

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['id'] ?? 0,
      employeeId: json['employee_id'] ?? '',
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }
}

class User {
  final int id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      email: json['email'] ?? '',
    );
  }
}

class Grade {
  final int id;
  final String name;
  final String? section;

  Grade({required this.id, required this.name, this.section});

  factory Grade.fromJson(Map<String, dynamic> json) {
    return Grade(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown Grade',
      section: json['section'],
    );
  }
}
