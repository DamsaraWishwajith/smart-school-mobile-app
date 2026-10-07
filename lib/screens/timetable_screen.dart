import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/student_provider.dart';
import '../models/simple_timetable_model.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
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
    // Auto-select today's day if it's a weekday
    final now = DateTime.now();
    if (now.weekday >= 1 && now.weekday <= 5) {
      _selectedDayIndex = now.weekday - 1;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTimetable());
  }

  Future<void> _loadTimetable() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final studentProvider = Provider.of<StudentProvider>(
      context,
      listen: false,
    );
    final userGrade = authProvider.user?.student?.grade;
    await studentProvider.loadSimpleTimetable(userGrade: userGrade);
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
    if (s.contains('interval') || s.contains('break')) {
      return Icons.free_breakfast_rounded;
    }
    return Icons.school_rounded;
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
          'Class Timetable',
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
                const SizedBox(height: 8),
                _buildDaySelector(),
                const SizedBox(height: 10),
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

                      if (provider.simpleTimetable.isEmpty) {
                        return _buildEmptyWidget('No timetable data found');
                      }

                      final dayData = provider.getSimpleTimetableForDay(
                        _fullDays[_selectedDayIndex],
                      );

                      if (dayData == null) {
                        return _buildEmptyWidget(
                          'No classes on ${_fullDays[_selectedDayIndex]}',
                        );
                      }

                      return _buildSlotList(dayData);
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

  Widget _buildSlotList(SimpleTimetableModel dayData) {
    // Separate intervals from actual subjects
    final regular =
        dayData.slots
            .where(
              (s) =>
                  !s.subject.toLowerCase().contains('interval') &&
                  !s.subject.toLowerCase().contains('break'),
            )
            .toList();
    final hasIntervals =
        dayData.slots.length != regular.length; // for reference

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grade badge
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0077BE).withAlpha(20),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF0077BE).withAlpha(60),
                ),
              ),
              child: Text(
                dayData.grade,
                style: const TextStyle(
                  color: Color(0xFF0077BE),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),

          ...dayData.slots.map((slot) => _buildSlotCard(slot)),

          const SizedBox(height: 20),
          _buildLegend(),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildSlotCard(TimeSlot slot) {
    final isInterval =
        slot.subject.toLowerCase().contains('interval') ||
        slot.subject.toLowerCase().contains('break');
    final color = _getSubjectColor(slot.subject);

    if (isInterval) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withAlpha(60)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.free_breakfast_rounded,
              color: Colors.grey.shade500,
              size: 16,
            ),
            const SizedBox(width: 10),
            Text(
              '${slot.startTime} – ${slot.endTime}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(width: 10),
            Text(
              slot.subject,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(200),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withAlpha(255)),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(20),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Time column
                SizedBox(
                  width: 85,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        slot.startTime,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        slot.endTime,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                // Accent bar
                Container(
                  width: 3,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 14),
                // Subject
                Expanded(
                  child: Text(
                    slot.subject,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                // Icon badge
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getSubjectIcon(slot.subject),
                    color: color,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDaySelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children:
            List.generate(
              _shortDays.length,
              (i) => _buildDayChip(i),
            ).toList(),
      ),
    );
  }

  Widget _buildDayChip(int index) {
    final isSelected = _selectedDayIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedDayIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color:
              isSelected ? const Color(0xFF0077BE) : Colors.white.withAlpha(180),
          borderRadius: BorderRadius.circular(14),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: const Color(0xFF0077BE).withAlpha(80),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : [],
        ),
        child: Text(
          _shortDays[index],
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black54,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: Colors.red.withAlpha(120),
            ),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadTimetable,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0077BE),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy_rounded,
            size: 80,
            color: Colors.grey.withAlpha(80),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    final items = [
      ('Mathematics', const Color(0xFF0077BE)),
      ('Science', const Color(0xFF4CAF50)),
      ('English', const Color(0xFFE91E63)),
      ('History', const Color(0xFF795548)),
      ('Geography', const Color(0xFF009688)),
      ('Physics', const Color(0xFF3F51B5)),
      ('Chemistry', const Color(0xFF9C27B0)),
      ('Biology', const Color(0xFFFF9800)),
      ('Art', const Color(0xFFFF5722)),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(180),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Subject Colors',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children:
                items
                    .map(
                      (e) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: e.$2,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(e.$1, style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    )
                    .toList(),
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
                colors: [Color(0xFF00B4DB), Color(0xFF0077BE)],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          left: -50,
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
}
