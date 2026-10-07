import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class EmergencyAlertScreen extends StatefulWidget {
  const EmergencyAlertScreen({super.key});

  @override
  State<EmergencyAlertScreen> createState() => _EmergencyAlertScreenState();
}

class _EmergencyAlertScreenState extends State<EmergencyAlertScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _customTitleController = TextEditingController();
  final _customContentController = TextEditingController();
  
  bool _isSending = false;
  bool _isLoadingHistory = false;
  List<dynamic> _historyAlerts = [];

  final List<Map<String, String>> _presets = [
    {
      'preset_type': 'fire',
      'title': '🚨 EMERGENCY ALERT: 🔥 FIRE EVACUATION ALARM',
      'content': 'Fire emergency reported on school grounds! Evacuate immediately via designated emergency exits!',
      'icon': '🔥',
      'label': 'Fire Evacuation',
      'description': 'Immediate evacuation order for all buildings',
      'color': '0xFFD32F2F',
    },
    {
      'preset_type': 'weather',
      'title': '🚨 EMERGENCY ALERT: ⛈️ SEVERE WEATHER EMERGENCY',
      'content': 'A Severe Weather & Heavy Storm alert has been issued. All students & staff move indoors immediately!',
      'icon': '⛈️',
      'label': 'Severe Weather',
      'description': 'Heavy storm or flood warning alert',
      'color': '0xFFF57C00',
    },
    {
      'preset_type': 'lockdown',
      'title': '🚨 EMERGENCY ALERT: 🔒 School SECURITY LOCKDOWN',
      'content': 'Security emergency on School grounds. Stay inside your classrooms, lock doors, and await instructions!',
      'icon': '🔒',
      'label': 'School Lockdown',
      'description': 'Stay indoors and secure all entry doors',
      'color': '0xFFC2185B',
    },
    {
      'preset_type': 'medical',
      'title': '🚨 EMERGENCY ALERT: 🚑 MEDICAL EMERGENCY ALERT',
      'content': 'Medical emergency reported on school premises. First aid responders report immediately!',
      'icon': '🚑',
      'label': 'Medical Emergency',
      'description': 'First aid responders & medical assistance',
      'color': '0xFF1976D2',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customTitleController.dispose();
    _customContentController.dispose();
    super.dispose();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoadingHistory = true);
    final response = await ApiServices.getEmergencyAlerts();
    if (mounted) {
      setState(() {
        _isLoadingHistory = false;
        if (response['success'] == true) {
          final data = response['data'];
          if (data is List) {
            _historyAlerts = data;
          }
        }
      });
    }
  }

  Future<void> _sendAlert(String title, String content, String presetType) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Confirm Emergency Broadcast',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to broadcast this Emergency Alert to ALL Students & Teachers?\n\nTitle: $title',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('BROADCAST NOW', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSending = true);

    final res = await ApiServices.sendEmergencyAlert(
      title: title,
      content: content,
      presetType: presetType,
    );

    if (mounted) {
      setState(() => _isSending = false);

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🚨 Emergency Alert Broadcasted Successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        _customTitleController.clear();
        _customContentController.clear();
        _fetchHistory();
        _tabController.animateTo(1);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Failed to send emergency alert'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final isAuthorized = user?.role.toLowerCase() == 'admin' || user?.role.toLowerCase() == 'teacher';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
        title: Row(
          children: const [
            Icon(Icons.shield_outlined, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Emergency Broadcast Center',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          tabs: const [
            Tab(icon: Icon(Icons.campaign), text: 'Broadcast Alert'),
            Tab(icon: Icon(Icons.history), text: 'Alert History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Broadcast Alert
          _buildBroadcastTab(isAuthorized),

          // Tab 2: Alert History
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildBroadcastTab(bool isAuthorized) {
    if (!isAuthorized) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Broadcast Restricted',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              SizedBox(height: 8),
              Text(
                'Only Admins and Teachers can trigger emergency broadcasts. You can view past emergency alerts in the History tab.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Warning
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFCDD2)),
            ),
            child: Row(
              children: const [
                Icon(Icons.warning_rounded, color: Colors.red, size: 30),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Emergency alerts send instant high-priority notifications & alarm sounds to ALL mobile apps.',
                    style: TextStyle(color: Color(0xFFB71C1C), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Text(
            'Quick Emergency Presets',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 12),

          // Presets Grid
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _presets.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final p = _presets[index];
              final color = Color(int.parse(p['color']!));

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withAlpha(20),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: color.withAlpha(50), width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: Text(p['icon']!, style: const TextStyle(fontSize: 26)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p['label']!,
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              p['description']!,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isSending ? null : () => _sendAlert(p['title']!, p['content']!, p['preset_type']!),
                        child: const Text('TRIGGER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),
          const Text(
            'Custom Emergency Alert',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 12),

          // Custom Form Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _customTitleController,
                  decoration: InputDecoration(
                    labelText: 'Emergency Title',
                    hintText: 'e.g. Chemical Spill in Lab 3',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.title, color: Colors.red),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _customContentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Emergency Instructions / Details',
                    hintText: 'Provide clear emergency instructions for students and staff...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.description, color: Colors.red),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.send_rounded),
                    label: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('BROADCAST CUSTOM ALERT', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _isSending
                        ? null
                        : () {
                            if (_customTitleController.text.trim().isEmpty ||
                                _customContentController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please fill in title and description')),
                              );
                              return;
                            }
                            _sendAlert(
                              _customTitleController.text.trim(),
                              _customContentController.text.trim(),
                              'custom',
                            );
                          },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return RefreshIndicator(
      onRefresh: _fetchHistory,
      child: _isLoadingHistory
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : _historyAlerts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No Emergency Alerts Sent', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _historyAlerts.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final alert = _historyAlerts[index];
                    final title = alert['title'] ?? 'Emergency Alert';
                    final content = alert['content'] ?? '';
                    final sender = alert['posted_by']?['name'] ?? 'Admin';
                    final date = alert['created_at'] != null ? alert['created_at'].toString().split('T')[0] : '';

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.red.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withAlpha(10),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
                        ),
                        title: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(content, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('By: $sender', style: TextStyle(fontSize: 11, color: Colors.red.shade700, fontWeight: FontWeight.w600)),
                                Text(date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
