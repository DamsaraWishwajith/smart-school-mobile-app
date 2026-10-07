class SubjectModel {
  final int id;
  final String? grade;
  final String? subjectName;
  final String? pdf;
  final String? assignment;
  final String? dueTime;
  final bool isSubmitted;
  final DateTime? submittedAt;
  final String? submissionFile;
  final String? submissionGrade;
  final String? submissionFeedback;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SubjectModel({
    required this.id,
    this.grade,
    this.subjectName,
    this.pdf,
    this.assignment,
    this.dueTime,
    this.isSubmitted = false,
    this.submittedAt,
    this.submissionFile,
    this.submissionGrade,
    this.submissionFeedback,
    this.createdAt,
    this.updatedAt,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id'],
      grade: json['grade'],
      subjectName: json['subject_name'],
      pdf: json['pdf'],
      assignment: json['assignment'],
      dueTime: json['due_time'],
      isSubmitted: json['is_submitted'] ?? false,
      submittedAt: json['submitted_at'] != null ? DateTime.parse(json['submitted_at']) : null,
      submissionFile: json['submission_file'],
      submissionGrade: json['submission_grade'],
      submissionFeedback: json['submission_feedback'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  String get displayAssignment {
    if (assignment == null || assignment!.isEmpty) return 'No assignment';
    if (assignment!.startsWith('/storage/') || assignment!.contains('/') || assignment!.endsWith('.pdf')) {
      return 'Assignment Document';
    }
    return assignment!;
  }

  String get timeRemaining {
    if (dueTime == null || dueTime!.isEmpty) return 'No deadline';
    try {
      final now = DateTime.now();
      final deadline = DateTime.parse(dueTime!);
      final difference = deadline.difference(now);

      if (difference.isNegative) return 'Overdue';
      
      if (difference.inDays > 0) {
        final hours = difference.inHours % 24;
        return '${difference.inDays}d ${hours}h left';
      } else if (difference.inHours > 0) {
        final minutes = difference.inMinutes % 60;
        return '${difference.inHours}h ${minutes}m left';
      } else {
        return '${difference.inMinutes}m left';
      }
    } catch (e) {
      return 'Due: $dueTime';
    }
  }

  String get submissionTimeInfo {
    if (submittedAt == null) return '';
    final now = DateTime.now();
    final difference = now.difference(submittedAt!);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'grade': grade,
      'subject_name': subjectName,
      'pdf': pdf,
      'assignment': assignment,
      'due_time': dueTime,
      'is_submitted': isSubmitted,
      'submitted_at': submittedAt?.toIso8601String(),
      'submission_file': submissionFile,
      'submission_grade': submissionGrade,
      'submission_feedback': submissionFeedback,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
