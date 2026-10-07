import 'package:narme_project/models/user_model.dart';

class ComplaintModel {
  final int id;
  final int userId;
  final String category;
  final String message;
  final String status;
  final String? adminResponse;
  final DateTime createdAt;
  final UserModel? user;

  ComplaintModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.message,
    required this.status,
    this.adminResponse,
    required this.createdAt,
    this.user,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['id'],
      userId: json['user_id'],
      category: json['category'],
      message: json['message'],
      status: json['status'],
      adminResponse: json['admin_response'],
      createdAt: DateTime.parse(json['created_at']),
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }
}
