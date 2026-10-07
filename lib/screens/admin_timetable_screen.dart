import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../providers/student_provider.dart';
import '../models/simple_timetable_model.dart';

class AdminTimetableScreen extends StatefulWidget {
  const AdminTimetableScreen({super.key});

  @override
  State<AdminTimetableScreen> createState() => _AdminTimetableScreenState();
}

class _AdminTimetableScreenState extends State<AdminTimetableScreen> {
  String _selectedDay = 'Monday';
  String _selectedGrade = 'Grade 1';

  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  final List<String> _grades = [
    'Grade 1',
    'Grade 2',
    'Grade 3',
    'Grade 4',
    'Grade 5',
    'Grade 6',
    'Grade 7',
    'Grade 8',
    'Grade 9',
    'Grade 10',
    'Grade 11',
    'Grade 12',
  ];

  final Map<String, String> _slotsMetadata = {
    't_8_00_8_30': '08:00 AM – 08:30 AM',
    't_8_30_9_00': '08:30 AM – 09:00 AM',
    't_9_00_9_30': '09:00 AM – 09:30 AM',
    't_9_30_10_00': '09:30 AM – 10:00 AM',
    't_10_00_10_30': '10:00 AM – 10:30 AM',
    't_10_30_11_00': '10:30 AM – 11:00 AM',
    't_11_00_11_30': '11:00 AM – 11:30 AM',
    't_11_30_12_00': '11:30 AM – 12:00 PM',
    't_12_00_12_30': '12:00 PM – 12:30 PM',
    't_12_30_1_00': '12:30 PM – 01:00 PM',
    't_1_00_1_30': '01:00 PM – 01:30 PM',
  };

  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    // Initialize text controllers
    for (var key in _slotsMetadata.keys) {
      _controllers[key] = TextEditingController();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTimetables();
    });
  }

  Future<void> _loadTimetables() async {
    // Fetch current timetables so we can prefill
    await Provider.of<StudentProvider>(context, listen: false).loadSimpleTimetable();
    _prefillFields();
  }

  void _prefillFields() {
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    
    // Find the record for selected day and grade
    SimpleTimetableModel? match;
    try {
      match = studentProvider.simpleTimetable.firstWhere((t) {
        final dayMatch = t.day.trim().toLowerCase() == _selectedDay.trim().toLowerCase();
        final gradeMatch = t.grade.trim().toLowerCase() == _selectedGrade.trim().toLowerCase();
        return dayMatch && gradeMatch;
      });
    } catch (_) {}

    // Clear controllers first
    for (var controller in _controllers.values) {
      controller.clear();
    }

    // Prefill if matched
    if (match != null) {
      for (var slot in match.slots) {
        if (_controllers.containsKey(slot.key)) {
          _controllers[slot.key]!.text = slot.subject;
        }
      }
    }
  }

  Future<void> _saveTimetable() async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    
    final Map<String, dynamic> payload = {
      'day': _selectedDay,
      'grade': _selectedGrade,
    };

    // Gather values
    for (var entry in _controllers.entries) {
      if (entry.value.text.isNotEmpty) {
        payload[entry.key] = entry.value.text.trim();
      }
    }

    final success = await adminProvider.saveTimetable(payload);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Timetable saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Reload list
        _loadTimetables();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(adminProvider.error ?? 'Failed to save timetable'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFFFF9800),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Manage Timetable',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _buildBackgroundShapes(),
          SafeArea(
            child: Column(
              children: [
                _buildSelectors(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      children: [
                        _buildTimetableForm(),
                        const SizedBox(height: 24),
                        adminProvider.isLoading
                            ? const CircularProgressIndicator(color: Color(0xFFFF9800))
                            : Container(
                                width: double.infinity,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFF9800), Colors.orangeAccent],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.withAlpha(76),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _saveTimetable,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: const Text(
                                    'SAVE TIMETABLE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundShapes() {
    return Stack(
      children: [
        Positioned(
          top: -50,
          right: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectors() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(180),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Row(
              children: [
                // Day Selector
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Day',
                        style: TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedDay,
                            isExpanded: true,
                            items: _days.map((day) {
                              return DropdownMenuItem(value: day, child: Text(day, style: const TextStyle(fontSize: 13)));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedDay = val;
                                  _prefillFields();
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Grade Selector
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Grade',
                        style: TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedGrade,
                            isExpanded: true,
                            items: _grades.map((grade) {
                              return DropdownMenuItem(value: grade, child: Text(grade, style: const TextStyle(fontSize: 13)));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedGrade = val;
                                  _prefillFields();
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimetableForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Time Slots Configuration',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        ..._slotsMetadata.entries.map((entry) => _buildSlotInputField(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildSlotInputField(String key, String timeLabel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(180),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Row(
              children: [
                // Time label
                Expanded(
                  flex: 2,
                  child: Text(
                    timeLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                // Subject Input
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: TextField(
                      controller: _controllers[key],
                      decoration: const InputDecoration(
                        hintText: 'e.g. Maths, Science, Break',
                        hintStyle: TextStyle(color: Colors.black26, fontSize: 12),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
