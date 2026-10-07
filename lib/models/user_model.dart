class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? address;
  final String? dob;
  final String? profilePic;
  final StudentModel? student;
  final TeacherModel? teacher;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.address,
    this.dob,
    this.profilePic,
    this.student,
    this.teacher,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      phone: json['phone'],
      address: json['address'],
      dob: json['dob'],
      profilePic: json['profile_pic'],
      student: json['student'] != null
          ? StudentModel.fromJson(json['student'])
          : null,
      teacher: json['teacher'] != null
          ? TeacherModel.fromJson(json['teacher'])
          : null,
    );
  }
}

class StudentModel {
  final int id;
  final int userId;
  final String studentId;
  final String grade;
  final String className;
  final int? parentId;

  StudentModel({
    required this.id,
    required this.userId,
    required this.studentId,
    required this.grade,
    required this.className,
    this.parentId,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'],
      userId: json['user_id'],
      studentId: json['student_id'],
      grade: json['grade'],
      className: json['class'],
      parentId: json['parent_id'],
    );
  }
}

class TeacherModel {
  final int id;
  final int userId;
  final String employeeId;
  final String qualification;
  final String subjectSpecialization;
  final String? salary;

  TeacherModel({
    required this.id,
    required this.userId,
    required this.employeeId,
    required this.qualification,
    required this.subjectSpecialization,
    this.salary,
  });

  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    return TeacherModel(
      id: json['id'],
      userId: json['user_id'],
      employeeId: json['employee_id'],
      qualification: json['qualification'],
      subjectSpecialization: json['subject_specialization'],
      salary: json['salary']?.toString(),
    );
  }
}
