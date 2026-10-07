import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AIReportScreen extends StatefulWidget {
  const AIReportScreen({super.key});

  @override
  State<AIReportScreen> createState() => _AIReportScreenState();
}

class _AIReportScreenState extends State<AIReportScreen> {
  bool _isLoading = true;
  bool _isGenerating = false;
  String? _errorMessage;

  Map<String, dynamic>? _studentData;
  Map<String, dynamic>? _currentReport;
  List<dynamic> _reportHistory = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReportData();
    });
  }

  Future<void> _loadReportData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiServices.getStudentAiReport();
      if (!mounted) return;

      if (res['success'] == true && res['data'] != null) {
        dynamic payload = res['data'];
        
        // Unwrap nested 'data' from ApiServices._handleResponse and Laravel response
        while (payload is Map && payload.containsKey('data') && payload['data'] != null) {
          if (payload.containsKey('student') || payload.containsKey('latest') || payload.containsKey('overall_performance')) {
            break;
          }
          payload = payload['data'];
        }

        Map<String, dynamic>? student;
        Map<String, dynamic>? latest;
        List<dynamic> history = [];

        if (payload is Map) {
          if (payload['student'] is Map) {
            student = Map<String, dynamic>.from(payload['student']);
          }
          if (payload['latest'] is Map) {
            latest = Map<String, dynamic>.from(payload['latest']);
          } else if (payload['overall_performance'] != null) {
            latest = Map<String, dynamic>.from(payload);
          }
          if (payload['history'] is List) {
            history = payload['history'];
          }
        }

        print('[AIReportScreen] Loaded: student=' + (student != null).toString() + ', latest=' + (latest != null).toString() + ', history=' + history.length.toString());

        setState(() {
          _isLoading = false;
          _studentData = student;
          _currentReport = latest;
          _reportHistory = history;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = res['message'] ?? 'Failed to load report.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      print('[AIReportScreen] Error loading report: ' + e.toString());
      setState(() {
        _isLoading = false;
        _errorMessage = 'Network error: $e';
      });
    }
  }

  Future<void> _generateReport() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final res = await ApiServices.generateStudentAiReport(
        academicYear: DateTime.now().year.toString(),
        term: 'All Terms',
      );

      if (!mounted) return;
      setState(() {
        _isGenerating = false;
      });

      if (res['success'] == true) {
        dynamic payload = res['data'];
        while (payload is Map && payload.containsKey('data') && payload['data'] != null) {
          if (payload.containsKey('overall_performance') || payload.containsKey('latest')) {
            break;
          }
          payload = payload['data'];
        }

        if (payload is Map) {
          Map<String, dynamic>? rep;
          if (payload['latest'] is Map) {
            rep = Map<String, dynamic>.from(payload['latest']);
          } else if (payload['overall_performance'] != null) {
            rep = Map<String, dynamic>.from(payload);
          }
          if (rep != null) {
            setState(() {
              _currentReport = rep;
            });
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI Performance Report generated successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        _loadReportData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Failed to generate report.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating report: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _exportPdf() async {
    if (_currentReport == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No report available to export.')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final studentName = _studentData?['name'] ?? authProvider.user?.name ?? 'Student';
    final studentId = _studentData?['student_id'] ?? ('STU' + (authProvider.user?.id?.toString() ?? ''));
    final grade = _studentData?['grade']?.toString().replaceAll('Grade ', '') ?? '';
    final studentClass = _studentData?['class'] ?? '';
    final gradeDisplay = grade.isNotEmpty ? ('Grade ' + grade + (studentClass.isNotEmpty ? ' - Class ' + studentClass : '')) : 'Grade 10';

    final year = _currentReport?['academic_year']?.toString() ?? DateTime.now().year.toString();
    final term = _currentReport?['term']?.toString() ?? 'All Terms';
    final dateStr = _currentReport?['created_at'] != null
        ? DateFormat('yyyy-MM-dd').format(DateTime.parse(_currentReport!['created_at']))
        : DateFormat('yyyy-MM-dd').format(DateTime.now());

    final metrics = (_currentReport?['metrics'] as Map<String, dynamic>?) ?? {};
    final totalExams = (metrics['total_exams'] ?? '0').toString();
    final assignments = (metrics['total_assignments_submitted'] ?? '0').toString();

    final strengths = (_currentReport?['strengths'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final weaknesses = (_currentReport?['weaknesses'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final suggestions = (_currentReport?['improvement_suggestions'] as List?)?.map((e) => e.toString()).toList() ?? [];

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Elite International School',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo800,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'AI-Powered Student Academic Performance Report',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Evaluation Date',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey500,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      dateStr,
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 2, color: PdfColors.indigo600),
            pw.SizedBox(height: 12),

            // Student Info Banner
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'STUDENT NAME',
                        style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        '$studentName ($studentId)',
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'GRADE / CLASS',
                        style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        gradeDisplay,
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'YEAR / TERM',
                        style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        '$year - $term',
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // 2 Key KPI Boxes (NO Average Score, NO Attendance)
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColors.blue300, width: 1.5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'TOTAL EXAMS',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          totalExams,
                          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                        ),
                        pw.Text(
                          'Subjects Evaluated',
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 14),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColors.green300, width: 1.5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'ASSIGNMENTS',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.green800),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          assignments,
                          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
                        ),
                        pw.Text(
                          'Tasks Submitted',
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 18),

            // Overall Performance
            pw.Text(
              '1. Overall Academic Standing & Evaluation',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              _currentReport?['overall_performance'] ?? 'No evaluation available.',
              style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.4, color: PdfColors.grey900),
            ),
            pw.SizedBox(height: 14),

            // Growth Progress
            pw.Text(
              '2. Growth & Performance Trajectory',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              _currentReport?['growth_progress'] ?? 'Stable performance trajectory maintained across terms.',
              style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.4, color: PdfColors.grey900),
            ),
            pw.SizedBox(height: 14),

            // Strengths
            pw.Text(
              '3. Key Academic Strengths',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
            ),
            pw.SizedBox(height: 4),
            ...strengths.map(
              (s) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('• ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                    pw.Expanded(
                      child: pw.Text(s, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey900)),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 14),

            // Areas for Improvement
            pw.Text(
              '4. Areas Requiring Focus & Improvement',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900),
            ),
            pw.SizedBox(height: 4),
            ...weaknesses.map(
              (w) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('• ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.orange800)),
                    pw.Expanded(
                      child: pw.Text(w, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey900)),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 14),

            // Improvement Suggestions
            pw.Text(
              '5. Actionable Guidance for Student & Parents',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
            ),
            pw.SizedBox(height: 4),
            ...suggestions.asMap().entries.map(
              (entry) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('${entry.key + 1}. ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                    pw.Expanded(
                      child: pw.Text(entry.value, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey900)),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 14),

            // Counselor Summary
            if (_currentReport?['summary'] != null && _currentReport!['summary'].toString().isNotEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'COUNSELOR SUMMARY',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo800),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      '"' + _currentReport!['summary'].toString() + '"',
                      style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, color: PdfColors.grey800),
                    ),
                  ],
                ),
              ),

            pw.Spacer(),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            pw.Center(
              child: pw.Text(
                'Generated with Elite International School AI Academic Intelligence System • Official Confidential School Document',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${studentName}_AI_Performance_Report.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0077BE)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'AI Performance Report',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_currentReport != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF0077BE)),
              tooltip: 'Export PDF',
              onPressed: _exportPdf,
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0077BE)),
            tooltip: 'Refresh',
            onPressed: _loadReportData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF0077BE)),
            SizedBox(height: 16),
            Text(
              'Loading AI Performance Report...',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null && _currentReport == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 50),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF1E293B), fontSize: 15),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadReportData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0077BE),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentReport == null) {
      return _buildEmptyState();
    }

    final strengths = (_currentReport?['strengths'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final weaknesses = (_currentReport?['weaknesses'] as List?)?.map((e) => e.toString()).toList() ?? [];

    return RefreshIndicator(
      onRefresh: _loadReportData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetaHeaderCard(),
            const SizedBox(height: 16),
            _buildKeyMetricsRow(),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Overall Academic Standing',
              icon: Icons.assessment_outlined,
              iconColor: const Color(0xFF0077BE),
              content: _currentReport?['overall_performance'] ?? 'No evaluation recorded.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Growth & Progress Trajectory',
              icon: Icons.trending_up_rounded,
              iconColor: const Color(0xFF10B981),
              content: _currentReport?['growth_progress'] ?? 'Stable progress maintained.',
            ),
            const SizedBox(height: 16),
            _buildListCard(
              title: 'Key Academic Strengths',
              icon: Icons.star_rounded,
              iconColor: const Color(0xFF10B981),
              badgeColor: const Color(0xFFDCFCE7),
              textColor: const Color(0xFF15803D),
              bulletIcon: Icons.check_circle_rounded,
              items: strengths,
            ),
            const SizedBox(height: 16),
            _buildListCard(
              title: 'Areas Requiring Focus',
              icon: Icons.flag_rounded,
              iconColor: const Color(0xFFF59E0B),
              badgeColor: const Color(0xFFFEF3C7),
              textColor: const Color(0xFFB45309),
              bulletIcon: Icons.info_rounded,
              items: weaknesses,
            ),
            const SizedBox(height: 16),
            _buildSuggestionsCard(),
            const SizedBox(height: 16),
            if (_currentReport?['summary'] != null && _currentReport!['summary'].toString().isNotEmpty) ...[
              _buildSummaryCard(),
              const SizedBox(height: 16),
            ],
            if (_reportHistory.length > 1) ...[
              _buildHistorySection(),
              const SizedBox(height: 20),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF0077BE)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            const Text(
              'No AI Performance Report Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Generate an intelligent academic performance analysis based on your exam scores, homework submissions, and coursework.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateReport,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome, color: Colors.white),
                label: Text(
                  _isGenerating ? 'Analyzing Academic Data...' : 'Generate My AI Report',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0077BE),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaHeaderCard() {
    final authProvider = Provider.of<AuthProvider>(context);
    final studentName = _studentData?['name'] ?? authProvider.user?.name ?? 'Student';
    final studentId = _studentData?['student_id'] ?? ('STU' + (authProvider.user?.id?.toString() ?? ''));
    final grade = _studentData?['grade']?.toString().replaceAll('Grade ', '') ?? '';
    final studentClass = _studentData?['class'] ?? '';
    final gradeDisplay = grade.isNotEmpty ? ('Grade ' + grade + (studentClass.isNotEmpty ? ' - ' + studentClass : '')) : 'Grade 10';

    final year = _currentReport?['academic_year']?.toString() ?? DateTime.now().year.toString();
    final term = _currentReport?['term']?.toString() ?? 'All Terms';
    final dateStr = _currentReport?['created_at'] != null
        ? DateFormat('dd/MM/yyyy, HH:mm').format(DateTime.parse(_currentReport!['created_at']).toLocal())
        : 'Recently';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF0077BE).withOpacity(0.1),
                child: const Icon(Icons.school_rounded, color: Color(0xFF0077BE), size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            studentId,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4F46E5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            gradeDisplay,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
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
          const SizedBox(height: 14),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Year: $year  •  $term',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              Text(
                'Evaluated: $dateStr',
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _exportPdf,
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                  label: const Text('Export PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0077BE),
                    side: const BorderSide(color: Color(0xFFBCE3FB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generateReport,
                  icon: _isGenerating
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(
                    _isGenerating ? 'Updating...' : 'Re-evaluate',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0077BE),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2 KPI Metrics Row (NO Average Score, NO Attendance)
  Widget _buildKeyMetricsRow() {
    final metrics = (_currentReport?['metrics'] as Map<String, dynamic>?) ?? {};
    final totalExams = (metrics['total_exams'] ?? '0').toString();
    final assignments = (metrics['total_assignments_submitted'] ?? '0').toString();

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'TOTAL EXAMS',
            value: totalExams,
            subtitle: 'Subjects Evaluated',
            color: const Color(0xFF0077BE),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            title: 'ASSIGNMENTS',
            value: assignments,
            subtitle: 'Tasks Submitted',
            color: const Color(0xFF10B981),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF334155),
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color badgeColor,
    required Color textColor,
    required IconData bulletIcon,
    required List<String> items,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            const Text(
              'No items recorded.',
              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            )
          else
            ...items.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: badgeColor),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(bulletIcon, color: textColor, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsCard() {
    final suggestions = (_currentReport?['improvement_suggestions'] as List?)?.map((e) => e.toString()).toList() ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF2563EB), size: 20),
              SizedBox(width: 8),
              Text(
                'Actionable Guidance',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (suggestions.isEmpty)
            const Text(
              'No recommendations recorded.',
              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            )
          else
            ...suggestions.asMap().entries.map(
              (entry) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: const Border(
                    left: BorderSide(color: Color(0xFF3B82F6), width: 3.5),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: const Color(0xFF2563EB),
                      child: Text(
                        '${entry.key + 1}',
                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1E293B),
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withOpacity(0.06),
            const Color(0xFF0077BE).withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.format_quote_rounded, color: Color(0xFF6366F1), size: 20),
              SizedBox(width: 6),
              Text(
                'Counselor Summary',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6366F1),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '"' + (_currentReport?['summary']?.toString() ?? '') + '"',
            style: const TextStyle(
              fontSize: 13.5,
              fontStyle: FontStyle.italic,
              color: Color(0xFF334155),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Evaluation History',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _reportHistory.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final rep = _reportHistory[index] as Map<String, dynamic>;
              final isSelected = rep['id'] == _currentReport?['id'];
              final term = rep['term'] ?? 'Evaluation';
              final year = rep['academic_year'] ?? '2026';
              final date = rep['created_at'] != null
                  ? DateFormat('dd MMM yyyy').format(DateTime.parse(rep['created_at']))
                  : '';

              return InkWell(
                onTap: () {
                  setState(() {
                    _currentReport = rep;
                  });
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 140,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0077BE) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF0077BE) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$year',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white70 : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        term,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected ? Colors.white60 : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
