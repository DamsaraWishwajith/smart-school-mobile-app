import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/student_provider.dart';
import '../providers/auth_provider.dart';
import '../models/simple_timetable_model.dart';

class TeacherScheduleItem {
  final String startTime;
  final String endTime;
  final String subject;
  final String grade;

  TeacherScheduleItem({
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.grade,
  });
}

class TeacherTimetableScreen extends StatefulWidget {
  const TeacherTimetableScreen({super.key});

  @override
  State<TeacherTimetableScreen> createState() => _TeacherTimetableScreenState();
}

class _TeacherTimetableScreenState extends State<TeacherTimetableScreen> {
  int _selectedDayIndex = 0;

  final List<String> _fullDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];
  final List<String> _shortDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    if (now.weekday >= 1 && now.weekday <= 5) {
      _selectedDayIndex = now.weekday - 1;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTimetable());
  }

  Future<void> _loadTimetable() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;
    if (userId == null) return;

    final studentProvider =
        Provider.of<StudentProvider>(context, listen: false);
    // Use the dedicated teacher timetable endpoint — returns only this teacher's rows
    await studentProvider.loadTeacherTimetable(userId);
  }

  Color _getSubjectColor(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('math')) return const Color(0xFF0077BE);
    if (s.contains('sci')) return const Color(0xFF4CAF50);
    if (s.contains('eng')) return const Color(0xFFE91E63);
    if (s.contains('hist')) return const Color(0xFF795548);
    if (s.contains('geo')) return const Color(0xFF009688);
    if (s.contains('phys')) return const Color(0xFF3F51B5);
    if (s.contains('chem')) return const Color(0xFF9C27B0);
    if (s.contains('bio')) return const Color(0xFFFF9800);
    if (s.contains('art')) return const Color(0xFFFF5722);
    if (s.contains('health')) return const Color(0xFF00ACC1);
    if (s.contains('interval') || s.contains('break')) {
      return const Color(0xFF90A4AE);
    }
    return const Color(0xFF607D8B);
  }

  IconData _getSubjectIcon(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('math')) return Icons.calculate_rounded;
    if (s.contains('sci')) return Icons.science_rounded;
    if (s.contains('eng')) return Icons.menu_book_rounded;
    if (s.contains('hist')) return Icons.history_edu_rounded;
    if (s.contains('geo')) return Icons.public_rounded;
    if (s.contains('phys')) return Icons.bolt_rounded;
    if (s.contains('chem')) return Icons.biotech_rounded;
    if (s.contains('bio')) return Icons.eco_rounded;
    if (s.contains('art')) return Icons.palette_rounded;
    if (s.contains('health')) return Icons.favorite_rounded;
    if (s.contains('interval') || s.contains('break')) {
      return Icons.free_breakfast_rounded;
    }
    return Icons.school_rounded;
  }

  List<TeacherScheduleItem> _getScheduleForDay(
      List<SimpleTimetableModel> timetables, String day) {
    // New endpoint returns only this teacher's rows.
    // Filter all rows matching this day.
    final dayRecords = timetables.where(
      (t) => t.day.trim().toLowerCase() == day.trim().toLowerCase(),
    );

    final List<TeacherScheduleItem> items = [];

    for (final dayRecord in dayRecords) {
      for (final slot in dayRecord.slots) {
        final rawVal = slot.subject.trim();
        if (rawVal.isEmpty) continue;

        String subjectName = rawVal;
        String slotGrade = 'Class';

        // Extract grade from parentheses: e.g. "Mathematics (Grade 6)"
        if (rawVal.contains('(') && rawVal.contains(')')) {
          final start = rawVal.indexOf('(');
          final end = rawVal.indexOf(')');
          if (end > start) {
            slotGrade = rawVal.substring(start + 1, end).trim();
            subjectName = rawVal.substring(0, start).trim();
          }
        }

        items.add(TeacherScheduleItem(
          startTime: slot.startTime,
          endTime: slot.endTime,
          subject: subjectName,
          grade: slotGrade,
        ));
      }
    }

    // Sort by start time
    items.sort((a, b) => _parseTime(a.startTime).compareTo(_parseTime(b.startTime)));
    return items;
  }

  int _parseTime(String timeStr) {
    try {
      final clean = timeStr.trim().toUpperCase();
      final isPm = clean.contains('PM');
      final isAm = clean.contains('AM');
      final parts =
          clean.replaceAll('AM', '').replaceAll('PM', '').trim().split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      if (isPm && hour < 12) hour += 12;
      if (isAm && hour == 12) hour = 0;
      return hour * 60 + minute;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0077BE),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Timetable',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0077BE)),
            onPressed: _loadTimetable,
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildBackgroundShapes(),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),
                _buildDaySelector(),
                const SizedBox(height: 16),
                Expanded(
                  child: Consumer<StudentProvider>(
                    builder: (context, provider, _) {
                      if (provider.isLoading) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF0077BE),
                          ),
                        );
                      }

                      if (provider.error != null) {
                        return _buildErrorWidget(provider.error!);
                      }

                      final scheduleItems = _getScheduleForDay(
                        provider.simpleTimetable,
                        _fullDays[_selectedDayIndex],
                      );

                      if (scheduleItems.isEmpty) {
                        return _buildEmptyWidget(
                          'No timetable scheduled for you on ${_fullDays[_selectedDayIndex]}',
                        );
                      }

                      return _buildScheduleList(scheduleItems);
                    },
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
            width: 300,
            height: 300,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF00B4DB), Color(0xFF0077BE)],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: -100,
          child: Container(
            width: 250,
            height: 250,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDaySelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(5, (index) {
          final isSelected = _selectedDayIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDayIndex = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0077BE) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? const Color(0xFF0077BE).withAlpha(80)
                        : Colors.black.withAlpha(10),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                _shortDays[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildScheduleList(List<TeacherScheduleItem> items) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Schedule for  ${_fullDays[_selectedDayIndex]}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          ...items.map((item) => _buildScheduleCard(item)),
          const SizedBox(height: 20),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(TeacherScheduleItem item) {
    String subjectText = item.subject;
    String gradeText = item.grade;

    if (subjectText.contains('(') && subjectText.contains(')')) {
      final startIndex = subjectText.indexOf('(');
      final endIndex = subjectText.indexOf(')');
      if (endIndex > startIndex) {
        final extractedGrade =
            subjectText.substring(startIndex + 1, endIndex).trim();
        subjectText = subjectText.substring(0, startIndex).trim();
        if (extractedGrade.isNotEmpty) {
          gradeText = extractedGrade;
        }
      }
    }

    if (gradeText.toLowerCase().startsWith('teacher:')) {
      gradeText = 'Assigned Class';
    }

    final isInterval =
        subjectText.toLowerCase().contains('interval') ||
        subjectText.toLowerCase().contains('break');
    final color = _getSubjectColor(subjectText);
    final icon = _getSubjectIcon(subjectText);

    if (isInterval) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(160),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(Icons.free_breakfast_rounded,
                color: Colors.grey.shade500, size: 18),
            const SizedBox(width: 12),
            Text(
              '${item.startTime} – ${item.endTime}',
              style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            Text(
              subjectText,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(220),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Timeline Bullet Dot & Subject Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),

            // Subject Name & Grade Pill
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subjectText,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0077BE).withAlpha(15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      gradeText,
                      style: const TextStyle(
                        color: Color(0xFF0077BE),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Time Badge Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                '${item.startTime} – ${item.endTime}',
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0077BE).withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_month_outlined,
                size: 56,
                color: Color(0xFF0077BE),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadTimetable,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh Timetable'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0077BE),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 56, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadTimetable,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0077BE),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(200),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _legendItem('Math', const Color(0xFF0077BE)),
          _legendItem('Science', const Color(0xFF4CAF50)),
          _legendItem('English', const Color(0xFFE91E63)),
          _legendItem('Other', const Color(0xFF9C27B0)),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    );
  }
}
