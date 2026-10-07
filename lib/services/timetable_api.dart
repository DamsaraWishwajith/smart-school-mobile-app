import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl =
      'https://eliteinternationalschool-live.us.stackstaging.com/api';

  // Auth endpoints
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      return jsonDecode(response.body);
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
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> logout(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getCurrentUser(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Student endpoints
  static Future<Map<String, dynamic>> getStudentDashboard(
    int studentId, {
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/student/$studentId/dashboard'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Timetable endpoint - FIXED
  static Future<Map<String, dynamic>> getTimetable(
    int studentId, {
    required String token,
    int? gradeId, // Optional if your API uses gradeId
  }) async {
    try {
      // Adjust the endpoint based on your Laravel routes
      // Option 1: Using student ID
      final url = '$baseUrl/student/$studentId/timetable';

      // Option 2: Using grade ID (if your API uses this)
      // final url = gradeId != null
      //     ? '$baseUrl/timetables/grade/$gradeId'
      //     : '$baseUrl/timetables/formatted';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed with status: ${response.statusCode}',
          'data': [],
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e', 'data': []};
    }
  }

  // Attendance endpoints
  static Future<Map<String, dynamic>> getAttendance(
    int studentId, {
    int? month,
    int? year,
    required String token,
  }) async {
    try {
      String url = '$baseUrl/student/$studentId/attendance';
      if (month != null && year != null) {
        url += '?month=$month&year=$year';
      }
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> markQRAttendance(
    int studentId,
    String gate, {
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/attendance/qr'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'student_id': studentId, 'gate': gate}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Add other endpoints similarly...
  static Future<Map<String, dynamic>> getAssignments({
    required int studentId,
    int? subjectId,
    required String token,
  }) async {
    try {
      String url = '$baseUrl/student/$studentId/assignments';
      if (subjectId != null) {
        url += '?subject_id=$subjectId';
      }
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> submitAssignment(
    int assignmentId,
    int studentId,
    String filePath, {
    String? comments,
    required String token,
  }) async {
    // Implement file upload logic here
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/assignments/$assignmentId/submit'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['student_id'] = studentId.toString();
      if (comments != null) {
        request.fields['comments'] = comments;
      }
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      return jsonDecode(responseData);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getFees({
    required int studentId,
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/student/$studentId/fees'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> processPayment(
    int studentId,
    int feeId,
    double amount,
    String paymentMethod, {
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payments/process'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'student_id': studentId,
          'fee_id': feeId,
          'amount': amount,
          'payment_method': paymentMethod,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getNotices({
    String? category,
    required String token,
  }) async {
    try {
      String url = '$baseUrl/notices';
      if (category != null) {
        url += '?category=$category';
      }
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getEvents({
    int? month,
    int? year,
    String? type,
    required String token,
  }) async {
    try {
      String url = '$baseUrl/events';
      final queryParams = <String, String>{};
      if (month != null) queryParams['month'] = month.toString();
      if (year != null) queryParams['year'] = year.toString();
      if (type != null) queryParams['type'] = type;

      if (queryParams.isNotEmpty) {
        url += '?${Uri(queryParameters: queryParams).query}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getComplaints({
    int? userId,
    String? status,
    required String token,
  }) async {
    try {
      String url = '$baseUrl/complaints';
      final queryParams = <String, String>{};
      if (userId != null) queryParams['user_id'] = userId.toString();
      if (status != null) queryParams['status'] = status;

      if (queryParams.isNotEmpty) {
        url += '?${Uri(queryParameters: queryParams).query}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> submitComplaint(
    String category,
    String message, {
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/complaints'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'category': category, 'message': message}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getGalleries() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/galleries'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      final data = jsonDecode(response.body);
      if (data is List) {
        return {'success': true, 'data': data};
      } else if (data is Map<String, dynamic> && data.containsKey('data')) {
        return {'success': true, 'data': data['data']};
      } else if (data is Map<String, dynamic>) {
        return data;
      }
      return {'success': false, 'message': 'Invalid response format'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Create Gallery Album (Admin)
  static Future<Map<String, dynamic>> createGallery({
    required String eventName,
    String? description,
    String? eventDate,
    required List<String> imagePaths,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/galleries'),
      );
      request.headers['Accept'] = 'application/json';
      if (token != null) request.headers['Authorization'] = 'Bearer $token';

      request.fields['event_name'] = eventName;
      if (eventDate != null) request.fields['event_date'] = eventDate;
      if (description != null) request.fields['description'] = description;

      for (final path in imagePaths) {
        request.files.add(await http.MultipartFile.fromPath('images[]', path));
      }

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      return jsonDecode(responseBody);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Delete Gallery Album (Admin)
  static Future<Map<String, dynamic>> deleteGallery(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.delete(
        Uri.parse('$baseUrl/galleries/$id'),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
