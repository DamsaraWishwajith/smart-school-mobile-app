import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/teacher_provider.dart';
import '../providers/student_provider.dart';
import '../providers/admin_provider.dart';
import '../models/attendance_model.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final teacherProvider = Provider.of<TeacherProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);

    final user = authProvider.user;
    if (user != null) {
      await studentProvider.loadUserAttendance(user.id);
    }

    await Future.wait([
      teacherProvider.loadSubmissions(),
      authProvider.refreshUserProfile(),
      Provider.of<AdminProvider>(context, listen: false).loadAttendanceRecords(),
    ]);
  }

  String _getFullPdfUrl(String pdfUrl) {
    if (pdfUrl.startsWith('http://') || pdfUrl.startsWith('https://')) {
      return pdfUrl;
    }
    // Prepend API base domain
    return 'https://eliteinternationalschool-live.us.stackstaging.com$pdfUrl';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final teacherProvider = Provider.of<TeacherProvider>(context);
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
                  user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'T',
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
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
                Text(
                  user?.name ?? 'Teacher',
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
          // IconButton(
          //   icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
          //   onPressed: () async {
          //     await authProvider.logout();
          //     if (mounted) {
          //       Navigator.pushReplacementNamed(context, '/login');
          //     }
          //   },
          // ),
        ],
      ),
      body: Stack(
        children: [
          _buildBackgroundShapes(),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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

                    // Safety Status Card
                    _buildSafetyCard(studentProvider),
                    _buildTeacherOwnLowAttendanceWarning(studentProvider),
                    const SizedBox(height: 25),

                    _buildFacultyQuickAccess(),
                    const SizedBox(height: 25),
                    
                  ],
                ),
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

  Widget _buildTeacherOwnLowAttendanceWarning(StudentProvider provider) {
    if (provider.attendance.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    final recentLogs = provider.attendance.where((log) =>
        log.date.month == now.month && log.date.year == now.year
    ).toList();

    int presentDays = recentLogs.length;
    int totalDays = 22; // ~22 working days/month
    double percentage = (presentDays / totalDays).clamp(0.0, 1.0);

    if (percentage >= 0.75) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/attendance'),
      child: Container(
        margin: const EdgeInsets.only(top: 15),
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

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'All Clean!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No student assignments have been submitted yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionsList(List<dynamic> submissions) {
    String getCleanFileName(String? path) {
      if (path == null || path.isEmpty) return 'No File';
      final uri = Uri.parse(path);
      String filename = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'document.pdf';
      if (filename.contains('/')) {
        filename = filename.split('/').last;
      }
      if (filename.contains('_')) {
        final parts = filename.split('_');
        if (parts.length > 1 && double.tryParse(parts[0]) != null) {
          return parts.sublist(1).join('_');
        }
      }
      return filename;
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: submissions.length,
      itemBuilder: (context, index) {
        final submission = submissions[index];
        final user = submission['user'];
        final studentName = user?['name'] ?? 'Unknown Student';
        final studentEmail = user?['email'] ?? '';
        final subject = submission['subject'];
        final subjectName = subject?['subject_name'] ?? 'General Subject';
        final grade = subject?['grade'] ?? 'N/A';
        final assignmentFile = subject?['assignment'] ?? '';
        final assignmentName = getCleanFileName(assignmentFile);
        final pdfUrl = submission['assignment_pdf'] ?? '';
        final submissionGrade = submission['grade'];
        final submissionFeedback = submission['feedback'];
        final submittedFileName = getCleanFileName(pdfUrl);
        final createdAt = submission['created_at'] != null 
            ? DateTime.tryParse(submission['created_at']) 
            : null;
        final dateString = createdAt != null 
            ? '${createdAt.day}/${createdAt.month}/${createdAt.year}' 
            : 'Just now';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(color: Colors.white),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Section: Student Profile Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFF0077BE).withOpacity(0.1),
                      child: Text(
                        studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                        style: const TextStyle(
                          color: Color(0xFF0077BE),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                studentName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0077BE).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  grade,
                                  style: const TextStyle(
                                    color: Color(0xFF0077BE),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            studentEmail,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      dateString,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              
              // Middle Section: Assignment & Submission Details
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.assignment_outlined, size: 18, color: Colors.black54),
                        const SizedBox(width: 8),
                        const Text(
                          'Subject / Course:',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          subjectName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                        ),
                      ],
                    ),
                    if (assignmentFile.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.folder_open_outlined, size: 18, color: Colors.black54),
                          const SizedBox(width: 8),
                          const Text(
                            'Assignment File:',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              assignmentName,
                              style: const TextStyle(fontSize: 13, color: Colors.black87, fontStyle: FontStyle.italic),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (submissionGrade != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star_border_rounded, size: 18, color: Colors.black54),
                          const SizedBox(width: 8),
                          const Text(
                            'Teacher Grade:',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              submissionGrade.toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (submissionFeedback != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Colors.black54),
                          const SizedBox(width: 8),
                          const Text(
                            'Feedback:',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              submissionFeedback.toString(),
                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    // Submitted PDF Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Submitted PDF',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  submittedFileName,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (pdfUrl.isNotEmpty)
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/pdf-viewer',
                                      arguments: {
                                        'url': _getFullPdfUrl(pdfUrl),
                                        'title': '$studentName - $subjectName',
                                      },
                                    );
                                  },
                                  icon: const Icon(Icons.visibility_outlined, size: 14, color: Colors.white),
                                  label: const Text(
                                    'VIEW',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0077BE),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 6),
                              ElevatedButton.icon(
                                onPressed: () => _showGradeDialog(context, submission['id'], studentName, subjectName, submissionGrade, submissionFeedback),
                                icon: const Icon(Icons.grade_rounded, size: 14, color: Colors.white),
                                label: Text(
                                  submissionGrade != null ? 'RE-GRADE' : 'GRADE',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4CAF50),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFacultyQuickAccess() {
    final actions = [
      (
        'Timetables',
        Icons.calendar_today_rounded,
        const Color(0xFF0077BE),
        '/teacher-timetable'
      ),
      (
        'Notices',
        Icons.campaign_rounded,
        const Color(0xFF4CAF50),
        '/notices'
      ),
      (
        'Events',
        Icons.event_note_rounded,
        const Color(0xFF9C27B0),
        '/events'
      ),
      (
        'Meal Plan',
        Icons.restaurant_menu_rounded,
        const Color(0xFFFF7043),
        '/meal-plan'
      ),
      (
        'Messages',
        Icons.chat_bubble_outline_rounded,
        const Color(0xFFE91E63),
        '/messaging'
      ),
      (
        'Complaints',
        Icons.warning_amber_rounded,
        const Color(0xFF607D8B),
        '/complaints'
      ),
      (
        'Salary Details',
        Icons.account_balance_wallet_rounded,
        const Color(0xFF009688),
        '/teacher-salary'
      ),
      (
        'Request Leave',
        Icons.time_to_leave_rounded,
        const Color(0xFFE91E63),
        '/teacher-leave'
      ),
      (
        'My Attendance',
        Icons.fact_check_rounded,
        const Color(0xFF4CAF50),
        '/attendance'
      ),
      (
        'Emergency Alert',
        Icons.shield_outlined,
        const Color(0xFFD32F2F),
        '/emergency-alerts'
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // const Text(
        //   'Quick Access',
        //   style: TextStyle(
        //     fontSize: 20,
        //     fontWeight: FontWeight.bold,
        //     color: Color(0xFF1A1A1A),
        //   ),
        // ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.3,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return GestureDetector(
              onTap: () {
                if (action.$1 == 'Exam Results') {
                  Navigator.pushNamed(context, action.$4, arguments: 0);
                } else if (action.$1 == 'My Class Results') {
                  Navigator.pushNamed(context, action.$4, arguments: 1);
                } else if (action.$1 == 'Class Rankings') {
                  Navigator.pushNamed(context, action.$4, arguments: 2);
                } else {
                  Navigator.pushNamed(context, action.$4);
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(200),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withAlpha(255)),
                      boxShadow: [
                        BoxShadow(
                          color: action.$3.withAlpha(15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: action.$3.withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            action.$2,
                            color: action.$3,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          action.$1,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: Color(0xFF2E2E2E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showGradeDialog(BuildContext context, int submissionId, String studentName, String subjectName, dynamic currentGrade, dynamic currentFeedback) {
    final gradeController = TextEditingController(text: currentGrade?.toString() ?? '');
    final feedbackController = TextEditingController(text: currentFeedback?.toString() ?? '');
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Grade Submission',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Student: $studentName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('Subject: $subjectName', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                    const SizedBox(height: 16),
                    const Text('Grade / Score', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: gradeController,
                      decoration: InputDecoration(
                        hintText: 'e.g. A, B+, 85/100',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Feedback / Comments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: feedbackController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Enter comments or suggestions...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final grade = gradeController.text.trim();
                          final feedback = feedbackController.text.trim();
                          if (grade.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Grade cannot be empty')),
                            );
                            return;
                          }

                          setDialogState(() {
                            isSubmitting = true;
                          });

                          final success = await Provider.of<TeacherProvider>(context, listen: false)
                              .gradeSubmission(submissionId, grade, feedback);

                          if (success) {
                            if (context.mounted) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Submission graded successfully!'), backgroundColor: Colors.green),
                              );
                            }
                          } else {
                            setDialogState(() {
                              isSubmitting = false;
                            });
                            if (context.mounted) {
                              final provider = Provider.of<TeacherProvider>(context, listen: false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(provider.error ?? 'Grading failed'), backgroundColor: Colors.redAccent),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0077BE),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('SUBMIT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
