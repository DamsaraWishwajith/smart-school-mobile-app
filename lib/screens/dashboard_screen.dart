import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/student_provider.dart';
import '../models/attendance_model.dart';

class CompleteStudentDashboard extends StatefulWidget {
  const CompleteStudentDashboard({super.key});

  @override
  State<CompleteStudentDashboard> createState() =>
      _CompleteStudentDashboardState();
}

class _CompleteStudentDashboardState extends State<CompleteStudentDashboard> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final studentProvider = Provider.of<StudentProvider>(
      context,
      listen: false,
    );

    await authProvider.loadUser();
    final user = authProvider.user;

    if (user != null) {
      await studentProvider.loadDashboard(user.student?.id ?? 0);
      await studentProvider.loadUserAttendance(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final studentProvider = Provider.of<StudentProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0077BE).withAlpha(100),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF0077BE),
                child: Text(
                  user?.name.isNotEmpty == true ? user!.name[0] : 'N',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome,',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                Text(
                  user?.name ?? 'Narmada',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // IconButton(
          //   icon: const Icon(
          //     Icons.qr_code_rounded,
          //     color: Color(0xFF0077BE),
          //   ),
          //   onPressed: () {
          //     Navigator.pushNamed(context, '/my-qr');
          //   },
          // ),
          IconButton(
            icon: const Icon(
              Icons.notifications_active,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildBackgroundShapes(),
          SafeArea(
            child: studentProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Daily Overview',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildLowAttendanceWarningCard(studentProvider),
                        _buildSafetyCard(studentProvider),
                        const SizedBox(height: 20),
                        _buildAIBanner(),
                        const SizedBox(height: 25),
                        // const Text(
                        //   'Academic Tools',
                        //   style: TextStyle(
                        //     fontSize: 20,
                        //     fontWeight: FontWeight.bold,
                        //     color: Color(0xFF1A1A1A),
                        //   ),
                        // ),
                        const SizedBox(height: 15),
                        _buildAcademicGrid(),
                        const SizedBox(height: 25),
                        // const Text(
                        //   'Communication Hub',
                        //   style: TextStyle(
                        //     fontSize: 20,
                        //     fontWeight: FontWeight.bold,
                        //     color: Color(0xFF1A1A1A),
                        //   ),
                        // ),
                        const SizedBox(height: 15),
                        _buildCommGrid(),
                        const SizedBox(height: 15),
                        // _buildFullWidthGridItem(
                        //   'Emergency Alerts',
                        //   Icons.shield_outlined,
                        //   const Color(0xFFD32F2F),
                        //   route: '/emergency-alerts',
                        // ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white.withAlpha(230),
        shape: const CircularNotchedRectangle(),
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              GestureDetector(
                onTap: () => setState(() => _selectedIndex = 0),
                child: Icon(
                  Icons.home_rounded,
                  color: _selectedIndex == 0
                      ? const Color(0xFF0077BE)
                      : Colors.black38,
                  size: 28,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/gallery');
                },
                child: const Icon(
                  Icons.photo_library_rounded,
                  color: Colors.black38,
                  size: 26,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/profile');
                },
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.black38,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildLowAttendanceWarningCard(StudentProvider provider) {
    if (provider.attendance.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    final recentLogs = provider.attendance.where((log) =>
        log.date.month == now.month && log.date.year == now.year
    ).toList();

    int presentDays = recentLogs.length;
    int totalDays = 22; // Assuming ~22 school days/month
    double percentage = (presentDays / totalDays).clamp(0.0, 1.0);

    if (percentage >= 0.75) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/attendance'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEF5350), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withAlpha(40),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFD32F2F),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚠️ Low Attendance Warning',
                    style: TextStyle(
                      color: Color(0xFFD32F2F),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Your attendance is ${(percentage * 100).toInt()}% (below 75% threshold). Tap to view details.',
                    style: const TextStyle(
                      color: Color(0xFFC62828),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFD32F2F), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyCard(StudentProvider provider) {
    AttendanceModel? latestAttendance;
    if (provider.attendance.isNotEmpty) {
      latestAttendance = provider.attendance.first;
    }

    bool isInside = latestAttendance?.exitTime == null && latestAttendance?.entryTime != null;
    String status = isInside ? 'Inside School' : 'Outside School';
    if (latestAttendance == null) status = 'No records today';

    return _buildGlassCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isInside ? const Color(0xFF4CAF50) : Colors.orange).withAlpha(40),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              isInside ? Icons.security_rounded : Icons.door_front_door_rounded,
              color: isInside ? const Color(0xFF4CAF50) : Colors.orange,
              size: 30,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Safety Status: $status',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  latestAttendance != null
                      ? '${isInside ? 'Arrived' : 'Departed'} at ${isInside ? latestAttendance.entryTime : latestAttendance.exitTime}  ${latestAttendance.gate ?? ''}'
                      : 'No entry records for today.',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(
          colors: [Color(0xFF0077BE), Color(0xFF00B4DB)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'AI Performance Insight',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Personalized academic performance insights, strengths & recommendations.',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/ai-report');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0077BE),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('View Full Report'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2,
      children: [
        _buildGridItem(
          'Attendance',
          Icons.fact_check_rounded,
          const Color(0xFF4CAF50),
          route: '/attendance',
        ),
        _buildGridItem(
          'Timetable',
          Icons.calendar_month_rounded,
          const Color(0xFF0077BE),
          route: '/timetable',
        ),
        _buildGridItem(
          'Materials',
          Icons.menu_book_rounded,
          const Color(0xFF9C27B0),
          route: '/materials',
        ),
        _buildGridItem(
          'Fees',
          Icons.account_balance_wallet_rounded,
          const Color(0xFFFF9800),
          route: '/fees',
        ),
        _buildGridItem(
          'Assignment Marks',
          Icons.assignment_turned_in_rounded,
          const Color(0xFFE91E63),
          route: '/student-results',
        ),
        _buildGridItem(
          'Final Exam Results',
          Icons.workspace_premium_rounded,
          const Color(0xFF0077BE),
          route: '/student-exams',
        ),
        _buildGridItem(
          'Meal Plan',
          Icons.restaurant_menu_rounded,
          const Color(0xFFFF7043),
          route: '/meal-plan',
        ),
      ],
    );
  }

  Widget _buildCommGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2,
      children: [
        _buildGridItem(
          'Messaging',
          Icons.chat_rounded,
          const Color(0xFF0077BE),
          route: '/messaging',
        ),
        _buildGridItem(
          'Notices',
          Icons.campaign_rounded,
          const Color(0xFFE91E63),
          route: '/notices',
        ),
        _buildGridItem(
          'Events',
          Icons.event_rounded,
          const Color(0xFF9C27B0),
          route: '/events',
        ),
        _buildGridItem(
          'Complaints',
          Icons.report_problem_rounded,
          const Color(0xFFFF9800),
          route: '/complaints',
        ),
      ],
    );
  }

  Widget _buildGridItem(
    String title,
    IconData icon,
    Color color, {
    required String route,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: _buildGlassCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(180),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }
}
