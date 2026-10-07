import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).refreshUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
          'My Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1F36),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0077BE)),
            onPressed: () {
              authProvider.refreshUserProfile();
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0077BE)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                children: [
                  // Dynamic Profile Header Card
                  _buildProfileHeader(user),
                  const SizedBox(height: 16),

                  // Account Information Section
                  _buildSectionTitle('Account Details'),
                  _buildInfoCard([
                    _buildInfoRow(
                        Icons.person_outline_rounded, 'Full Name', user.name),
                    _buildDivider(),
                    _buildInfoRow(
                        Icons.email_outlined, 'Email Address', user.email),
                    _buildDivider(),
                    _buildInfoRow(
                        Icons.phone_outlined,
                        'Phone Number',
                        user.phone != null && user.phone!.isNotEmpty
                            ? user.phone!
                            : 'Not Provided'),
                    _buildDivider(),
                    _buildInfoRow(
                        Icons.location_on_outlined,
                        'Address',
                        user.address != null && user.address!.isNotEmpty
                            ? user.address!
                            : 'Not Provided'),
                    if (user.dob != null && user.dob!.isNotEmpty) ...[
                      _buildDivider(),
                      _buildInfoRow(
                          Icons.cake_outlined, 'Date of Birth', user.dob!),
                    ],
                  ]),

                  // Role Specific Section (Student / Teacher)
                  if (user.role.toLowerCase() == 'student' &&
                      user.student != null) ...[
                    _buildSectionTitle('Student Academic Details'),
                    _buildInfoCard([
                      _buildInfoRow(
                        Icons.badge_outlined,
                        'Student ID',
                        user.student!.studentId,
                      ),
                      _buildDivider(),
                      _buildInfoRow(
                        Icons.grade_outlined,
                        'Assigned Grade',
                        user.student!.grade.startsWith('Grade')
                            ? user.student!.grade
                            : 'Grade ${user.student!.grade}',
                      ),
                      _buildDivider(),
                      // _buildInfoRow(
                      //   Icons.class_outlined,
                      //   'Class Section',
                      //   user.student!.className,
                      // ),
                    ]),
                  ],

                  if (user.role.toLowerCase() == 'teacher' &&
                      user.teacher != null) ...[
                    _buildSectionTitle('Teacher Credentials'),
                    _buildInfoCard([
                      _buildInfoRow(
                        Icons.badge_outlined,
                        'Employee ID',
                        user.teacher!.employeeId,
                      ),
                      _buildDivider(),
                      _buildInfoRow(
                        Icons.school_outlined,
                        'Degree / Qualification',
                        user.teacher!.qualification.isNotEmpty
                            ? user.teacher!.qualification
                            : 'N/A',
                      ),
                      _buildDivider(),
                      _buildInfoRow(
                        Icons.menu_book_outlined,
                        'Subject Specialization',
                        user.teacher!.subjectSpecialization.isNotEmpty
                            ? user.teacher!.subjectSpecialization
                            : 'N/A',
                      ),
                      if (user.teacher!.salary != null) ...[
                        _buildDivider(),
                        _buildInfoRow(
                          Icons.account_balance_wallet_outlined,
                          'Monthly Basic Compensation',
                          'LKR ${user.teacher!.salary}',
                        ),
                      ],
                    ]),
                  ],

                  // Settings & Quick Links
                  _buildSectionTitle('Quick Actions & Tools'),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withAlpha(10),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildClickableRow(
                          Icons.qr_code_rounded,
                          'My Attendance QR Code',
                          const Color(0xFF0077BE),
                          () => Navigator.pushNamed(context, '/my-qr'),
                        ),
                      ],
                    ),
                  ),

                  // Logout Action
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                    child: ElevatedButton(
                      onPressed: () => _confirmLogout(context, authProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.withAlpha(20),
                        foregroundColor: Colors.redAccent,
                        minimumSize: const Size(double.infinity, 54),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.logout_rounded, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Log Out of Account',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    final String initial =
        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U';
    final String roleTitle = user.role.toUpperCase();

    final Color roleBg = user.role.toLowerCase() == 'teacher'
        ? const Color(0xFF9C27B0)
        : const Color(0xFF0077BE);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: user.role.toLowerCase() == 'teacher'
              ? [const Color(0xFF0A2540), const Color(0xFF9C27B0)]
              : [const Color(0xFF0A2540), const Color(0xFF0077BE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: roleBg.withAlpha(50),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 46,
              backgroundColor: roleBg,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            user.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withAlpha(200),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withAlpha(60)),
            ),
            child: Text(
              'ROLE: $roleTitle',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0077BE),
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0077BE).withAlpha(15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF0077BE), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableRow(
      IconData icon, String title, Color iconColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 60,
      endIndent: 16,
      color: Colors.grey.withAlpha(30),
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              nav.pop();
              await authProvider.logout();
              nav.pushNamedAndRemoveUntil('/login', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
