import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/subject_provider.dart';
import '../providers/auth_provider.dart';
import '../models/subject_model.dart';

class StudentResultsScreen extends StatefulWidget {
  const StudentResultsScreen({super.key});

  @override
  State<StudentResultsScreen> createState() => _StudentResultsScreenState();
}

class _StudentResultsScreenState extends State<StudentResultsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      Provider.of<SubjectProvider>(context, listen: false).fetchSubjects(userId: authProvider.user?.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final subjectProvider = Provider.of<SubjectProvider>(context);
    final allSubmissions = subjectProvider.subjects.where((s) => s.isSubmitted).toList();
    final gradedSubmissions = allSubmissions.where((s) => s.submissionGrade != null && s.submissionGrade!.isNotEmpty).toList();

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
          title: const Text(
            'Assignment Marks',
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
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: TabBar(
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: const Color(0xFFE91E63),
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: const Color(0xFFE91E63),
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                        tabs: const [
                          Tab(text: 'All Submissions'),
                          Tab(text: 'Graded Only'),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: subjectProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : RefreshIndicator(
                            onRefresh: () {
                              final authProvider = Provider.of<AuthProvider>(context, listen: false);
                              return subjectProvider.fetchSubjects(userId: authProvider.user?.id);
                            },
                            child: TabBarView(
                              children: [
                                _buildSubmissionsList(allSubmissions, showAll: true),
                                _buildSubmissionsList(gradedSubmissions, showAll: false),
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
                colors: [Color(0xFFF06292), Color(0xFFE91E63)],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmissionsList(List<SubjectModel> submissions, {required bool showAll}) {
    if (submissions.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                showAll ? Icons.assignment_outlined : Icons.grade_outlined,
                size: 60,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                showAll ? 'No Submissions Yet' : 'No Graded Assignments Yet',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                showAll
                    ? 'Upload and submit assignments to see them here.'
                    : 'Your graded assignments will appear here once marked.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: submissions.length,
      itemBuilder: (context, index) {
        final submission = submissions[index];
        final isGraded = submission.submissionGrade != null && submission.submissionGrade!.isNotEmpty;

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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0077BE).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            submission.subjectName ?? 'Subject',
                            style: const TextStyle(
                              color: Color(0xFF0077BE),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Text(
                          submission.submittedAt != null
                              ? DateFormat('MMM dd, yyyy').format(submission.submittedAt!)
                              : '',
                          style: const TextStyle(color: Colors.black45, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      submission.displayAssignment,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Colors.black12),
                    const SizedBox(height: 12),
                    if (isGraded) ...[
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 20, color: Colors.orange),
                          const SizedBox(width: 8),
                          const Text(
                            'Grade / Marks: ',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              submission.submissionGrade!,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                      if (submission.submissionFeedback != null && submission.submissionFeedback!.isNotEmpty) ...[
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
                                submission.submissionFeedback!,
                                style: const TextStyle(fontSize: 13, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ] else ...[
                      Row(
                        children: [
                          Icon(Icons.hourglass_empty_rounded, size: 18, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Pending Evaluation',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
