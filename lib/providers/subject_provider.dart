import 'package:flutter/material.dart';
import '../models/subject_model.dart';
import '../services/api_service.dart';

class SubjectProvider extends ChangeNotifier {
  List<SubjectModel> _subjects = [];
  bool _isLoading = false;
  String? _error;

  List<SubjectModel> get subjects => _subjects;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchSubjects({int? userId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiServices.getSubjects(userId: userId);
      if (response['success'] == true) {
        final dynamic rawData = response['data'];
        List<dynamic> dataList = [];

        if (rawData is List) {
          dataList = rawData;
        } else if (rawData is Map && rawData['data'] is List) {
          dataList = rawData['data'] as List;
        } else if (rawData is Map && rawData['success'] == true && rawData['data'] is List) {
          // Handle double-wrapped response if necessary
          dataList = rawData['data'] as List;
        }

        _subjects = dataList
            .map((json) => SubjectModel.fromJson(json))
            .where((s) => s.subjectName != null)
            .toList();
      } else {
        _error = response['message'];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper to group by subject name (all subjects)
  Map<String, List<SubjectModel>> get subjectsGroupedByName {
    Map<String, List<SubjectModel>> grouped = {};
    for (var subject in _subjects) {
      if (subject.subjectName != null) {
        if (!grouped.containsKey(subject.subjectName)) {
          grouped[subject.subjectName!] = [];
        }
        grouped[subject.subjectName!]!.add(subject);
      }
    }
    return grouped;
  }

  // Helper to group by subject name but ONLY for subjects with uploaded materials or assignments
  Map<String, List<SubjectModel>> get materialsGroupedByName {
    Map<String, List<SubjectModel>> grouped = {};
    for (var subject in _subjects) {
      if (subject.subjectName != null && ((subject.pdf != null && subject.pdf!.isNotEmpty) || (subject.assignment != null && subject.assignment!.isNotEmpty))) {
        if (!grouped.containsKey(subject.subjectName)) {
          grouped[subject.subjectName!] = [];
        }
        grouped[subject.subjectName!]!.add(subject);
      }
    }
    return grouped;
  }
}
