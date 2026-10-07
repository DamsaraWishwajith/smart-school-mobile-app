import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/subject_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class SubjectModulesScreen extends StatelessWidget {
  const SubjectModulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    final subject = args?['subject'] ?? 'Mathematics';
    final List<SubjectModel> materials = args?['materials'] as List<SubjectModel>? ?? [];

    // Sort assignments by dueTime
    final assignments = materials.where((m) => m.assignment != null && m.assignment!.isNotEmpty).toList();
    
    assignments.sort((a, b) {
      if (a.dueTime == null && b.dueTime == null) return 0;
      if (a.dueTime == null) return 1;
      if (b.dueTime == null) return -1;
      return a.dueTime!.compareTo(b.dueTime!);
    });

    // Filter for the top notice card: only show upcoming, non-submitted assignments
    final upcomingNotSubmitted = assignments.where((m) {
      if (m.isSubmitted) return false;
      if (m.dueTime == null || m.dueTime!.isEmpty) return true;
      try {
        final deadline = DateTime.parse(m.dueTime!);
        return deadline.isAfter(DateTime.now());
      } catch (e) {
        return true; // Keep it if we can't parse it
      }
    }).toList();

    final firstAssignment = upcomingNotSubmitted.isNotEmpty ? upcomingNotSubmitted.first : SubjectModel(id: -1);

    // Filter lists for tabs
    final courseMaterials = materials.where((m) => m.pdf != null && m.pdf!.isNotEmpty).toList();
    final assignmentMaterials = assignments; // Already filtered and sorted above

    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
          title: Text(
            subject,
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
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {},
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (firstAssignment.id != -1)
                                    _buildAssignmentNotice(
                                      context,
                                      firstAssignment,
                                      materials.indexOf(firstAssignment),
                                      subject,
                                      firstAssignment.isSubmitted 
                                        ? 'Submitted on ${DateFormat('MMM dd, hh:mm a').format(firstAssignment.submittedAt!)}'
                                        : firstAssignment.timeRemaining,
                                    ),
                                  const SizedBox(height: 25),
                                  Container(
                                    height: 45,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: TabBar(
                                      indicatorSize: TabBarIndicatorSize.tab,
                                      indicator: BoxDecoration(
                                        borderRadius: BorderRadius.circular(15),
                                        color: const Color(0xFF0077BE),
                                      ),
                                      labelColor: Colors.white,
                                      unselectedLabelColor: const Color(0xFF0077BE),
                                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                                      tabs: const [
                                        Tab(text: 'Materials'),
                                        Tab(text: 'Assignments'),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                          SliverFillRemaining(
                            child: TabBarView(
                              children: [
                                _buildMaterialsList(context, courseMaterials, subject),
                                _buildAssignmentsList(context, assignmentMaterials, subject),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialsList(BuildContext context, List<SubjectModel> items, String subject) {
    if (items.isEmpty) {
      return const Center(child: Text('No course materials available.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final material = items[index];
        return _buildModuleCard(
          'Module ${index + 1}',
          'Reading Material',
          const Color(0xFF0077BE),
          false,
          onTap: () => _openPDF(context, material.pdf, 'Study Material'),
        );
      },
    );
  }

  Widget _buildAssignmentsList(BuildContext context, List<SubjectModel> items, String subject) {
    if (items.isEmpty) {
      return const Center(child: Text('No assignments available.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final material = items[index];
        return _buildModuleCard(
          material.displayAssignment,
          material.isSubmitted 
            ? 'Submitted ${material.submissionTimeInfo}' 
            : material.timeRemaining,
          material.isSubmitted ? const Color(0xFF4CAF50) : const Color(0xFFD32F2F),
          !material.isSubmitted,
          subTitle: material.isSubmitted 
            ? 'on ${DateFormat('MMM dd, hh:mm a').format(material.submittedAt!)}' 
            : 'Deadline: ${material.dueTime ?? "Soon"}',
          onTap: () {
            // Open the assignment PDF
            if (material.assignment != null && material.assignment!.isNotEmpty) {
              _openPDF(context, material.assignment, 'Assignment Document');
            }
          },
          onAssignmentTap: () {
            // Go to submission screen
            Navigator.pushNamed(
              context,
              '/assignment-upload',
              arguments: {
                'subject_id': material.id,
                'subject_name': subject
              },
            );
          },
          onTapLabel: 'View Doc',
          onAssignmentTapLabel: 'Submit Now',
          submissionGrade: material.submissionGrade,
          submissionFeedback: material.submissionFeedback,
        );
      },
    );
  }

  Widget _buildAssignmentNotice(BuildContext context, SubjectModel firstAssignment, int index, String subject, String deadline) {
    final isSubmitted = firstAssignment.isSubmitted;
    
    return _buildNoticeCard(
      firstAssignment.displayAssignment,
      'Module ${index + 1}',
      deadline,
      isSubmitted: isSubmitted,
      onTap: () => Navigator.pushNamed(
        context,
        '/assignment-upload',
        arguments: {
          'subject_id': firstAssignment.id,
          'subject_name': subject
        },
      ),
    );
  }

  Future<void> _openPDF(BuildContext context, String? path, String title) async {
    if (path == null || path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No PDF available')),
      );
      return;
    }

    final String url = 'https://eliteinternationalschool-live.us.stackstaging.com$path';
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opening $title...'), duration: const Duration(seconds: 1)),
      );

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) => response.bodyBytes,
          name: title,
        );
      } else {
        throw Exception('Failed to load PDF (Status: ${response.statusCode})');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _buildBackgroundShapes() {
    return Stack(
      children: [
        Positioned(
          top: -70,
          left: -70,
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
      ],
    );
  }

  Widget _buildNoticeCard(
    String title,
    String moduleName,
    String deadline, {
    bool isSubmitted = false,
    required VoidCallback onTap,
  }) {
    final cardColor = isSubmitted ? const Color(0xFF4CAF50) : const Color(0xFFD32F2F);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: cardColor.withOpacity(0.12),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSubmitted ? Icons.check_circle_outline_rounded : Icons.assignment_outlined,
                      color: cardColor,
                      size: 24
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isSubmitted ? 'SUBMISSION COMPLETE' : 'PENDING ASSIGNMENT',
                              style: TextStyle(
                                color: cardColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isSubmitted ? 'Done' : deadline,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 9,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(isSubmitted ? 'Click to update submission' : 'Inside $moduleName', style: const TextStyle(color: Colors.black45, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cardColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      isSubmitted ? 'RESUBMIT ASSIGNMENT →' : 'GO TO ASSIGNMENT →',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(
    String title,
    String status,
    Color color,
    bool hasAlert, {
    String? subTitle,
    VoidCallback? onTap,
    VoidCallback? onAssignmentTap,
    String onTapLabel = 'View Material',
    String onAssignmentTapLabel = 'Open Assignment',
    String? submissionGrade,
    String? submissionFeedback,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      hasAlert ? Icons.assignment_late_rounded : Icons.picture_as_pdf_rounded,
                      color: hasAlert ? const Color(0xFFD32F2F) : color,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Row(
                            children: [
                              Text(status, style: TextStyle(color: hasAlert ? const Color(0xFFD32F2F) : Colors.black54, fontSize: 12, fontWeight: hasAlert ? FontWeight.bold : FontWeight.normal)),
                              if (subTitle != null) ...[
                                const SizedBox(width: 8),
                                Text('•', style: TextStyle(color: Colors.black26)),
                                const SizedBox(width: 8),
                                Text(subTitle, style: const TextStyle(color: Colors.black45, fontSize: 11)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (submissionGrade != null && submissionGrade.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Colors.black12),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 18, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Text(
                        'Grade / Marks: ',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          submissionGrade,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                  if (submissionFeedback != null && submissionFeedback.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.feedback_rounded, size: 18, color: Colors.blueGrey),
                        const SizedBox(width: 8),
                        const Text(
                          'Feedback: ',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54),
                        ),
                        Expanded(
                          child: Text(
                            submissionFeedback,
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onTap != null)
                      TextButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.menu_book_rounded, size: 16),
                        label: Text(onTapLabel, style: const TextStyle(fontSize: 11)),
                        style: TextButton.styleFrom(foregroundColor: color),
                      ),
                    if (onAssignmentTap != null) ...[
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: onAssignmentTap,
                        icon: const Icon(Icons.assignment_rounded, size: 16),
                        label: Text(onAssignmentTapLabel, style: const TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasAlert ? const Color(0xFFD32F2F) : color,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
