import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/student_provider.dart';
import '../models/attendance_model.dart';
import 'package:intl/intl.dart';
import '../utils/pdf_helper.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  int _selectedFilter = 0;
  DateTime? _selectedDate;
  bool _showMonthlyLogs = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now(); // Auto-select today
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);

    if (authProvider.user != null) {
      await studentProvider.loadUserAttendance(authProvider.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);

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
          'Attendance Record',
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
            child: studentProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFilterToggle(),
                          const SizedBox(height: 25),
                          if (studentProvider.error != null)
                            Container(
                              padding: const EdgeInsets.all(15),
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: Colors.red.withAlpha(30),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.red.withAlpha(100)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.red),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Error: ${studentProvider.error}',
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // Debug info (Remove later)
                          Text(
                            'User ID: ${Provider.of<AuthProvider>(context, listen: false).user?.id ?? "Not Found"}',
                            style: const TextStyle(fontSize: 10, color: Colors.black26),
                          ),
                          const SizedBox(height: 5),
                          _buildSummaryCard(studentProvider.attendance),
                          const SizedBox(height: 30),
                          Text(
                            _selectedFilter == 0 ? 'This Week' : 'This Month',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 15),
                          _selectedFilter == 0
                              ? _buildWeeklyView(studentProvider.attendance)
                              : _buildMonthlyView(studentProvider.attendance),
                          if (_selectedFilter == 0) ...[
                            const SizedBox(height: 25),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Attendance Logs",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            _buildQRLogs(studentProvider.attendance),
                          ],
                        ],
                      ),
                    ),
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
          left: -50,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF00B4DB), Color(0xFF0077BE)],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 50,
          right: -100,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterToggle() {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(150),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withAlpha(200)),
      ),
      child: Row(
        children: [
          _buildFilterButton('This Week', 0),
          _buildFilterButton('This Month', 1),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String title, int index) {
    bool isSelected = _selectedFilter == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedFilter = index;
          if (index == 0) {
            _selectedDate = DateTime.now();
            _showMonthlyLogs = false;
          } else {
            _selectedDate = null;
          }
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0077BE) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black54,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(List<AttendanceModel> logs) {
    double percentage = 0;
    String statusText = '';
    bool isLowAttendance = false;
    
    if (logs.isNotEmpty) {
      final now = DateTime.now();
      final relevantLogs = logs.where((log) {
        if (_selectedFilter == 0) {
          // This week
          return log.date.isAfter(now.subtract(const Duration(days: 7)));
        } else {
          // This month
          return log.date.month == now.month && log.date.year == now.year;
        }
      }).toList();

      int presentDays = relevantLogs.length;
      int totalDays = _selectedFilter == 0 ? 5 : 22; // Assuming 5 school days/week, 22/month
      percentage = (presentDays / totalDays).clamp(0.0, 1.0);
      isLowAttendance = percentage < 0.75;
      statusText = 'Present for $presentDays out of $totalDays days.';
    } else {
      statusText = 'No attendance records found.';
      isLowAttendance = true;
    }

    final themeColor = isLowAttendance ? const Color(0xFFD32F2F) : const Color(0xFF4CAF50);

    return Column(
      children: [
        if (isLowAttendance) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFEF5350), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withAlpha(30),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFD32F2F), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '⚠️ LOW ATTENDANCE WARNING',
                        style: TextStyle(
                          color: Color(0xFFD32F2F),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Your attendance rate (${(percentage * 100).toInt()}%) is below the required 75% threshold. Regular attendance is required.',
                        style: const TextStyle(
                          color: Color(0xFFC62828),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        _buildGlassCard(
          borderColor: isLowAttendance ? const Color(0xFFEF5350) : null,
          backgroundColor: isLowAttendance ? const Color(0xFFFFEBEE).withAlpha(180) : null,
          child: Row(
            children: [
              _buildProgressCircle(
                percentage,
                '${(percentage * 100).toInt()}%',
                color: themeColor,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(
                          _selectedFilter == 0 ? 'Weekly Status' : 'Monthly Status',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: themeColor,
                          ),
                        ),
                        if (isLowAttendance)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD32F2F).withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFD32F2F).withAlpha(80)),
                            ),
                            child: const Text(
                              'LOW ATTENDANCE',
                              style: TextStyle(
                                color: Color(0xFFD32F2F),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      statusText,
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCircle(double value, String label, {Color color = const Color(0xFF4CAF50)}) {
    return SizedBox(
      height: 70,
      width: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: 6,
            backgroundColor: color.withAlpha(30),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color == const Color(0xFF4CAF50) ? Colors.black : color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyView(List<AttendanceModel> logs) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    
    return _buildGlassCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(5, (index) {
          final date = monday.add(Duration(days: index));
          final isPresent = logs.any((log) => 
            log.date.day == date.day && 
            log.date.month == date.month && 
            log.date.year == date.year
          );
          
          return _buildDayCircle(
            DateFormat('E').format(date),
            date.day.toString(),
            isPresent,
            isToday: date.day == now.day && date.month == now.month,
            isSelected: _selectedDate != null && 
                       _selectedDate!.day == date.day && 
                       _selectedDate!.month == date.month,
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
            },
          );
        }),
      ),
    );
  }

  Widget _buildDayCircle(String d, String dt, bool p, 
      {bool isToday = false, bool isSelected = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            d,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected 
                  ? const Color(0xFF0077BE) 
                  : (isToday ? const Color(0xFF0077BE).withOpacity(0.5) : Colors.black54),
            ),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF0077BE).withOpacity(0.1) : Colors.transparent,
              shape: BoxShape.circle,
              border: isSelected ? Border.all(color: const Color(0xFF0077BE), width: 1) : null,
            ),
            child: Text(
              dt, 
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF0077BE) : Colors.black,
              )
            ),
          ),
          const SizedBox(height: 5),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: p ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyView(List<AttendanceModel> logs) {
    final now = DateTime.now();
    final monthLogs = logs.where((log) => 
      log.date.month == now.month && log.date.year == now.year
    ).toList();
    final presentDays = monthLogs.length;

    return Column(
      children: [
        _buildStatRow('Total School Days', '22 Days', const Color(0xFF0077BE)),
        const SizedBox(height: 12),
        _buildStatRow('Days Present', '$presentDays Days', const Color(0xFF4CAF50)),
        const SizedBox(height: 12),
        _buildStatRow('Days Absent', '${22 - presentDays} Days', const Color(0xFFD32F2F)),
        const SizedBox(height: 30),
        Text('Monthly Logs',style: TextStyle(fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),),),
        SizedBox(
          height: 20,
        ),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              if (authProvider.user != null) {
                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Generating PDF Report...')),
                );
                
                await PdfHelper.generateAttendanceReport(
                  user: authProvider.user!,
                  logs: logs,
                  month: DateFormat('MMMM').format(DateTime.now()),
                  year: DateTime.now().year.toString(),
                );
              }
            },
            icon: const Icon(Icons.download_rounded, color: Color(0xFF0077BE)),
            label: const Text('Download Monthly Report'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF0077BE)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogCard(AttendanceModel log) {
    return _buildGlassCard(
      child: Column(
        children: [
          if (log.entryTime != null)
            _buildTimelineTile(
              log.entryTime!,
              'Entry Recorded (${DateFormat('MMM dd').format(log.date)})',
              log.gate ?? '',
              Icons.login,
              const Color(0xFF4CAF50),
            ),
          if (log.entryTime != null && log.exitTime != null)
            const SizedBox(height: 10),
          if (log.exitTime != null)
            _buildTimelineTile(
              log.exitTime!,
              'Exit Recorded (${DateFormat('MMM dd').format(log.date)})',
              log.gate ?? '',
              Icons.logout,
              const Color(0xFFFF9800),
            ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return _buildGlassCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildQRLogs(List<AttendanceModel> logs) {
    if (_selectedDate == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'Select a day to view logs',
            style: TextStyle(color: Colors.black45, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    var filteredLogs = logs.where((log) => 
      log.date.day == _selectedDate!.day && 
      log.date.month == _selectedDate!.month && 
      log.date.year == _selectedDate!.year
    ).toList();

    if (filteredLogs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'No logs for ${DateFormat('MMM dd').format(_selectedDate!)}',
            style: const TextStyle(color: Colors.black45),
          ),
        ),
      );
    }

    return Column(
      children: filteredLogs.map((log) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildGlassCard(
            child: Column(
              children: [
                if (log.entryTime != null)
                  _buildTimelineTile(
                    log.entryTime!,
                    'Entry Recorded (${DateFormat('MMM dd').format(log.date)})',
                    log.gate ?? '',
                    Icons.login,
                    const Color(0xFF4CAF50),
                  ),
                if (log.entryTime != null && log.exitTime != null)
                  const SizedBox(height: 10),
                if (log.exitTime != null)
                  _buildTimelineTile(
                    log.exitTime!,
                    'Exit Recorded (${DateFormat('MMM dd').format(log.date)})',
                    log.gate ?? '',
                    Icons.logout,
                    const Color(0xFFFF9800),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimelineTile(
    String t,
    String title,
    String sub,
    IconData i,
    Color c,
  ) {
    return Row(
      children: [
        Text(
          t,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 15),
        Icon(i, size: 18, color: c),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              sub,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGlassCard({
    required Widget child,
    Color? borderColor,
    Color? backgroundColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white.withAlpha(150),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor ?? Colors.white.withAlpha(200),
              width: borderColor != null ? 1.5 : 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
