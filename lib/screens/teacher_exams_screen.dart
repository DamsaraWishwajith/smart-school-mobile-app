import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/teacher_provider.dart';
import '../providers/subject_provider.dart';
import '../providers/admin_provider.dart';
import '../models/exam_result_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class StudentSummary {
  final int studentId;
  final String studentName;
  final String grade; // e.g. Grade 1
  final List<ExamResultModel> results;

  StudentSummary({
    required this.studentId,
    required this.studentName,
    required this.grade,
    required this.results,
  });

  int get totalMarks =>
      results.fold(0, (sum, item) => sum + item.marksObtained);
  int get totalMaxMarks =>
      results.fold(0, (sum, item) => sum + item.totalMarks);
  double get avgPercent =>
      totalMaxMarks > 0 ? (totalMarks / totalMaxMarks) * 100 : 0.0;
  int get subjectCount => results.length;
}

class TeacherExamsScreen extends StatefulWidget {
  final int initialTabIndex;
  const TeacherExamsScreen({super.key, this.initialTabIndex = 0});

  @override
  State<TeacherExamsScreen> createState() => _TeacherExamsScreenState();
}

class _TeacherExamsScreenState extends State<TeacherExamsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String? _selectedClass = 'Grade 1';
  int? _selectedSubjectId;
  String? _selectedTerm = 'Term 1';
  int? _selectedYear = 2026;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 3, vsync: this, initialIndex: widget.initialTabIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is int && args >= 0 && args < 3) {
        _tabController.animateTo(args);
      }
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final teacherProv = Provider.of<TeacherProvider>(context, listen: false);
    final subjectProv = Provider.of<SubjectProvider>(context, listen: false);
    final adminProv = Provider.of<AdminProvider>(context, listen: false);

    await Future.wait([
      teacherProv.loadExamResults(),
      subjectProv.fetchSubjects(),
      adminProv.loadUsers(),
    ]);
  }

  List<StudentSummary> _calculateStudentSummaries(
      List<ExamResultModel> examResults) {
    Map<String, StudentSummary> map = {};

    for (var res in examResults) {
      final key = '${res.studentId}_${res.studentName}';
      if (!map.containsKey(key)) {
        map[key] = StudentSummary(
          studentId: res.studentId,
          studentName: res.studentName,
          grade: res.studentClassGrade,
          results: [],
        );
      }
      map[key]!.results.add(res);
    }

    List<StudentSummary> summaries = map.values.toList();
    // Sort descending by total marks
    summaries.sort((a, b) => b.totalMarks.compareTo(a.totalMarks));
    return summaries;
  }

  @override
  Widget build(BuildContext context) {
    final teacherProv = Provider.of<TeacherProvider>(context);
    final subjectProv = Provider.of<SubjectProvider>(context);

    // Filter results
    final List<ExamResultModel> filteredResults =
        teacherProv.examResults.where((res) {
      final matchesSearch =
          res.studentName.toLowerCase().contains(_searchQuery.toLowerCase());
      
      bool matchesClass = true;
      if (_selectedClass != null && _selectedClass != 'All Classes') {
        final c1 = res.studentClassGrade.trim().toLowerCase().replaceAll('grade ', '');
        final c2 = _selectedClass!.trim().toLowerCase().replaceAll('grade ', '');
        matchesClass = (c1 == c2);
      }

      final matchesSubject =
          _selectedSubjectId == null || res.subjectId == _selectedSubjectId;
      
      final matchesTerm = _selectedTerm == null ||
          _selectedTerm == 'All Terms' ||
          res.term.trim().toLowerCase() == _selectedTerm!.trim().toLowerCase();

      final matchesYear = _selectedYear == null ||
          res.academicYear == 0 ||
          res.academicYear == _selectedYear;

      return matchesSearch && matchesClass && matchesSubject && matchesTerm && matchesYear;
    }).toList();

    final List<StudentSummary> studentSummaries =
        _calculateStudentSummaries(filteredResults);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A2540),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Exam & Class Management',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
            tooltip: 'Export Report Sheet',
            onPressed: () => _generatePdfReport(filteredResults),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF0077BE),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.check_circle_outline_rounded, size: 18), text: 'Exam Results'),
            Tab(icon: Icon(Icons.article_outlined, size: 18), text: 'Class Results'),
            Tab(icon: Icon(Icons.groups_outlined, size: 18), text: 'Rankings'),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showAddEditDialog(context),
              backgroundColor: const Color(0xFF0077BE),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Exam Result',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: ALL EXAM RESULTS (CRUD)
          _buildExamResultsTab(teacherProv, subjectProv, filteredResults),

          // TAB 2: MY CLASS RESULTS (STUDENT-WISE REPORT CARDS)
          _buildClassResultsTab(teacherProv, subjectProv, studentSummaries),

          // TAB 3: CLASS RANKINGS (LEADERBOARD)
          _buildClassRankingsTab(teacherProv, subjectProv, studentSummaries),
        ],
      ),
    );
  }

  // TAB 1: EXAM RESULTS LIST
  Widget _buildExamResultsTab(TeacherProvider teacherProv,
      SubjectProvider subjectProv, List<ExamResultModel> filteredResults) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: Column(
        children: [
          _buildSearchAndFilters(subjectProv.subjects),
          Expanded(
            child: teacherProv.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0077BE)),
                  )
                : filteredResults.isEmpty
                    ? _buildEmptyState('No Exam Results Found',
                        'Add exam records by tapping the "+" button below.')
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: filteredResults.length,
                        itemBuilder: (context, index) {
                          return _buildExamCard(filteredResults[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // TAB 2: MY CLASS RESULTS (STUDENT REPORT CARDS)
  Widget _buildClassResultsTab(TeacherProvider teacherProv,
      SubjectProvider subjectProv, List<StudentSummary> summaries) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: Column(
        children: [
          _buildSearchAndFilters(subjectProv.subjects),
          Expanded(
            child: teacherProv.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0077BE)))
                : summaries.isEmpty
                    ? _buildEmptyState(
                        'No Class Results', 'No exam records logged for students in this class.')
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: summaries.length,
                        itemBuilder: (context, index) {
                          final student = summaries[index];
                          final rank = index + 1;
                          return _buildStudentReportCard(student, rank);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // TAB 3: CLASS RANKINGS LEADERBOARD
  Widget _buildClassRankingsTab(TeacherProvider teacherProv,
      SubjectProvider subjectProv, List<StudentSummary> summaries) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: Column(
        children: [
          _buildSearchAndFilters(subjectProv.subjects),
          Expanded(
            child: teacherProv.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0077BE)))
                : summaries.isEmpty
                    ? _buildEmptyState('No Rankings Available',
                        'Log student exam marks to generate class leaderboard.')
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Class Leaderboard & Ranks',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...summaries.asMap().entries.map((entry) {
                              final rank = entry.key + 1;
                              final student = entry.value;
                              return _buildRankingCard(student, rank);
                            }),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(List<dynamic> subjects) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search by student name...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          // Class Filter Dropdown (Grade 1, Grade 2...)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedClass,
                      hint: const Text('Class', style: TextStyle(fontSize: 12)),
                      isExpanded: true,
                      style: const TextStyle(color: Colors.black87, fontSize: 13),
                      items: const [
                        DropdownMenuItem<String>(
                          value: 'All Classes',
                          child: Text('All Classes', style: TextStyle(fontSize: 12)),
                        ),
                        DropdownMenuItem<String>(
                          value: 'Grade 1',
                          child: Text('Grade 1', style: TextStyle(fontSize: 12)),
                        ),
                        DropdownMenuItem<String>(
                          value: 'Grade 2',
                          child: Text('Grade 2', style: TextStyle(fontSize: 12)),
                        ),
                        DropdownMenuItem<String>(
                          value: 'Grade 3',
                          child: Text('Grade 3', style: TextStyle(fontSize: 12)),
                        ),
                        DropdownMenuItem<String>(
                          value: 'Grade 4',
                          child: Text('Grade 4', style: TextStyle(fontSize: 12)),
                        ),
                        DropdownMenuItem<String>(
                          value: 'Grade 5',
                          child: Text('Grade 5', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedClass = val;
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedTerm,
                      hint: const Text('Term', style: TextStyle(fontSize: 12)),
                      isExpanded: true,
                      style:
                          const TextStyle(color: Colors.black87, fontSize: 13),
                      items: const [
                        DropdownMenuItem<String>(
                          value: 'All Terms',
                          child: Text('All Terms',
                              style: TextStyle(fontSize: 12)),
                        ),
                        DropdownMenuItem<String>(
                            value: 'Term 1',
                            child: Text('Term 1',
                                style: TextStyle(fontSize: 12))),
                        DropdownMenuItem<String>(
                            value: 'Term 2',
                            child: Text('Term 2',
                                style: TextStyle(fontSize: 12))),
                        DropdownMenuItem<String>(
                            value: 'Term 3',
                            child: Text('Term 3',
                                style: TextStyle(fontSize: 12))),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedTerm = val;
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedYear,
                      hint: const Text('Year', style: TextStyle(fontSize: 12)),
                      isExpanded: true,
                      style:
                          const TextStyle(color: Colors.black87, fontSize: 13),
                      items: const [
                        DropdownMenuItem<int>(
                          value: 2026,
                          child: Text('2026', style: TextStyle(fontSize: 12)),
                        ),
                        DropdownMenuItem<int>(
                          value: 2025,
                          child: Text('2025', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedYear = val;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExamCard(ExamResultModel res) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  res.studentName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0077BE).withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  res.studentClassGrade,
                  style: const TextStyle(
                    color: Color(0xFF0077BE),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.book_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                res.subjectName,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
              const Spacer(),
              Text(
                '${res.marksObtained} / ${res.totalMarks}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  res.grade,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.layers_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                '${res.examName} (${res.term}) • ${res.academicYear}',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ],
          ),
          if (res.remarks != null && res.remarks!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Remarks: ${res.remarks}',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                  color: Color(0xFF475569),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _showAddEditDialog(context, res),
                icon: const Icon(Icons.edit_rounded,
                    size: 16, color: Color(0xFF0077BE)),
                label: const Text('Edit',
                    style: TextStyle(color: Color(0xFF0077BE), fontSize: 13)),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: () => _deleteResult(res.id),
                icon: const Icon(Icons.delete_forever_rounded,
                    size: 16, color: Colors.redAccent),
                label: const Text('Delete',
                    style: TextStyle(color: Colors.redAccent, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentReportCard(StudentSummary student, int rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF0077BE),
                  child: Text(
                    student.studentName.isNotEmpty
                        ? student.studentName[0].toUpperCase()
                        : 'S',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.studentName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        '${student.grade} • ${student.subjectCount} Subjects Recorded',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                _buildRankBadge(rank),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('Total Marks',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFF64748B))),
                      const SizedBox(height: 2),
                      Text('${student.totalMarks} Marks',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF4CAF50))),
                    ],
                  ),
                  Container(height: 24, width: 1, color: const Color(0xFFE2E8F0)),
                  Column(
                    children: [
                      const Text('Average %',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFF64748B))),
                      const SizedBox(height: 2),
                      Text('${student.avgPercent.toStringAsFixed(1)}%',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFFFF9800))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text('Subject Marks & Evaluation',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF334155))),
            const SizedBox(height: 8),

            ...student.results.map((res) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9).withAlpha(100),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        res.subjectName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF1E293B)),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        res.examName,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ),
                    Text(
                      '${res.marksObtained}/${res.totalMarks}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF0077BE)),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9800),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        res.grade,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingCard(StudentSummary student, int rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildRankBadge(rank),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.studentName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${student.grade} • ${student.subjectCount} Subjects',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${student.totalMarks} Marks',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF4CAF50),
                ),
              ),
              Text(
                '${student.avgPercent.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Color(0xFFFF9800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color bg;
    Color text;
    String label;

    if (rank == 1) {
      bg = const Color(0xFFFFD700);
      text = const Color(0xFF856404);
      label = '🥇 1ST PLACE';
    } else if (rank == 2) {
      bg = const Color(0xFFC0C0C0);
      text = const Color(0xFF383D41);
      label = '🥈 2ND PLACE';
    } else if (rank == 3) {
      bg = const Color(0xFFCD7F32);
      text = Colors.white;
      label = '🥉 3RD PLACE';
    } else {
      bg = const Color(0xFFF1F5F9);
      text = const Color(0xFF64748B);
      label = '$rank TH PLACE';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0077BE).withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_turned_in_rounded,
                color: Color(0xFF0077BE),
                size: 60,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEditDialog(BuildContext context,
      [ExamResultModel? existingRecord]) {
    final subjectProv = Provider.of<SubjectProvider>(context, listen: false);
    final adminProv = Provider.of<AdminProvider>(context, listen: false);

    final isEdit = existingRecord != null;

    final formKey = GlobalKey<FormState>();
    int? formStudentId = existingRecord?.studentId;
    int? formSubjectId = existingRecord?.subjectId;
    final nameController =
        TextEditingController(text: existingRecord?.examName ?? 'Final Exam');
    final marksController =
        TextEditingController(text: existingRecord?.marksObtained.toString());
    final totalMarksController = TextEditingController(
        text: existingRecord?.totalMarks.toString() ?? '100');
    String formTerm = existingRecord?.term ?? 'Term 1';
    int formYear = existingRecord?.academicYear ?? 2026;
    final remarksController =
        TextEditingController(text: existingRecord?.remarks);

    final studentUsers = adminProv.users
        .where((u) => u.role.toLowerCase() == 'student' && u.student != null)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEdit ? 'Edit Exam Result' : 'Add New Exam Result',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue: formStudentId,
                        decoration: InputDecoration(
                          labelText: 'Select Student',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        items: studentUsers.map((u) {
                          final studentGrade = u.student?.grade ?? "Grade 1";
                          return DropdownMenuItem<int>(
                            value: u.student!.id,
                            child: Text('${u.name} ($studentGrade)'),
                          );
                        }).toList(),
                        onChanged: isEdit
                            ? null
                            : (val) {
                                setModalState(() {
                                  formStudentId = val;
                                });
                              },
                        validator: (val) =>
                            val == null ? 'Please select a student' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: formSubjectId,
                        decoration: InputDecoration(
                          labelText: 'Select Subject',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        items: subjectProv.subjects.map((s) {
                          return DropdownMenuItem<int>(
                            value: s.id,
                            child: Text(s.subjectName ?? 'Unknown Subject'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setModalState(() {
                            formSubjectId = val;
                          });
                        },
                        validator: (val) =>
                            val == null ? 'Please select a subject' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Exam Name',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (val) => val == null || val.isEmpty
                            ? 'Please enter exam name'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: marksController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Marks Obtained',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Enter marks'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: totalMarksController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Total Marks',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Enter total'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: formTerm,
                              decoration: InputDecoration(
                                labelText: 'Term',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'Term 1', child: Text('Term 1')),
                                DropdownMenuItem(
                                    value: 'Term 2', child: Text('Term 2')),
                                DropdownMenuItem(
                                    value: 'Term 3', child: Text('Term 3')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() {
                                    formTerm = val;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: formYear,
                              decoration: InputDecoration(
                                labelText: 'Year',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 2026, child: Text('2026')),
                                DropdownMenuItem(
                                    value: 2025, child: Text('2025')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() {
                                    formYear = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: remarksController,
                        decoration: InputDecoration(
                          labelText: 'Remarks (Optional)',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              final teacherProv = Provider.of<TeacherProvider>(
                                  context,
                                  listen: false);

                              final marks =
                                  int.parse(marksController.text.trim());
                              final total =
                                  int.parse(totalMarksController.text.trim());

                              bool ok = false;
                              if (isEdit) {
                                ok = await teacherProv.updateExamResult(
                                  existingRecord.id,
                                  {
                                    'exam_name': nameController.text.trim(),
                                    'marks_obtained': marks,
                                    'total_marks': total,
                                    'term': formTerm,
                                    'academic_year': formYear,
                                    'remarks': remarksController.text.trim(),
                                  },
                                );
                              } else {
                                ok = await teacherProv.addExamResult({
                                  'student_id': formStudentId!,
                                  'subject_id': formSubjectId!,
                                  'exam_name': nameController.text.trim(),
                                  'marks_obtained': marks,
                                  'total_marks': total,
                                  'term': formTerm,
                                  'academic_year': formYear,
                                  'remarks': remarksController.text.trim(),
                                });
                              }

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(ok
                                        ? (isEdit
                                            ? 'Result updated successfully!'
                                            : 'Result added successfully!')
                                        : 'Failed to save exam result.'),
                                    backgroundColor:
                                        ok ? Colors.green : Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0077BE),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            isEdit ? 'Save Changes' : 'Add Exam Result',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _deleteResult(int id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Result'),
          content:
              const Text('Are you sure you want to delete this exam result?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final teacherProv =
                    Provider.of<TeacherProvider>(context, listen: false);
                final ok = await teacherProv.deleteExamResult(id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok
                          ? 'Result deleted successfully'
                          : 'Failed to delete result'),
                      backgroundColor: ok ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _generatePdfReport(List<ExamResultModel> results) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Elite International School - Exam Results Report Sheet',
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.Text(DateTime.now().toString().substring(0, 10)),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                headers: [
                  'Student Name',
                  'Grade',
                  'Subject',
                  'Exam Name',
                  'Marks',
                  'Grade',
                  'Term'
                ],
                data: results.map((res) {
                  return [
                    res.studentName,
                    res.studentClassGrade,
                    res.subjectName,
                    res.examName,
                    '${res.marksObtained}/${res.totalMarks}',
                    res.grade,
                    res.term,
                  ];
                }).toList(),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
