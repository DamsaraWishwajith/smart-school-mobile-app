import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/student_provider.dart';
import 'providers/subject_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/teacher_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/timetable_screen.dart';
import 'screens/subject_materials_screen.dart';
import 'screens/fees_screen.dart';
import 'screens/messaging_screen.dart';
import 'screens/notices_screen.dart';
import 'screens/events_screen.dart';
import 'screens/complaints_screen.dart';
import 'screens/gallery_screen.dart';
import 'screens/meal_plan_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/ai_report_screen.dart';
import 'screens/payment_success_screen.dart';
import 'screens/payment_failed_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/assignment_upload_screen.dart';
import 'screens/submission_success_screen.dart';
import 'screens/subject_modules_screen.dart';
import 'screens/module_content_screen.dart';
import 'screens/pdf_viewer_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_users_screen.dart';
import 'screens/admin_teachers_screen.dart';
import 'screens/admin_attendance_screen.dart';
import 'screens/admin_timetable_screen.dart';
import 'screens/teacher_dashboard_screen.dart';
import 'screens/teacher_upload_screen.dart';
import 'screens/teacher_timetable_screen.dart';
import 'screens/teacher_salary_screen.dart';
import 'screens/teacher_leave_screen.dart';
import 'screens/student_results_screen.dart';
import 'screens/my_qr_code_screen.dart';
import 'screens/teacher_exams_screen.dart';
import 'screens/student_exams_screen.dart';
import 'screens/emergency_alert_screen.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }
  
  NotificationService.initialize();
  
  final authProvider = AuthProvider();
  authProvider.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => SubjectProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => TeacherProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const SmartSchoolApp(),
    ),
  );
}


class SmartSchoolApp extends StatelessWidget {
  const SmartSchoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Elite International School',
      theme: ThemeData(
        fontFamily: 'Roboto',
        primaryColor: const Color(0xFF0077BE),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: const Color(0xFF4CAF50),
        ),
      ),
      initialRoute: authProvider.isAuthenticated 
          ? (authProvider.user?.role.toLowerCase() == 'admin' 
              ? '/admin-dashboard' 
              : (authProvider.user?.role.toLowerCase() == 'teacher'
                  ? '/teacher-dashboard'
                  : '/dashboard'))
          : '/login',
      routes: {
        '/login': (context) => const ModernLoginScreen(),
        '/register': (context) => const ModernRegisterScreen(),
        '/dashboard': (context) => const CompleteStudentDashboard(),
        '/attendance': (context) => const AttendanceScreen(),
        '/timetable': (context) => const TimetableScreen(),
        '/materials': (context) => const SubjectMaterialsScreen(),
        '/fees': (context) => const SchoolFeesScreen(),
        '/messaging': (context) => const MessagingHubScreen(),
        '/notices': (context) => const NoticesScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/events': (context) => const SchoolEventsHub(),
        '/complaints': (context) => const ComplaintScreen(),
        '/gallery': (context) => const SchoolGalleryHub(),
        '/meal-plan': (context) => const MealPlanScreen(),
        '/profile': (context) => const StudentProfileScreen(),
        '/ai-report': (context) => const AIReportScreen(),
        '/payment-success': (context) => const PaymentSuccessScreen(),
        '/payment-failed': (context) => const PaymentFailedScreen(),
        '/checkout': (context) => const CheckoutScreen(),
        '/assignment-upload': (context) => const AssignmentUploadScreen(),
        '/submission-success': (context) => const SubmissionSuccessScreen(),
        '/subject-modules': (context) => const SubjectModulesScreen(),
        '/module-content': (context) => const ModuleContentScreen(),
        '/pdf-viewer': (context) => const PDFViewerScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/admin-users': (context) => const AdminUsersScreen(),
        '/admin-teachers': (context) => const AdminTeachersScreen(),
        '/admin-student-attendance': (context) => const AdminAttendanceScreen(roleFilter: 'student'),
        '/admin-teacher-attendance': (context) => const AdminAttendanceScreen(roleFilter: 'teacher'),
        '/admin-timetable': (context) => const AdminTimetableScreen(),
        '/teacher-dashboard': (context) => const TeacherDashboardScreen(),
        '/teacher-upload': (context) => const TeacherUploadScreen(),
        '/teacher-timetable': (context) => const TeacherTimetableScreen(),
        '/teacher-salary': (context) => const TeacherSalaryScreen(),
        '/teacher-leave': (context) => const TeacherLeaveScreen(),
        '/teacher-exams': (context) => const TeacherExamsScreen(),
        '/student-exams': (context) => const StudentExamsScreen(),
        '/student-results': (context) => const StudentResultsScreen(),
        '/my-qr': (context) => const MyQrCodeScreen(),
        '/emergency-alerts': (context) => const EmergencyAlertScreen(),
      },
    );
  }
}
