import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/student_provider.dart';
import '../providers/auth_provider.dart';
import '../models/complaint_model.dart';

class ComplaintScreen extends StatefulWidget {
  const ComplaintScreen({super.key});

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  int activeTab = 0;
  final _categoryController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  final _adminSearchController = TextEditingController();
  String _adminStatusFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user?.role == 'admin') {
        Provider.of<StudentProvider>(context, listen: false).loadComplaints();
      } else {
        _loadComplaintsHistory();
      }
    });
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _messageController.dispose();
    _adminSearchController.dispose();
    super.dispose();
  }

  void _loadComplaintsHistory() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;
    if (userId != null) {
      Provider.of<StudentProvider>(context, listen: false).loadComplaints(userId: userId);
    }
  }

  Future<void> _submitComplaint() async {
    final category = _categoryController.text.trim();
    final message = _messageController.text.trim();

    if (category.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final result = await studentProvider.submitComplaint(category, message);
    
    setState(() {
      _isSubmitting = false;
    });

    if (result != null) {
      _categoryController.clear();
      _messageController.clear();
      
      // Reload history specifically for the logged-in user
      final userId = authProvider.user?.id;
      if (userId != null) {
        await studentProvider.loadComplaints(userId: userId);
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50)),
              SizedBox(width: 8),
              Text('Submitted'),
            ],
          ),
          content: const Text('Your complaint has been logged successfully. The admin will review it soon.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  activeTab = 1; // Switch to history tab
                });
              },
              child: const Text('OK', style: TextStyle(color: Color(0xFF0077BE), fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(studentProvider.error ?? 'Failed to submit complaint')),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.user?.role == 'admin';
    return isAdmin ? _buildAdminScaffold(context) : _buildUserScaffold(context);
  }

  Widget _buildUserScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
          'Complaints & Feedback',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
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
                _buildTabBar(),
                const SizedBox(height: 15),
                Expanded(
                  child: activeTab == 0
                      ? _buildNewComplaintForm()
                      : _buildHistoryList(),
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
            decoration: BoxDecoration(
              color: const Color(0xFF0077BE).withOpacity(0.06),
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
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.04),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFF0077BE).withOpacity(0.1)),
        ),
        child: Row(
          children: [_buildTab('New Complaint', 0), _buildTab('My History', 1)],
        ),
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    bool isSelected = activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            activeTab = index;
          });
          if (index == 1) {
            _loadComplaintsHistory();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
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
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewComplaintForm() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Category',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              _buildField(_categoryController, 'e.g., Academics, Transport, Facilities'),
              const SizedBox(height: 20),
              const Text(
                'Message / Details',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              _buildField(_messageController, 'Describe your concern in detail...', maxLines: 5),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitComplaint,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'SUBMIT COMPLAINT',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList() {
    return Consumer<StudentProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.complaints.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0077BE)),
            ),
          );
        }

        if (provider.error != null && provider.complaints.isEmpty) {
          return Center(
            child: Text(
              provider.error!,
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }

        if (provider.complaints.isEmpty) {
          return const Center(
            child: Text(
              'No complaint records found.',
              style: TextStyle(color: Colors.black45, fontSize: 14),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            _loadComplaintsHistory();
          },
          color: const Color(0xFF0077BE),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: provider.complaints.length,
            itemBuilder: (context, index) {
              final complaint = provider.complaints[index];
              return _buildStatusCard(complaint);
            },
          ),
        );
      },
    );
  }

  Widget _buildField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
        ),
      ),
    );
  }

  Widget _buildStatusCard(ComplaintModel complaint) {
    final dateStr = DateFormat('MMM dd, yyyy').format(complaint.createdAt);
    final statusColor = _getStatusColor(complaint.status);
    final statusText = _formatStatus(complaint.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          title: Text(
            complaint.category,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              dateStr,
              style: const TextStyle(color: Colors.black38, fontSize: 11),
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          children: [
            const Divider(color: Colors.black12, height: 1),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Message:',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black45),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    complaint.message,
                    style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                  ),
                  if (complaint.adminResponse != null && complaint.adminResponse!.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.05),
                        border: Border.all(color: Colors.green.withOpacity(0.15)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.admin_panel_settings_rounded, color: Colors.green, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Official Response:',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            complaint.adminResponse!,
                            style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Admin: Complaints Desk ----------------

  Widget _buildAdminScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
          'Complaints Desk',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
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
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                  child: Text(
                    'Review and resolve concerns submitted by students and teachers',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
                _buildAdminFilters(),
                const SizedBox(height: 12),
                Expanded(
                  child: Consumer<StudentProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoading && provider.complaints.isEmpty) {
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0077BE)),
                          ),
                        );
                      }

                      if (provider.error != null && provider.complaints.isEmpty) {
                        return Center(
                          child: Text(
                            provider.error!,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        );
                      }

                      final search = _adminSearchController.text.trim().toLowerCase();
                      final filtered = provider.complaints.where((c) {
                        final matchesSearch = search.isEmpty ||
                            c.category.toLowerCase().contains(search) ||
                            c.message.toLowerCase().contains(search) ||
                            (c.user?.name.toLowerCase().contains(search) ?? false);
                        final matchesStatus =
                            _adminStatusFilter == 'all' || c.status == _adminStatusFilter;
                        return matchesSearch && matchesStatus;
                      }).toList();

                      if (filtered.isEmpty) {
                        return const Center(
                          child: Text(
                            'No complaints found.',
                            style: TextStyle(color: Colors.black45, fontSize: 14),
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () => provider.loadComplaints(),
                        color: const Color(0xFF0077BE),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) => _buildAdminComplaintCard(filtered[index]),
                        ),
                      );
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

  Widget _buildAdminFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _adminSearchController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Search by name, category or message',
                  hintStyle: TextStyle(fontSize: 12, color: Colors.black38),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, size: 18, color: Colors.black38),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _adminStatusFilter,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                  DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                  DropdownMenuItem(value: 'closed', child: Text('Closed')),
                ],
                onChanged: (val) => setState(() => _adminStatusFilter = val ?? 'all'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminComplaintCard(ComplaintModel complaint) {
    final dateStr = DateFormat('MMM dd, yyyy').format(complaint.createdAt);
    final statusColor = _getStatusColor(complaint.status);
    final statusText = _formatStatus(complaint.status);
    final userName = complaint.user?.name ?? 'Unknown User';
    final userRole = complaint.user?.role.toUpperCase() ?? 'USER';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openAdminComplaintSheet(context, complaint),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      complaint.category,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '$userName ($userRole) · $dateStr',
                style: const TextStyle(color: Colors.black38, fontSize: 11),
              ),
              const SizedBox(height: 10),
              Text(
                complaint.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _confirmDeleteComplaint(context, complaint),
                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                    label: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ),
                  TextButton.icon(
                    onPressed: () => _openAdminComplaintSheet(context, complaint),
                    icon: const Icon(Icons.reply_rounded, size: 16, color: Color(0xFF0077BE)),
                    label: const Text('Respond', style: TextStyle(color: Color(0xFF0077BE), fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAdminComplaintSheet(BuildContext context, ComplaintModel complaint) {
    String status = complaint.status;
    final responseController = TextEditingController(text: complaint.adminResponse ?? '');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'Reply to Complaint',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      '${complaint.user?.name ?? 'Unknown'} (${complaint.user?.role.toUpperCase() ?? 'USER'})',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      complaint.category,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0077BE)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      complaint.message,
                      style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'pending', child: Text('Pending')),
                        DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                        DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                        DropdownMenuItem(value: 'closed', child: Text('Closed')),
                      ],
                      onChanged: (val) => setModalState(() => status = val ?? status),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: responseController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Response message',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                setModalState(() => isSaving = true);
                                final success = await Provider.of<StudentProvider>(context, listen: false)
                                    .updateComplaint(complaint.id, {
                                  'status': status,
                                  'admin_response': responseController.text.trim(),
                                });
                                if (sheetContext.mounted) Navigator.pop(sheetContext);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(success ? 'Complaint updated successfully' : 'Failed to update complaint'),
                                      backgroundColor: success ? const Color(0xFF4CAF50) : Colors.redAccent,
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0077BE),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                              )
                            : const Text('UPDATE COMPLAINT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
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

  void _confirmDeleteComplaint(BuildContext context, ComplaintModel complaint) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Complaint'),
        content: const Text('Are you sure you want to delete this complaint? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await Provider.of<StudentProvider>(context, listen: false).deleteComplaint(complaint.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Complaint deleted successfully' : 'Failed to delete complaint'),
                    backgroundColor: success ? const Color(0xFF4CAF50) : Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
