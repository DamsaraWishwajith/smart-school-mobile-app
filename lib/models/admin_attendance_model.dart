import 'user_model.dart';

class AdminAttendanceModel {
  final int id;
  final int userId;
  final String date;
  final String? inTime;
  final String? outTime;
  final String? status;
  final UserModel? user;

  AdminAttendanceModel({
    required this.id,
    required this.userId,
    required this.date,
    this.inTime,
    this.outTime,
    this.status,
    this.user,
  });

  factory AdminAttendanceModel.fromJson(Map<String, dynamic> json) {
    return AdminAttendanceModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      date: json['date'] ?? '',
      inTime: json['in_time'],
      outTime: json['out_time'],
      status: json['status'],
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date,
      'in_time': inTime,
      'out_time': outTime,
      'status': status,
      'user': user?.id != null ? {
        'id': user!.id,
        'name': user!.name,
        'email': user!.email,
        'role': user!.role,
      } : null,
    };
  }
}
