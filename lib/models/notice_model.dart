import 'package:narme_project/models/user_model.dart';

class NoticeModel {
  final int id;
  final String title;
  final String content;
  final String category;
  final int postedBy;
  final DateTime? expiryDate;
  final DateTime createdAt;
  final UserModel? postedByUser;

  NoticeModel({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.postedBy,
    this.expiryDate,
    required this.createdAt,
    this.postedByUser,
  });

  factory NoticeModel.fromJson(Map<String, dynamic> json) {
    return NoticeModel(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      category: json['category'],
      postedBy: json['posted_by'] is int ? json['posted_by'] : (json['posted_by']?['id'] ?? 0),
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      postedByUser: json['posted_by'] != null && json['posted_by'] is! int
          ? UserModel.fromJson(json['posted_by'])
          : null,
    );
  }
}
