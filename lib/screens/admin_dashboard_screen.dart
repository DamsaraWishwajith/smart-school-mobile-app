import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/admin_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardMetrics();
    });
  }

  Future<void> _loadDashboardMetrics() async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    await adminProvider.loadUsers();
    await adminProvider.loadTeachers();
    await adminProvider.loadAttendanceRecords();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final adminProvider = Provider.of<AdminProvider>(context);
    final user = authProvider.user;

    final totalUsers = adminProvider.users.length;
    final totalTeachers = adminProvider.teachers.length;
    final totalStudents = adminProvider.users.where((u) => u.role == 'student').length;

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
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFF0077BE),
                child: Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Administrator Mode',
                  style: TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.bold),
                ),
                Text(
                  user?.name ?? 'Admin Portal',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout_rounded,
              color: Colors.redAccent,
            ),
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildBackgroundShapes(),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadDashboardMetrics,
              color: const Color(0xFF0077BE),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Management Hub',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const Text(
                      'System metrics and configuration shortcuts',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Metrics row
                    _buildMetricsSection(
                      totalUsers: totalUsers,
                      totalTeachers: totalTeachers,
                      totalStudents: totalStudents,
                      isLoading: adminProvider.isLoading,
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      'Core Modules',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 15),

                    _buildAdminGrid(),
                    const SizedBox(height: 100),
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

  Widget _buildMetricsSection({
    required int totalUsers,
    required int totalTeachers,
    required int totalStudents,
    required bool isLoading,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'Users',
            value: isLoading ? '...' : totalUsers.toString(),
            icon: Icons.people_outline_rounded,
            color: const Color(0xFF0077BE),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            title: 'Teachers',
            value: isLoading ? '...' : totalTeachers.toString(),
            icon: Icons.school_outlined,
            color: const Color(0xFF9C27B0),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            title: 'Students',
            value: isLoading ? '...' : totalStudents.toString(),
            icon: Icons.face_rounded,
            color: const Color(0xFF4CAF50),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.15,
      children: [
        _buildGridItem(
          'Users Directory',
          Icons.people_rounded,
          const Color(0xFF0077BE),
          route: '/admin-users',
          subtitle: 'Search and inspect users',
        ),
        // _buildGridItem(
        //   'Academic Staff',
        //   Icons.school_rounded,
        //   const Color(0xFF9C27B0),
        //   route: '/admin-teachers',
        //   subtitle: 'Manage teachers details',
        // ),
        _buildGridItem(
          'Student Attendance',
          Icons.assignment_ind_rounded,
          const Color(0xFF4CAF50),
          route: '/admin-student-attendance',
          subtitle: 'View student logs',
        ),
        _buildGridItem(
          'Teacher Attendance',
          Icons.badge_rounded,
          const Color(0xFFE91E63),
          route: '/admin-teacher-attendance',
          subtitle: 'View teacher logs',
        ),
        _buildGridItem(
          'Messaging Hub',
          Icons.chat_rounded,
          const Color(0xFFE91E63),
          route: '/messaging',
          subtitle: 'Chat with staff & students',
        ),
        _buildGridItem(
          'Emergency Alert',
          Icons.shield_outlined,
          const Color(0xFFD32F2F),
          route: '/emergency-alerts',
          subtitle: 'Broadcast emergency alarms',
        ),
        _buildGridItem(
          'Event Gallery',
          Icons.photo_library_rounded,
          const Color(0xFF0288D1),
          route: '/gallery',
          subtitle: 'View event photo albums',
        ),
        _buildGridItem(
          'Notices',
          Icons.campaign_rounded,
          const Color(0xFF4CAF50),
          route: '/notices',
          subtitle: 'Publish & view announcements',
        ),
        _buildGridItem(
          'Events',
          Icons.event_note_rounded,
          const Color(0xFF9C27B0),
          route: '/events',
          subtitle: 'School calendar & events',
        ),
        _buildGridItem(
          'Complaints Desk',
          Icons.warning_amber_rounded,
          const Color(0xFF607D8B),
          route: '/complaints',
          subtitle: 'Review reported concerns',
        ),
        _buildGridItem(
          'Meal Plan',
          Icons.restaurant_menu_rounded,
          const Color(0xFFFF7043),
          route: '/meal-plan',
          subtitle: 'Manage daily meal schedule',
        ),
      ],
    );
  }

  Widget _buildGridItem(
    String title,
    IconData icon,
    Color color, {
    required String route,
    required String subtitle,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: _buildGlassCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.black45,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(180),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }
}
