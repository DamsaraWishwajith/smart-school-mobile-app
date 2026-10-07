import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../models/admin_attendance_model.dart';

class AdminAttendanceScreen extends StatefulWidget {
  final String? roleFilter;
  const AdminAttendanceScreen({super.key, this.roleFilter});

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedGrade; // null = All Grades

  static const List<String> _grades = [
    '1', '2', '3', '4', '5', '6',
    '7', '8', '9', '10', '11', '12',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData({String? grade}) {
    Provider.of<AdminProvider>(context, listen: false)
        .loadAttendanceRecords(grade: grade);
  }

  void _onGradeSelected(String? grade) {
    setState(() {
      _selectedGrade = grade;
      _searchQuery = '';
      _searchController.clear();
    });
    _loadData(grade: grade);
  }

  Color _getStatusColor(String? status) {
    if (status == null) return const Color(0xFFD32F2F);
    final s = status.toLowerCase();
    if (s == 'in' || s == 'present') return const Color(0xFF4CAF50);
    if (s == 'out') return Colors.orange;
    if (s == 'absent' || s.contains('low') || s.contains('warn')) return const Color(0xFFD32F2F);
    return Colors.grey;
  }

  Widget _buildGradeBadge(String? grade) {
    if (grade == null || grade.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF0077BE).withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF0077BE).withAlpha(60)),
      ),
      child: Text(
        'Grade $grade',
        style: const TextStyle(
          color: Color(0xFF0077BE),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    final isStudentTab = widget.roleFilter == 'student';

    final filteredRecords = adminProvider.attendanceRecords.where((rec) {
      if (widget.roleFilter != null) {
        if ((rec.user?.role ?? '').toLowerCase() != widget.roleFilter!.toLowerCase()) {
          return false;
        }
      }
      final student = rec.user?.student;
      final matchesSearch =
          (rec.user?.name ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
          rec.date.contains(_searchQuery) ||
          (rec.status ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (student?.studentId ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
          'grade ${student?.grade ?? ''}'.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0077BE)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.roleFilter == 'student'
              ? 'Student Attendance Logs'
              : widget.roleFilter == 'teacher'
                  ? 'Teacher Attendance Logs'
                  : 'School Attendance Logs',
          style: const TextStyle(
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
                _buildSearchBar(),
                if (isStudentTab) _buildGradeDropdown(),
                if (!adminProvider.isLoading) ...[
                  if (isStudentTab && filteredRecords.any((r) => r.status?.toLowerCase() == 'absent' || r.inTime == null || (r.status?.toLowerCase().contains('low') ?? false)))
                    Container(
                      margin: const EdgeInsets.fromLTRB(20, 6, 20, 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFEF5350), width: 1.2),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Color(0xFFD32F2F), size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '⚠️ Low Attendance Warning: ${filteredRecords.where((r) => r.status?.toLowerCase() == 'absent' || r.inTime == null || (r.status?.toLowerCase().contains('low') ?? false)).length} student log(s) flagged for low/absent attendance.',
                              style: const TextStyle(
                                color: Color(0xFFD32F2F),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 2),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0077BE).withAlpha(15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${filteredRecords.length} record${filteredRecords.length == 1 ? "" : "s"}'
                            '${_selectedGrade != null ? "  \u00b7  Grade $_selectedGrade" : ""}',
                            style: const TextStyle(
                              color: Color(0xFF0077BE),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Expanded(
                  child: adminProvider.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Color(0xFF0077BE)),
                        )
                      : filteredRecords.isEmpty
                          ? _buildEmptyWidget(
                              _selectedGrade != null
                                  ? 'No logs found for Grade $_selectedGrade'
                                  : 'No attendance logs found',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              itemCount: filteredRecords.length,
                              itemBuilder: (context, index) {
                                return _buildAttendanceCard(filteredRecords[index]);
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
            width: 200,
            height: 200,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF64B5F6), Color(0xFF0077BE)],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -60,
          left: -60,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF0077BE), Colors.transparent],
                stops: [0.0, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(180),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by name, ID, date or status...',
                hintStyle: TextStyle(color: Colors.black38),
                prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF0077BE)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 15),
              ),
              onChanged: (value) {
                setState(() { _searchQuery = value; });
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradeDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(180),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _selectedGrade,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0077BE)),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(15),
                style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Row(
                      children: [
                        Icon(Icons.tune_rounded, size: 18, color: Color(0xFF0077BE)),
                        SizedBox(width: 8),
                        Text('All Grades'),
                      ],
                    ),
                  ),
                  ..._grades.map(
                    (g) => DropdownMenuItem<String?>(
                      value: g,
                      child: Row(
                        children: [
                          Icon(Icons.school_rounded, size: 18, color: Color(0xFF0077BE)),
                          SizedBox(width: 8),
                          Text('Grade $g'),
                        ],
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  _onGradeSelected(value);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(AdminAttendanceModel record) {
    final bool isLowOrAbsent = (record.status?.toLowerCase() == 'absent' ||
        record.status?.toLowerCase().contains('low') == true ||
        record.inTime == null);
    final statusColor = isLowOrAbsent ? const Color(0xFFD32F2F) : _getStatusColor(record.status);
    final userName = record.user?.name ?? 'Unknown User';
    final role = record.user?.role ?? 'N/A';
    final student = record.user?.student;
    final grade = student?.grade;
    final studentId = student?.studentId;
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isLowOrAbsent
                  ? const Color(0xFFFFEBEE).withAlpha(200)
                  : Colors.white.withAlpha(180),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isLowOrAbsent ? const Color(0xFFEF5350) : Colors.white,
                width: isLowOrAbsent ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [statusColor.withAlpha(40), statusColor.withAlpha(20)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF1A1A1A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (grade != null && grade.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            _buildGradeBadge(grade),
                          ],
                          if (isLowOrAbsent) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD32F2F).withAlpha(20),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFD32F2F).withAlpha(60)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.warning_amber_rounded, size: 10, color: Color(0xFFD32F2F)),
                                  SizedBox(width: 2),
                                  Text(
                                    'LOW',
                                    style: TextStyle(
                                      color: Color(0xFFD32F2F),
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 5,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            role.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.black38,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (studentId != null) ...[
                            _buildDot(),
                            Text(
                              studentId,
                              style: const TextStyle(
                                color: Colors.black45,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          _buildDot(),
                          Text(
                            record.date,
                            style: const TextStyle(color: Colors.black54, fontSize: 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.login_rounded,
                            size: 12,
                            color: record.inTime != null ? const Color(0xFF4CAF50) : const Color(0xFFD32F2F),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            record.inTime ?? 'Absent',
                            style: TextStyle(
                              color: record.inTime != null ? Colors.black87 : const Color(0xFFD32F2F),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.logout_rounded,
                            size: 12,
                            color: record.outTime != null ? Colors.orange : Colors.black26,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            record.outTime ?? '--:--',
                            style: TextStyle(
                              color: record.outTime != null ? Colors.black87 : Colors.black38,
                              fontSize: 11,
                              fontWeight: record.outTime != null ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withAlpha(60)),
                  ),
                  child: Text(
                    (isLowOrAbsent && record.inTime == null ? 'ABSENT' : (record.status ?? 'LOW')).toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
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

  Widget _buildDot() {
    return Container(
      width: 3,
      height: 3,
      decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
    );
  }

  Widget _buildEmptyWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 64, color: Colors.grey.withAlpha(80)),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (_selectedGrade != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _onGradeSelected(null),
              icon: const Icon(Icons.clear_rounded, size: 16),
              label: const Text('Clear Filter'),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF0077BE)),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
