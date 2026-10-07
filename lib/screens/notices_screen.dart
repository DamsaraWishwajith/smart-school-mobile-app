import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:narme_project/providers/student_provider.dart';
import 'package:narme_project/providers/auth_provider.dart';
import 'package:narme_project/models/notice_model.dart';
import 'package:narme_project/widgets/create_sheet_kit.dart';
import 'package:intl/intl.dart';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  String _selectedTab = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StudentProvider>(context, listen: false).loadNotices();
    });
  }

  Future<void> _refreshNotices() async {
    await Provider.of<StudentProvider>(context, listen: false).loadNotices();
  }

  static const Map<String, Color> _categoryColors = {
    'academic': Color(0xFF0077BE),
    'finance': Color(0xFF4CAF50),
    'event': Color(0xFF9C27B0),
    'general': Color(0xFFFF9800),
  };

  static const Map<String, IconData> _categoryIcons = {
    'academic': Icons.school_rounded,
    'finance': Icons.payments_rounded,
    'event': Icons.event_rounded,
    'general': Icons.info_rounded,
  };

  void _showAddNoticeDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String category = 'general';
    String targetAudience = 'all';
    bool isPublishing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 22,
                right: 22,
                top: 14,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sheetDragHandle(),
                    sheetHeader(
                      icon: Icons.campaign_rounded,
                      title: 'Post New Notice',
                      subtitle: 'Share an announcement with the school',
                      color: _categoryColors[category]!,
                    ),
                    const SizedBox(height: 24),
                    sheetSectionLabel('Notice Title'),
                    TextField(
                      controller: titleController,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      decoration: sheetFieldDecoration(
                        hint: 'e.g. Term Exam Schedule Update',
                        icon: Icons.title_rounded,
                      ),
                    ),
                    const SizedBox(height: 18),
                    sheetSectionLabel('Content / Message'),
                    TextField(
                      controller: contentController,
                      maxLines: 4,
                      style: const TextStyle(fontSize: 13.5),
                      decoration: sheetFieldDecoration(
                        hint: 'Write the announcement details...',
                      ),
                    ),
                    const SizedBox(height: 18),
                    sheetSectionLabel('Category'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categoryColors.keys.map((c) {
                        return sheetChoiceChip(
                          label: c[0].toUpperCase() + c.substring(1),
                          selected: category == c,
                          color: _categoryColors[c]!,
                          icon: _categoryIcons[c],
                          onTap: () => setModalState(() => category = c),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    sheetSectionLabel('Audience'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: const [
                        ['all', 'All', Icons.groups_rounded],
                        ['students', 'Students', Icons.school_rounded],
                        ['teachers', 'Teachers', Icons.badge_rounded],
                      ].map((entry) {
                        final value = entry[0] as String;
                        final label = entry[1] as String;
                        final icon = entry[2] as IconData;
                        return sheetChoiceChip(
                          label: label,
                          icon: icon,
                          selected: targetAudience == value,
                          onTap: () => setModalState(() => targetAudience = value),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),
                    sheetSubmitButton(
                      label: 'PUBLISH NOTICE',
                      icon: Icons.send_rounded,
                      isLoading: isPublishing,
                      color: _categoryColors[category]!,
                      onPressed: () async {
                        if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Title and content are required')),
                          );
                          return;
                        }
                        setModalState(() => isPublishing = true);
                        final success = await Provider.of<StudentProvider>(context, listen: false).createNotice({
                          'title': titleController.text.trim(),
                          'content': contentController.text.trim(),
                          'category': category,
                          'target_audience': targetAudience,
                        });
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? 'Notice published successfully!' : 'Failed to publish notice'),
                              backgroundColor: success ? const Color(0xFF4CAF50) : Colors.redAccent,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.user?.role == 'admin';

    // List of categories for tabs
    final tabs = ['All', 'Academic', 'Finance', 'Event', 'General'];

    // Filter notices based on the selected tab
    final filteredNotices = studentProvider.notices.where((notice) {
      if (_selectedTab == 'All') return true;
      return notice.category.toLowerCase() == _selectedTab.toLowerCase();
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: _showAddNoticeDialog,
              backgroundColor: const Color(0xFF0077BE),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Post Notice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      body: Stack(
        children: [
          _buildBackgroundShapes(),
          SafeArea(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 25),
                  child: Text(
                    'Notices & Announcements',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                _buildTabBar(tabs),
                const SizedBox(height: 20),
                Expanded(
                  child: studentProvider.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0077BE)),
                          ),
                        )
                      : studentProvider.error != null
                          ? _buildErrorState(studentProvider.error!)
                          : filteredNotices.isEmpty
                              ? _buildEmptyState()
                              : RefreshIndicator(
                                  onRefresh: _refreshNotices,
                                  color: const Color(0xFF0077BE),
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    itemCount: filteredNotices.length,
                                    itemBuilder: (context, index) {
                                      final notice = filteredNotices[index];
                                      return _buildNoticeCard(notice);
                                    },
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

  Widget _buildBackgroundShapes() {
    return Stack(
      children: [
        Positioned(
          top: -80,
          left: -60,
          child: Container(
            width: 320,
            height: 320,
            decoration: const BoxDecoration(
              color: Color(0xFF0077BE),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: 50,
          right: -100,
          child: Container(
            width: 280,
            height: 280,
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(List<String> tabs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: const Color(0xFF0077BE).withOpacity(0.08)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: tabs.map((tab) => _buildTab(tab)).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String title) {
    final isSelected = _selectedTab == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = title;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0077BE) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black45,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildNoticeCard(NoticeModel notice) {
    Color cardColor;
    switch (notice.category.toLowerCase()) {
      case 'academic':
        cardColor = const Color(0xFF0077BE);
        break;
      case 'finance':
        cardColor = const Color(0xFF4CAF50);
        break;
      case 'event':
        cardColor = const Color(0xFF9C27B0);
        break;
      case 'general':
      default:
        cardColor = const Color(0xFFFF9800);
        break;
    }

    final String timeString = DateFormat('MMM dd, yyyy').format(notice.createdAt);
    final String postedByStr = notice.postedByUser != null
        ? 'By ${notice.postedByUser!.name}'
        : 'By Administrator';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: cardColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  notice.category.toUpperCase(),
                  style: TextStyle(
                    color: cardColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                timeString,
                style: const TextStyle(color: Colors.black38, fontSize: 10, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            notice.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            notice.content,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.black.withOpacity(0.05)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.person_outline, size: 14, color: cardColor.withOpacity(0.7)),
              const SizedBox(width: 6),
              Text(
                postedByStr,
                style: TextStyle(
                  color: cardColor.withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_outlined,
              size: 80,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Notices Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no announcements currently posted for this category.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load notices',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshNotices,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0077BE),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
