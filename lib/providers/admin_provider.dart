import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../models/admin_attendance_model.dart';

class AdminProvider extends ChangeNotifier {
  List<UserModel> _users = [];
  List<UserModel> _teachers = [];
  List<AdminAttendanceModel> _attendanceRecords = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<UserModel> get users => _users;
  List<UserModel> get teachers => _teachers;
  List<AdminAttendanceModel> get attendanceRecords => _attendanceRecords;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Load all users in the system
  Future<bool> loadUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiServices.getAdminUsers();

      if (response['success'] == true) {
        final dynamic rawData = response['data'];
        List<dynamic> dataList = [];

        if (rawData is List) {
          dataList = rawData;
        } else if (rawData is Map && rawData['data'] is List) {
          dataList = rawData['data'] as List;
        }

        _users = dataList.map((item) => UserModel.fromJson(item)).toList();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to load users';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Load all academic staff (teachers)
  Future<bool> loadTeachers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiServices.getAdminTeachers();

      if (response['success'] == true) {
        final dynamic rawData = response['data'];
        List<dynamic> dataList = [];

        if (rawData is List) {
          dataList = rawData;
        } else if (rawData is Map && rawData['data'] is List) {
          dataList = rawData['data'] as List;
        }

        _teachers = dataList.map((item) => UserModel.fromJson(item)).toList();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to load teachers';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Load all attendance logs across the system
  /// Optionally filter by student [grade] (e.g. '1', '5', '10')
  Future<bool> loadAttendanceRecords({String? grade}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiServices.getAdminAttendance(grade: grade);

      if (response['success'] == true) {
        final dynamic rawData = response['data'];
        List<dynamic> dataList = [];

        if (rawData is List) {
          dataList = rawData;
        } else if (rawData is Map && rawData['data'] is List) {
          dataList = rawData['data'] as List;
        }

        _attendanceRecords = dataList
            .map((item) => AdminAttendanceModel.fromJson(item))
            .toList();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to load attendance records';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Save or update simple timetable slots for a day and grade
  Future<bool> saveTimetable(Map<String, dynamic> timetableData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiServices.saveSimpleTimetable(timetableData);

      _isLoading = false;
      if (response['success'] == true) {
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to save timetable';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
