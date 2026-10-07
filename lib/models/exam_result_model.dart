class ExamResultModel {
  final int id;
  final int studentId;
  final int subjectId;
  final String examName;
  final int marksObtained;
  final int totalMarks;
  final double percentage;
  final String grade; // Letter Grade e.g. A, B, C, S, F
  final String studentClassGrade; // Class Grade e.g. Grade 1, Grade 2
  final String term;
  final int academicYear;
  final String? remarks;
  final String studentName;
  final String subjectName;

  ExamResultModel({
    required this.id,
    required this.studentId,
    required this.subjectId,
    required this.examName,
    required this.marksObtained,
    required this.totalMarks,
    required this.percentage,
    required this.grade,
    required this.studentClassGrade,
    required this.term,
    required this.academicYear,
    this.remarks,
    required this.studentName,
    required this.subjectName,
  });

  static int _parseInt(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) {
      return int.tryParse(val) ?? (double.tryParse(val)?.toInt() ?? 0);
    }
    return 0;
  }

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  factory ExamResultModel.fromJson(Map<String, dynamic> json) {
    String name = 'Unknown Student';
    String studentGrade = 'Grade 1';

    if (json['student'] != null && json['student'] is Map) {
      final studentMap = Map<String, dynamic>.from(json['student'] as Map);
      if (studentMap['user'] != null && studentMap['user'] is Map) {
        final userMap = Map<String, dynamic>.from(studentMap['user'] as Map);
        if (userMap['name'] != null) {
          name = userMap['name'].toString();
        }
      } else if (studentMap['name'] != null) {
        name = studentMap['name'].toString();
      }

      if (studentMap['grade'] != null &&
          studentMap['grade'].toString().isNotEmpty) {
        studentGrade = studentMap['grade'].toString();
      } else if (studentMap['class'] != null &&
          studentMap['class'].toString().isNotEmpty) {
        studentGrade = 'Grade ${studentMap['class']}';
      }
    } else if (json['student_name'] != null) {
      name = json['student_name'].toString();
    }

    String sub = 'Unknown Subject';
    if (json['subject'] != null && json['subject'] is Map) {
      final subMap = Map<String, dynamic>.from(json['subject'] as Map);
      if (subMap['subject_name'] != null) {
        sub = subMap['subject_name'].toString();
      } else if (subMap['name'] != null) {
        sub = subMap['name'].toString();
      }
    } else if (json['subject_name'] != null) {
      sub = json['subject_name'].toString();
    }

    int marks = _parseInt(json['marks_obtained']);
    int total = _parseInt(json['total_marks']);
    double pct = _parseDouble(json['percentage']);
    if (pct == 0.0 && total > 0) {
      pct = (marks / total) * 100;
    }

    String letterGrade = json['grade']?.toString() ?? '';
    if (letterGrade.isEmpty || letterGrade.startsWith('Grade')) {
      if (pct >= 75) {
        letterGrade = 'A';
      } else if (pct >= 65) {
        letterGrade = 'B';
      } else if (pct >= 55) {
        letterGrade = 'C';
      } else if (pct >= 35) {
        letterGrade = 'S';
      } else {
        letterGrade = 'F';
      }
    }

    if (!studentGrade.toLowerCase().startsWith('grade')) {
      studentGrade = 'Grade $studentGrade';
    }

    return ExamResultModel(
      id: _parseInt(json['id']),
      studentId: _parseInt(json['student_id']),
      subjectId: _parseInt(json['subject_id']),
      examName: json['exam_name']?.toString() ?? 'Test Exam',
      marksObtained: marks,
      totalMarks: total,
      percentage: pct,
      grade: letterGrade,
      studentClassGrade: studentGrade,
      term: json['term']?.toString() ?? 'Term 1',
      academicYear: _parseInt(json['academic_year']),
      remarks: json['remarks']?.toString(),
      studentName: name,
      subjectName: sub,
    );
  }
}
