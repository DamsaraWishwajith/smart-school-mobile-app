import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/attendance_model.dart';
import '../models/timetable_model.dart';
import '../models/simple_timetable_model.dart';
import '../models/assignment_model.dart';
import '../models/fee_model.dart';
import '../models/notice_model.dart';
import '../models/event_model.dart';
import '../models/complaint_model.dart';
import '../models/meal_plan_model.dart';

class StudentProvider extends ChangeNotifier {
  Map<String, dynamic>? _dashboardData;
  List<AttendanceModel> _attendance = [];
  List<TimetableModel> _timetable = [];
  List<SimpleTimetableModel> _simpleTimetable = [];
  List<AssignmentModel> _assignments = [];
  List<FeeModel> _fees = [];
  List<NoticeModel> _notices = [];
  List<EventModel> _events = [];
  List<ComplaintModel> _complaints = [];
  List<MealPlanModel> _mealPlans = [];

  bool _isLoading = false;
  String? _error;
  int? _currentStudentId;

  // Getters
  Map<String, dynamic>? get dashboardData => _dashboardData;
  List<AttendanceModel> get attendance => _attendance;
  List<TimetableModel> get timetable => _timetable;
  List<SimpleTimetableModel> get simpleTimetable => _simpleTimetable;
  List<AssignmentModel> get assignments => _assignments;
  List<FeeModel> get fees => _fees;
  List<NoticeModel> get notices => _notices;
  List<EventModel> get events => _events;
  List<ComplaintModel> get complaints => _complaints;
  List<MealPlanModel> get mealPlans => _mealPlans;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get currentStudentId => _currentStudentId;

  // Set student ID
  void setStudentId(int studentId) {
    _currentStudentId = studentId;
    notifyListeners();
  }

  // Clear all data
  void clearAll() {
    _dashboardData = null;
    _attendance = [];
    _timetable = [];
    _simpleTimetable = [];
    _assignments = [];
    _fees = [];
    _notices = [];
    _events = [];
    _complaints = [];
    _isLoading = false;
    _error = null;
    _currentStudentId = null;
    notifyListeners();
  }

  // Dashboard
  Future<bool> loadDashboard(int studentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiServices.getStudentDashboard(
        studentId,
      );
      if (response['success'] == true) {
        _dashboardData = response['data'];
        _currentStudentId = studentId;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to load dashboard';
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

  // Attendance
  Future<bool> loadAttendance(
    int studentId, {
    int? month,
    int? year,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiServices.getAttendance(
        studentId,
        month: month,
        year: year,
      );
      if (response['success'] == true) {
        final dynamic rawData = response['data'];
        List<dynamic> dataList = [];

        if (rawData is List) {
          dataList = rawData;
        } else if (rawData is Map && rawData['data'] is List) {
          dataList = rawData['data'] as List;
        }

        _attendance = dataList
            .map((item) => AttendanceModel.fromJson(item))
            .toList();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to load attendance';
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

  Future<bool> loadUserAttendance(int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiServices.getAttendanceByUser(userId);
      if (response['success'] == true) {
        final dynamic rawData = response['data'];
        List<dynamic> dataList = [];

        if (rawData is List) {
          dataList = rawData;
        } else if (rawData is Map && rawData['data'] is List) {
          dataList = rawData['data'] as List;
        }

        _attendance = dataList
            .map((item) => AttendanceModel.fromJson(item))
            .toList();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to load attendance logs';
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

  Future<Map<String, dynamic>?> markAttendance(
    int studentId,
    String gate,
  ) async {
    try {
      final response = await ApiServices.markQRAttendance(
        studentId,
        gate,
      );
      if (response['success'] == true) {
        await loadAttendance(studentId);
        return response['data'];
      } else {
        _error = response['message'] ?? 'Failed to mark attendance';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Timetable - FIXED VERSION
  Future<bool> loadTimetable(
    int studentId, {
    int? gradeId, // You might need gradeId instead of studentId
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // The API might expect gradeId instead of studentId
      // Adjust this based on your actual API
      final response = await ApiServices.getTimetable(
        studentId, // or gradeId if that's what your API expects
      );

      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        _timetable = data.map((item) => TimetableModel.fromJson(item)).toList();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to load timetable';
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

  // Get filtered timetable for a specific day
  List<TimetableModel> getTimetableForDay(String day) {
    return _timetable
        .where((schedule) => schedule.day.toLowerCase() == day.toLowerCase())
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  // Simple timetable - fetches from /api/simple-timetables
  Future<bool> loadSimpleTimetable({String? userGrade}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiServices.getSimpleTimetables();

      if (response['success'] == true) {
        // _handleResponse wraps the full JSON body in 'data',
        // so the actual array is at response['data']['data']
        final dynamic rawData = response['data'];
        List<dynamic> dataList = [];

        if (rawData is List) {
          dataList = rawData;
        } else if (rawData is Map && rawData['data'] is List) {
          dataList = rawData['data'] as List;
        }

        var models = dataList
            .map((item) => SimpleTimetableModel.fromJson(item))
            .toList();

        // Filter by grade if provided
        if (userGrade != null && userGrade.isNotEmpty) {
          // Flexible matching: handles both "11" matching "Grade 11" 
          // or exact "Grade 5" matching "Grade 5"
          models = models.where((t) {
            final timetableGrade = t.grade.toLowerCase();
            final searchGrade = userGrade.toLowerCase();
            return timetableGrade == searchGrade || 
                   timetableGrade.contains(searchGrade) ||
                   searchGrade.contains(timetableGrade);
          }).toList();
        }

        _simpleTimetable = models;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to load timetable';
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

  // Teacher timetable — fetches only this teacher's rows from /api/teacher-timetable/{userId}
  Future<bool> loadTeacherTimetable(int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiServices.getTeacherTimetable(userId);

      if (response['success'] == true) {
        final dynamic rawData = response['data'];
        List<dynamic> dataList = [];

        if (rawData is List) {
          dataList = rawData;
        } else if (rawData is Map && rawData['data'] is List) {
          dataList = rawData['data'] as List;
        }

        var models = dataList
            .map((item) => SimpleTimetableModel.fromJson(item))
            .toList();

        // If direct teacher endpoint returned nothing, fallback to fetching all simple timetables
        if (models.isEmpty) {
          final allResponse = await ApiServices.getSimpleTimetables();
          if (allResponse['success'] == true) {
            final dynamic allRaw = allResponse['data'];
            List<dynamic> allList = [];
            if (allRaw is List) {
              allList = allRaw;
            } else if (allRaw is Map && allRaw['data'] is List) {
              allList = allRaw['data'] as List;
            }
            models = allList
                .map((item) => SimpleTimetableModel.fromJson(item))
                .where((t) => t.grade.toLowerCase().contains('teacher:$userId'))
                .toList();
          }
        }

        _simpleTimetable = models;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to load teacher timetable';
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

  // Get simple timetable entries for a specific day
  SimpleTimetableModel? getSimpleTimetableForDay(String day) {
    try {
      return _simpleTimetable.firstWhere(
        (t) => t.day.toLowerCase() == day.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  // Get simple timetable entries for a specific day and grade
  SimpleTimetableModel? getSimpleTimetableForDayAndGrade(String day, String grade) {
    try {
      return _simpleTimetable.firstWhere(
        (t) =>
            t.day.toLowerCase() == day.toLowerCase() &&
            (t.grade.toLowerCase() == grade.toLowerCase() ||
                t.grade.toLowerCase().contains(grade.toLowerCase()) ||
                grade.toLowerCase().contains(t.grade.toLowerCase())),
      );
    } catch (_) {
      return null;
    }
  }

  // Assignments
  Future<bool> loadAssignments(
    int studentId, {
    int? subjectId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiServices.getAssignments(
        studentId: studentId,
        subjectId: subjectId,
      );
      if (response['success'] == true) {
        _assignments = (response['data'] as List)
            .map((item) => AssignmentModel.fromJson(item))
            .toList();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to load assignments';
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

  Future<Map<String, dynamic>?> submitAssignment(
    int assignmentId,
    int studentId,
    String filePath, {
    String? comments,
  }) async {
    try {
      final response = await ApiServices.submitAssignment(
        assignmentId,
        studentId,
        filePath,
        comments: comments,
      );
      if (response['success'] == true) {
        await loadAssignments(studentId);
        return response['data'];
      } else {
        _error = response['message'] ?? 'Failed to submit assignment';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> submitSubjectAssignment({
    required int userId,
    required int subjectId,
    required String filePath,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiServices.submitSubjectAssignment(
        userId: userId,
        subjectId: subjectId,
        filePath: filePath,
      );
      
      _isLoading = false;
      if (response['success'] == true) {
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Submission failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Fees
  Future<bool> loadFees(int studentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiServices.getFees(
        studentId: studentId,
      );
      if (response['success'] == true) {
        _fees = (response['data'] as List)
            .map((item) => FeeModel.fromJson(item))
            .toList();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to load fees';
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

  Future<Map<String, dynamic>?> processPayment(
    int studentId,
    int feeId,
    double amount,
    String paymentMethod,
  ) async {
    try {
      final response = await ApiServices.processPayment(
        studentId,
        feeId,
        amount,
        paymentMethod,
      );
      if (response['success'] == true) {
        await loadFees(studentId);
        return response['data'];
      } else {
        _error = response['message'] ?? 'Payment failed';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Notices
  Future<bool> loadNotices({String? category}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiServices.getNotices(
        category: category,
      );
      if (response['success'] == true) {
        _notices = (response['data'] as List)
            .map((item) => NoticeModel.fromJson(item))
            .toList();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to load notices';
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

  // Events
  Future<bool> loadEvents({
    int? month,
    int? year,
    String? type,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiServices.getEvents(
        month: month,
        year: year,
        type: type,
      );
      if (response['success'] == true) {
        _events = (response['data'] as List)
            .map((item) => EventModel.fromJson(item))
            .toList();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to load events';
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

  // Complaints
  Future<bool> loadComplaints({
    int? userId,
    String? status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiServices.getComplaints(
        userId: userId,
        status: status,
      );
      if (response['success'] == true) {
        _complaints = (response['data'] as List)
            .map((item) => ComplaintModel.fromJson(item))
            .toList();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to load complaints';
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

  Future<Map<String, dynamic>?> submitComplaint(
    String category,
    String message,
  ) async {
    try {
      final response = await ApiServices.submitComplaint(
        category,
        message,
      );
      if (response['success'] == true) {
        await loadComplaints();
        return response['data'];
      } else {
        _error = response['message'] ?? 'Failed to submit complaint';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> createNotice(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiServices.createNotice(data);
      if (response['success'] == true) {
        await loadNotices();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to create notice';
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

  Future<bool> createEvent(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiServices.createEvent(data);
      if (response['success'] == true) {
        await loadEvents();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to create event';
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

  Future<bool> updateComplaint(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiServices.updateComplaint(id, data);
      if (response['success'] == true) {
        await loadComplaints();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to update complaint';
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

  Future<bool> deleteComplaint(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiServices.deleteComplaint(id);
      if (response['success'] == true) {
        await loadComplaints();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to delete complaint';
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

  Future<bool> loadMealPlans() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiServices.getMealPlans();
      final body = response['data'];
      final list = (body is Map && body['data'] is List) ? body['data'] : body;
      if (response['success'] == true && list is List) {
        _mealPlans = list
            .map((item) => MealPlanModel.fromJson(item))
            .toList();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to load meal plans';
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

  Future<bool> saveMealPlan(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiServices.saveMealPlan(data);
      if (response['success'] == true) {
        await loadMealPlans();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to save meal plan';
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

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
