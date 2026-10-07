import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/exam_result_model.dart';

class TeacherProvider extends ChangeNotifier {
  List<dynamic> _submissions = [];
  List<dynamic> _salaries = [];
  List<dynamic> _leaveRequests = [];
  List<ExamResultModel> _examResults = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get submissions => _submissions;
  List<dynamic> get salaries => _salaries;
  List<dynamic> get leaveRequests => _leaveRequests;
  List<ExamResultModel> get examResults => _examResults;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> loadSubmissions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiServices.getSubjectSubmissions();
      
      _isLoading = false;
      if (response['success'] == true) {
        // Under data, get list of submissions
        final payload = response['data'];
        if (payload is Map && payload['data'] is List) {
          _submissions = payload['data'];
        } else if (payload is List) {
          _submissions = payload;
        } else {
          _submissions = [];
        }
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to load submissions';
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

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> uploadSubject({
    required String grade,
    required String subjectName,
    String? pdfPath,
    String? assignmentPath,
    String? dueTime,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiServices.uploadSubject(
        grade: grade,
        subjectName: subjectName,
        pdfPath: pdfPath,
        assignmentPath: assignmentPath,
        dueTime: dueTime,
      );

      _isLoading = false;
      if (response['success'] == true) {
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to upload subject';
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

  Future<bool> gradeSubmission(int id, String grade, String feedback) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiServices.gradeSubmission(id, grade, feedback);

      _isLoading = false;
      if (response['success'] == true) {
        await loadSubmissions();
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to grade submission';
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

  Future<bool> loadSalaryHistory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiServices.getTeacherSalaryHistory();
      
      _isLoading = false;
      if (response['success'] == true) {
        final payload = response['data'];
        debugPrint('Teacher salary response data: $payload');
        
        if (payload is List) {
          _salaries = payload;
        } else if (payload is Map) {
          if (payload['data'] is List) {
            _salaries = payload['data'];
          } else if (payload['salaries'] is List) {
            _salaries = payload['salaries'];
          } else if (payload.containsKey('success') && payload['data'] is List) {
            _salaries = payload['data'];
          } else {
            _salaries = [];
          }
        } else {
          _salaries = [];
        }
        
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to load salary history';
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

  Future<bool> loadLeaveRequests() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiServices.getMyLeaveRequests();
      
      _isLoading = false;
      if (response['success'] == true) {
        final payload = response['data'];
        if (payload is List) {
          _leaveRequests = payload;
        } else if (payload is Map && payload['data'] is List) {
          _leaveRequests = payload['data'];
        } else {
          _leaveRequests = [];
        }
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to load leave requests';
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

  Future<bool> submitLeave({
    required String leaveType,
    required String startDate,
    required String endDate,
    required String reason,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiServices.submitLeaveRequest(
        leaveType,
        startDate,
        endDate,
        reason,
      );

      _isLoading = false;
      if (response['success'] == true) {
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to submit leave request';
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

  Future<bool> loadExamResults({int? studentId, int? subjectId, String? term, int? academicYear}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiServices.getExamResults(
        studentId: studentId,
        subjectId: subjectId,
        term: term,
        academicYear: academicYear,
      );
      
      _isLoading = false;
      if (response['success'] == true) {
        final payload = response['data'];
        if (payload is List) {
          _examResults = payload.map((item) {
            final map = Map<String, dynamic>.from(item as Map);
            return ExamResultModel.fromJson(map);
          }).toList();
        } else if (payload is Map && payload['data'] is List) {
          _examResults = (payload['data'] as List).map((item) {
            final map = Map<String, dynamic>.from(item as Map);
            return ExamResultModel.fromJson(map);
          }).toList();
        } else {
          _examResults = [];
        }
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to load exam results';
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

  Future<bool> addExamResult(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiServices.addExamResult(data);
      _isLoading = false;
      if (response['success'] == true) {
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to add exam result';
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

  Future<bool> updateExamResult(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiServices.updateExamResult(id, data);
      _isLoading = false;
      if (response['success'] == true) {
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to update exam result';
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

  Future<bool> deleteExamResult(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiServices.deleteExamResult(id);
      _isLoading = false;
      if (response['success'] == true) {
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to delete exam result';
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
}
