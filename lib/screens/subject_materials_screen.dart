import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subject_provider.dart';
import '../providers/auth_provider.dart';
import '../models/subject_model.dart';

class SubjectMaterialsScreen extends StatefulWidget {
  const SubjectMaterialsScreen({super.key});

  @override
  State<SubjectMaterialsScreen> createState() => _SubjectMaterialsScreenState();
}

class _SubjectMaterialsScreenState extends State<SubjectMaterialsScreen> {
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
    final groupedSubjects = subjectProvider.materialsGroupedByName;

    return Scaffold(
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
          'Learning Materials',
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
                _buildSearchBar(),
                Expanded(
                  child: subjectProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: () {
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            return subjectProvider.fetchSubjects(userId: authProvider.user?.id);
                          },
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (subjectProvider.error != null)
                                  _buildErrorWidget(subjectProvider.error!),
                                _buildAssignmentAlert(),
                                const SizedBox(height: 25),
                                const Text(
                                  'Subjects',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (groupedSubjects.isEmpty && !subjectProvider.isLoading)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(40.0),
                                      child: Text('No subject materials found.'),
                                    ),
                                  ),
                                ...groupedSubjects.entries.map((entry) {
                                  final name = entry.key;
                                  final items = entry.value;
                                  return _buildSubjectRow(
                                    name,
                                    '${items.length} Materials',
                                    _getSubjectColor(name),
                                    _getSubjectIcon(name),
                                    hasAssignment: items.any((s) => s.assignment != null && s.assignment!.isNotEmpty),
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      '/subject-modules',
                                      arguments: {'subject': name, 'materials': items},
                                    ),
                                  );
                                }).toList(),
                                const SizedBox(height: 50),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getSubjectColor(String name) {
    switch (name.toLowerCase()) {
      case 'mathematics':
      case 'math':
        return const Color(0xFF0077BE);
      case 'science':
      case 'physics':
        return const Color(0xFF4CAF50);
      case 'english':
        return const Color(0xFF9C27B0);
      case 'history':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF607D8B);
    }
  }

  IconData _getSubjectIcon(String name) {
    switch (name.toLowerCase()) {
      case 'mathematics':
      case 'math':
        return Icons.functions;
      case 'science':
      case 'physics':
        return Icons.science_outlined;
      case 'english':
        return Icons.translate;
      case 'history':
        return Icons.history_edu;
      default:
        return Icons.book_outlined;
    }
  }

  Widget _buildErrorWidget(String error) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(30),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'Error: $error',
        style: const TextStyle(color: Colors.red),
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF00B4DB), Color(0xFF0077BE)],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search subjects or notes...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF0077BE)),
          filled: true,
          fillColor: Colors.white.withAlpha(180),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildAssignmentAlert() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD32F2F), Color(0xFFFF5252)],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(Icons.notification_important, color: Colors.white),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'New Materials Available',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Check your subjects for updated assignments.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectRow(
    String name,
    String count,
    Color color,
    IconData icon, {
    required bool hasAssignment,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(150),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withAlpha(200)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (hasAssignment)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withAlpha(40),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: const Text(
                                  'Assignment',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Text(
                          count,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
