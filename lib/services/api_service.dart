import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiServices {
  // For physical device with your computer's IP
  static String baseUrl = 'https://eliteinternationalschool-live.us.stackstaging.com/api';
  // For iOS simulator
  // static const String baseUrl = 'http://localhost:8000/api';
  // For physical device with your computer's IP
  // static const String baseUrl = 'http://192.168.x.x:8000/api';

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, String>> _getMultipartHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    return {'Accept': 'application/json', 'Authorization': 'Bearer $token'};
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {
      data = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {
        'success': true,
        'data': data,
        'message': (data is Map && data.containsKey('message'))
            ? data['message'].toString()
            : 'Success',
      };
    } else {
      return {
        'success': false,
        'message': (data is Map && data.containsKey('message'))
            ? data['message'].toString()
            : 'An error occurred',
        'errors':
            (data is Map && data.containsKey('errors')) ? data['errors'] : {},
        'statusCode': response.statusCode,
      };
    }
  }

  static Future<Map<String, dynamic>> _handleMultipartResponse(
    http.StreamedResponse response,
  ) async {
    final responseBody = await response.stream.bytesToString();
    final data = jsonDecode(responseBody);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      String msg = 'Success';
      if (data is Map && data['message'] != null) {
        msg = data['message'].toString();
      }
      return {
        'success': true,
        'data': data,
        'message': msg,
      };
    } else {
      String msg = 'An error occurred';
      dynamic errors = {};
      if (data is Map) {
        if (data['message'] != null) msg = data['message'].toString();
        if (data['errors'] != null) errors = data['errors'];
      }
      return {
        'success': false,
        'message': msg,
        'errors': errors,
        'statusCode': response.statusCode,
      };
    }
  }

  // Auth
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> register(
    Map<String, dynamic> userData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(userData),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Dashboard
  static Future<Map<String, dynamic>> getStudentDashboard(int studentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/students/$studentId/dashboard'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Attendance
  static Future<Map<String, dynamic>> getAttendance(
    int studentId, {
    int? month,
    int? year,
  }) async {
    try {
      String url = '$baseUrl/students/$studentId/attendance';
      if (month != null && year != null) {
        url += '?month=$month&year=$year';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getAttendanceByUser(int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/attendence/user'),
        headers: await _getHeaders(),
        body: jsonEncode({'user_id': userId}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> markQRAttendance(
    int studentId,
    String gate,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/attendance/mark-qr'),
        headers: await _getHeaders(),
        body: jsonEncode({'student_id': studentId, 'gate': gate}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Simple Timetable (flat column-based format)
  static Future<Map<String, dynamic>> getSimpleTimetables() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/simple-timetables'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Teacher Timetable — returns only this teacher's rows from simple_timetables
  static Future<Map<String, dynamic>> getTeacherTimetable(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/teacher-timetable/$userId'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Timetable
  static Future<Map<String, dynamic>> getTimetable(int studentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/students/$studentId/timetable'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Assignments
  static Future<Map<String, dynamic>> getAssignments({
    int? subjectId,
    int? studentId,
  }) async {
    try {
      String url = '$baseUrl/assignments';
      List<String> params = [];
      if (subjectId != null) params.add('subject_id=$subjectId');
      if (studentId != null) params.add('student_id=$studentId');

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> submitAssignment(
    int assignmentId,
    int studentId,
    String filePath, {
    String? comments,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/assignments/$assignmentId/submit'),
      );
      request.headers.addAll(await _getMultipartHeaders());

      request.fields['student_id'] = studentId.toString();
      if (comments != null) request.fields['comments'] = comments;
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      var response = await request.send();
      return await _handleMultipartResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Fees
  static Future<Map<String, dynamic>> getFees({int? studentId}) async {
    try {
      String url = '$baseUrl/fees';
      if (studentId != null) {
        url += '?student_id=$studentId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> processPayment(
    int studentId,
    int feeId,
    double amount,
    String paymentMethod,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/fees/pay'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'student_id': studentId,
          'fee_id': feeId,
          'amount': amount,
          'payment_method': paymentMethod,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Notices
  static Future<Map<String, dynamic>> getNotices({String? category}) async {
    try {
      String url = '$baseUrl/notices';
      if (category != null) {
        url += '?category=$category';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Events
  static Future<Map<String, dynamic>> getEvents({
    int? month,
    int? year,
    String? type,
  }) async {
    try {
      String url = '$baseUrl/events';
      List<String> params = [];
      if (month != null) params.add('month=$month');
      if (year != null) params.add('year=$year');
      if (type != null) params.add('type=$type');

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Complaints
  static Future<Map<String, dynamic>> getComplaints({
    int? userId,
    String? status,
  }) async {
    try {
      String url = '$baseUrl/complaints';
      List<String> params = [];
      if (userId != null) params.add('user_id=$userId');
      if (status != null) params.add('status=$status');

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> submitComplaint(
    String category,
    String message,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/complaints'),
        headers: await _getHeaders(),
        body: jsonEncode({'category': category, 'message': message}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Create Notice (Admin)
  static Future<Map<String, dynamic>> createNotice(Map<String, dynamic> noticeData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/notices'),
        headers: await _getHeaders(),
        body: jsonEncode(noticeData),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Create Event (Admin)
  static Future<Map<String, dynamic>> createEvent(Map<String, dynamic> eventData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/events'),
        headers: await _getHeaders(),
        body: jsonEncode(eventData),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Update Complaint Status & Response (Admin)
  static Future<Map<String, dynamic>> updateComplaint(int id, Map<String, dynamic> complaintData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/complaints/$id'),
        headers: await _getHeaders(),
        body: jsonEncode(complaintData),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Delete Complaint (Admin)
  static Future<Map<String, dynamic>> deleteComplaint(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/complaints/$id'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Meal Plan
  static Future<Map<String, dynamic>> getMealPlans() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/meal-plans'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Create/Update Meal Plan for a day (Admin)
  static Future<Map<String, dynamic>> saveMealPlan(Map<String, dynamic> mealPlanData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/meal-plans'),
        headers: await _getHeaders(),
        body: jsonEncode(mealPlanData),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Leaves
  static Future<Map<String, dynamic>> getMyLeaveRequests() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/leaves/my'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> submitLeaveRequest(
    String leaveType,
    String startDate,
    String endDate,
    String reason,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/leaves'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'leave_type': leaveType,
          'start_date': startDate,
          'end_date': endDate,
          'reason': reason,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Subjects
  static Future<Map<String, dynamic>> getSubjects({int? userId}) async {
    try {
      String url = '$baseUrl/subjects';
      if (userId != null) {
        url += '?user_id=$userId';
      }
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> addSubject(Map<String, dynamic> subjectData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/subjects'),
        headers: await _getHeaders(),
        body: jsonEncode(subjectData),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> uploadSubject({
    required String grade,
    required String subjectName,
    String? pdfPath,
    String? assignmentPath,
    String? dueTime,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/subjects'),
      );
      request.headers.addAll(await _getMultipartHeaders());

      request.fields['grade'] = grade;
      request.fields['subject_name'] = subjectName;
      if (dueTime != null) request.fields['due_time'] = dueTime;

      if (pdfPath != null && pdfPath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('pdf', pdfPath));
      }
      if (assignmentPath != null && assignmentPath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('assignment', assignmentPath));
      }

      var response = await request.send();
      return await _handleMultipartResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> submitSubjectAssignment({
    required int userId,
    required int subjectId,
    required String filePath,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/subject-submissions'),
      );
      request.headers.addAll(await _getMultipartHeaders());

      request.fields['user_id'] = userId.toString();
      request.fields['subject_id'] = subjectId.toString();
      request.files.add(await http.MultipartFile.fromPath('assignment_pdf', filePath));

      var response = await request.send();
      return await _handleMultipartResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getSubjectSubmissions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/subject-submissions'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> gradeSubmission(int id, String grade, String feedback) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/subject-submissions/$id/grade'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'grade': grade,
          'feedback': feedback,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Admin Methods
  static Future<Map<String, dynamic>> getAdminUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/users'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getAdminTeachers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/teachers'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getAdminAttendance({String? grade}) async {
    try {
      final uri = grade != null && grade.isNotEmpty
          ? Uri.parse('$baseUrl/admin/attendance?grade=${Uri.encodeComponent(grade)}')
          : Uri.parse('$baseUrl/admin/attendance');
      final response = await http.get(uri, headers: await _getHeaders());
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> saveSimpleTimetable(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/simple-timetables'),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Messaging API Methods
  static Future<Map<String, dynamic>> getConversations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/messages/conversations'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getMessagesWith(int otherUserId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/messages/with/$otherUserId'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> sendMessage(int receiverId, String content) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/messages'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'receiver_id': receiverId,
          'content': content,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getTeacherSalaryHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/teacher/salaries'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Exam Results APIs
  static Future<Map<String, dynamic>> getExamResults({
    int? studentId,
    int? subjectId,
    String? term,
    int? academicYear,
    bool all = true,
  }) async {
    try {
      List<String> params = [];
      if (all) params.add('all=true');
      if (studentId != null) params.add('student_id=$studentId');
      if (subjectId != null) params.add('subject_id=$subjectId');
      if (term != null) params.add('term=${Uri.encodeComponent(term)}');
      if (academicYear != null) params.add('academic_year=$academicYear');
      
      String url = '$baseUrl/exam-results';
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getStudentReport(
    int studentId,
    int academicYear,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/exam-results/student/$studentId/$academicYear'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> addExamResult(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/exam-results'),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateExamResult(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/exam-results/$id'),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteExamResult(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/exam-results/$id'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateFcmToken(String fcmToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/fcm-token'),
        headers: await _getHeaders(),
        body: jsonEncode({'fcm_token': fcmToken}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Emergency Alerts
  static Future<Map<String, dynamic>> sendEmergencyAlert({
    required String title,
    required String content,
    String? presetType,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/emergency-alert'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'title': title,
          'content': content,
          'preset_type': presetType ?? 'custom',
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getEmergencyAlerts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/emergency-alerts'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Gallery API
  static Future<Map<String, dynamic>> getGalleries() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/galleries'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // AI Performance Reports API
  static Future<Map<String, dynamic>> getStudentAiReport() async {
    try {
      print('[ApiServices] Requesting AI report from: ' + baseUrl + '/student/ai-performance');
      final response = await http.get(
        Uri.parse('$baseUrl/student/ai-performance'),
        headers: await _getHeaders(),
      );
      print('[ApiServices] AI report response: ' + response.statusCode.toString());
      return _handleResponse(response);
    } catch (e) {
      print('[ApiServices] AI report network error: ' + e.toString());
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> generateStudentAiReport({
    String? academicYear,
    String? term,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      if (academicYear != null && academicYear.isNotEmpty) {
        body['academic_year'] = academicYear;
      }
      if (term != null && term.isNotEmpty) {
        body['term'] = term;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/student/ai-performance/generate'),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}

typedef ApiService = ApiServices;

