class AssignmentModel {
  final int id;
  final String title;
  final String description;
  final int subjectId;
  final int teacherId;
  final DateTime dueDate;
  final String? fileUrl;
  final int? totalMarks;
  final String? submissionStatus;
  final SubmissionModel? submission;

  AssignmentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.subjectId,
    required this.teacherId,
    required this.dueDate,
    this.fileUrl,
    this.totalMarks,
    this.submissionStatus,
    this.submission,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      subjectId: json['subject_id'],
      teacherId: json['teacher_id'],
      dueDate: DateTime.parse(json['due_date']),
      fileUrl: json['file_url'],
      totalMarks: json['total_marks'],
      submissionStatus: json['submission_status'],
      submission: json['submission'] != null
          ? SubmissionModel.fromJson(json['submission'])
          : null,
    );
  }
}

class SubmissionModel {
  final int id;
  final int assignmentId;
  final int studentId;
  final String fileUrl;
  final String? comments;
  final int? marks;
  final String status;
  final DateTime submittedAt;

  SubmissionModel({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.fileUrl,
    this.comments,
    this.marks,
    required this.status,
    required this.submittedAt,
  });

  factory SubmissionModel.fromJson(Map<String, dynamic> json) {
    return SubmissionModel(
      id: json['id'],
      assignmentId: json['assignment_id'],
      studentId: json['student_id'],
      fileUrl: json['file_url'],
      comments: json['comments'],
      marks: json['marks'],
      status: json['status'],
      submittedAt: DateTime.parse(json['submitted_at']),
    );
  }
}
