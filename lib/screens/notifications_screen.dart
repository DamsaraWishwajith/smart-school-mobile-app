import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;
  List<dynamic> _emergencyAlerts = [];
  List<dynamic> _notices = [];
  List<dynamic> _attendanceLogs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;

      final results = await Future.wait<Map<String, dynamic>>([
        ApiServices.getEmergencyAlerts(),
        ApiServices.getNotices(),
        if (userId != null)
          ApiServices.getAttendanceByUser(userId)
        else
          Future.value({'success': false, 'data': []}),
      ]);

      if (mounted) {
        setState(() {
          _isLoading = false;

          final emergencyRes = results[0];
          final noticesRes   = results[1];
          final attendanceRes = results[2];

          if (emergencyRes['success'] == true && emergencyRes['data'] is List) {
            _emergencyAlerts = emergencyRes['data'] as List<dynamic>;
          }

          if (noticesRes['success'] == true && noticesRes['data'] is List) {
            _notices = noticesRes['data'] as List<dynamic>;
          }

          if (attendanceRes['success'] == true && attendanceRes['data'] is List) {
            _attendanceLogs = attendanceRes['data'] as List<dynamic>;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load notifications: $e';
        });
      }
    }
  }

  String _formatDateTime(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return 'Just now';
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      return DateFormat('M/d/yyyy, h:mm:ss a').format(dt);
    } catch (_) {
      return rawDate;
    }
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '—';
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      return DateFormat('EEE, MMM d, yyyy').format(dt);
    } catch (_) {
      return rawDate;
    }
  }

  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return '—';
    try {
      // Handle both HH:mm:ss and HH:mm formats
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final min = int.parse(parts[1]);
      final dt = DateTime(2000, 1, 1, hour, min);
      return DateFormat('h:mm a').format(dt);
    } catch (_) {
      return time;
    }
  }

  Color _getPresetColor(String? presetType) {
    switch (presetType?.toLowerCase()) {
      case 'fire':
        return const Color(0xFFD32F2F);
      case 'weather':
        return const Color(0xFFF57C00);
      case 'lockdown':
        return const Color(0xFFC2185B);
      case 'medical':
        return const Color(0xFF1976D2);
      default:
        return const Color(0xFF757575);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Notifications & Alerts',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadAllNotifications,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF38BDF8),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emergency_rounded, size: 14, color: Colors.redAccent),
                  const SizedBox(width: 4),
                  Text('Alerts (${_emergencyAlerts.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.campaign_rounded, size: 14, color: Color(0xFF38BDF8)),
                  const SizedBox(width: 4),
                  Text('Notices (${_notices.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.fingerprint_rounded, size: 14, color: Color(0xFF4ADE80)),
                  const SizedBox(width: 4),
                  Text('Attendance (${_attendanceLogs.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0077BE)))
          : _error != null
              ? _buildErrorView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEmergencyAlertsTab(),
                    _buildNoticesTab(),
                    _buildAttendanceLogsTab(),
                  ],
                ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ATTENDANCE LOGS TAB
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildAttendanceLogsTab() {
    if (_attendanceLogs.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadAllNotifications,
        color: const Color(0xFF0077BE),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ADE80).withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fingerprint_rounded,
                    size: 56,
                    color: Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Attendance Records',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your school arrival and departure logs will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllNotifications,
      color: const Color(0xFF0077BE),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _attendanceLogs.length,
        itemBuilder: (context, index) {
          final log = _attendanceLogs[index];
          return _buildAttendanceLogCard(log);
        },
      ),
    );
  }

  Widget _buildAttendanceLogCard(Map<String, dynamic> log) {
    final String date = _formatDate(log['date']?.toString());
    final String? inTime = log['in_time']?.toString();
    final String? outTime = log['out_time']?.toString();
    final String status = (log['status'] ?? '').toString().toLowerCase();

    final bool hasIn = inTime != null && inTime.isNotEmpty;
    final bool hasOut = outTime != null && outTime.isNotEmpty;

    Color statusColor;
    if (status == 'in' || status == 'present') {
      statusColor = const Color(0xFF16A34A);
    } else if (status == 'out') {
      statusColor = const Color(0xFFF97316);
    } else {
      statusColor = const Color(0xFF6366F1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withAlpha(40), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withAlpha(15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 5),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withAlpha(60)),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Arrival & Departure Row
            Row(
              children: [
                if (hasIn)
                  Expanded(
                    child: _buildTimeChip(
                      icon: Icons.login_rounded,
                      label: 'Arrived',
                      time: _formatTime(inTime),
                      color: const Color(0xFF16A34A),
                      bgColor: const Color(0xFFDCFCE7),
                    ),
                  ),
                if (hasIn && hasOut) const SizedBox(width: 10),
                if (hasOut)
                  Expanded(
                    child: _buildTimeChip(
                      icon: Icons.logout_rounded,
                      label: 'Left',
                      time: _formatTime(outTime),
                      color: const Color(0xFFEA580C),
                      bgColor: const Color(0xFFFFF7ED),
                    ),
                  ),
                if (!hasIn && !hasOut)
                  const Text(
                    'No time recorded',
                    style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeChip({
    required IconData icon,
    required String label,
    required String time,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // EMERGENCY ALERTS TAB
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildEmergencyAlertsTab() {
    if (_emergencyAlerts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadAllNotifications,
        color: const Color(0xFF0077BE),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield_outlined, size: 56, color: Colors.green),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Emergency Alerts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'All clear! No emergency broadcast notifications recorded.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllNotifications,
      color: const Color(0xFF0077BE),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _emergencyAlerts.length,
        itemBuilder: (context, index) {
          final alert = _emergencyAlerts[index];
          return _buildEmergencyLogCard(alert);
        },
      ),
    );
  }

  Widget _buildEmergencyLogCard(Map<String, dynamic> alert) {
    final String title = alert['title'] ?? '🚨 EMERGENCY ALERT';
    final String content = alert['content'] ?? '';
    final String dateStr = _formatDateTime(alert['created_at']?.toString());
    final String presetType = (alert['preset_type'] ?? 'CUSTOM').toString();
    final String broadcastedBy = alert['broadcasted_by'] ??
        (alert['sender'] != null ? alert['sender']['name'] : 'School Admin');

    final Color themeColor = _getPresetColor(presetType);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeColor.withAlpha(50), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: themeColor.withAlpha(15),
            blurRadius: 12,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 13, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: themeColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: themeColor.withAlpha(60)),
                  ),
                  child: Text(
                    presetType.toUpperCase(),
                    style: TextStyle(
                      color: themeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: themeColor,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                content,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF334155),
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.campaign_outlined, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                const Text(
                  'BROADCASTED BY:',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0077BE).withAlpha(15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    broadcastedBy,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0077BE),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // NOTICES TAB
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildNoticesTab() {
    if (_notices.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadAllNotifications,
        color: const Color(0xFF0077BE),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0077BE).withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.campaign_outlined, size: 56, color: Color(0xFF0077BE)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No School Notices',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'School announcements and notices will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllNotifications,
      color: const Color(0xFF0077BE),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _notices.length,
        itemBuilder: (context, index) {
          final notice = _notices[index];
          return _buildNoticeCard(notice);
        },
      ),
    );
  }

  Widget _buildNoticeCard(Map<String, dynamic> notice) {
    final String title = notice['title'] ?? 'School Notice';
    final String content = notice['content'] ?? notice['message'] ?? '';
    final String category = (notice['category'] ?? 'General').toString();
    final String dateStr = _formatDateTime(notice['created_at']?.toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withAlpha(10),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0077BE).withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    category.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF0077BE),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(dateStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              content,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ERROR VIEW
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 56, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadAllNotifications,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0077BE),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
