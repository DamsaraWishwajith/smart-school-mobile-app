import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class SchoolFeesScreen extends StatefulWidget {
  const SchoolFeesScreen({super.key});

  @override
  State<SchoolFeesScreen> createState() => _SchoolFeesScreenState();
}

class _SchoolFeesScreenState extends State<SchoolFeesScreen> {
  List<Map<String, dynamic>> _pendingFees  = [];
  List<Map<String, dynamic>> _upcomingFees = [];
  List<Map<String, dynamic>> _paidFees     = [];
  bool   _isLoading      = true;
  String? _error;

  // "See More" toggles per section
  bool _showAllPending  = false;
  bool _showAllUpcoming = false;
  bool _showAllPaid     = false;
  static const int _previewCount = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFees());
  }

  Future<void> _loadFees() async {
    setState(() { _isLoading = true; _error = null; });

    try {
      final auth      = Provider.of<AuthProvider>(context, listen: false);
      final studentId = auth.user?.student?.id;

      if (studentId == null) {
        setState(() {
          _error = 'Student profile not found. Please contact admin.';
          _isLoading = false;
        });
        return;
      }

      final res = await ApiServices.getFees(studentId: studentId);

      if (res['success'] == true) {
        final rawData = res['data'];
        List<dynamic> list = rawData is List ? rawData : [];

        final pending  = <Map<String, dynamic>>[];
        final upcoming = <Map<String, dynamic>>[];
        final paid     = <Map<String, dynamic>>[];

        for (final item in list) {
          if (item is! Map<String, dynamic>) continue;
          final status = item['payment_status'] as String? ?? 'pending';
          if (status == 'completed') {
            paid.add(item);
          } else if (status == 'upcoming') {
            upcoming.add(item);
          } else {
            pending.add(item);
          }
        }

        setState(() {
          _pendingFees  = pending;
          _upcomingFees = upcoming;
          _paidFees     = paid;
          _isLoading    = false;
        });
      } else {
        setState(() {
          _error     = res['message'] ?? 'Failed to load fees.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  String _fmtDate(dynamic v) {
    if (v == null) return '—';
    try { return DateFormat('MMM dd, yyyy').format(DateTime.parse(v.toString())); }
    catch (_) { return v.toString(); }
  }

  String _fmtAmt(dynamic v) {
    final d = double.tryParse(v?.toString() ?? '') ?? 0;
    return 'LKR ${d.toStringAsFixed(2)}';
  }

  String _fmtMethod(dynamic v) {
    switch ((v ?? '').toString().toLowerCase()) {
      case 'cash':           return 'Cash';
      case 'card':           return 'Card';
      case 'bank_transfer':  return 'Bank Transfer';
      case 'digital_wallet': return 'Digital Wallet';
      default:               return 'Cash';
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Fees & Payments',
            style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: Stack(children: [
        _buildBg(),
        SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadFees,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0077BE))))
                : _error != null
                    ? _buildError()
                    : _buildContent(),
          ),
        ),
      ]),
    );
  }

  Widget _buildError() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.error_outline, size: 52, color: Color(0xFFD32F2F)),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 14)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadFees,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0077BE), foregroundColor: Colors.white),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final totalPending = _pendingFees.fold<double>(
        0, (s, f) => s + (double.tryParse(f['amount']?.toString() ?? '') ?? 0));

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 50),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Summary banner ───────────────────────────────────────────
        _glass(child: Row(children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0077BE).withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded,
                color: Color(0xFF0077BE), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Total Pending Amount',
                style: TextStyle(color: Colors.black54, fontSize: 12)),
            Text(_fmtAmt(totalPending),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                    color: Color(0xFF0077BE))),
            Text('${_pendingFees.length} pending • ${_paidFees.length} paid',
                style: const TextStyle(fontSize: 11, color: Colors.black45)),
          ])),
        ])),

        const SizedBox(height: 24),

        // ── Pending Fees ─────────────────────────────────────────────
        _sectionTitle('Pending Fees', Icons.warning_amber_rounded, const Color(0xFFD32F2F)),
        const SizedBox(height: 10),
        if (_pendingFees.isEmpty)
          _emptyCard('No pending fees. You are all caught up! ✅', const Color(0xFF4CAF50))
        else ...[
          ..._visibleItems(_pendingFees, _showAllPending).map(_buildPendingCard),
          if (_pendingFees.length > _previewCount)
            _seeMoreBtn(
              total: _pendingFees.length,
              expanded: _showAllPending,
              onTap: () => setState(() => _showAllPending = !_showAllPending),
            ),
        ],

        const SizedBox(height: 26),

        // ── Upcoming (next month) ─────────────────────────────────────
        if (_upcomingFees.isNotEmpty) ...[
          _sectionTitle('Upcoming Fees', Icons.calendar_month_rounded, const Color(0xFF0077BE)),
          const SizedBox(height: 10),
          ..._visibleItems(_upcomingFees, _showAllUpcoming).map(_buildUpcomingCard),
          if (_upcomingFees.length > _previewCount)
            _seeMoreBtn(
              total: _upcomingFees.length,
              expanded: _showAllUpcoming,
              onTap: () => setState(() => _showAllUpcoming = !_showAllUpcoming),
            ),
          const SizedBox(height: 26),
        ],

        // ── Payment History ───────────────────────────────────────────
        _sectionTitle('Payment History', Icons.history_rounded, const Color(0xFF4CAF50)),
        const SizedBox(height: 10),
        if (_paidFees.isEmpty)
          _emptyCard('No payment history found.', Colors.grey)
        else ...[
          ..._visibleItems(_paidFees, _showAllPaid).map(_buildHistoryCard),
          if (_paidFees.length > _previewCount)
            _seeMoreBtn(
              total: _paidFees.length,
              expanded: _showAllPaid,
              onTap: () => setState(() => _showAllPaid = !_showAllPaid),
            ),
        ],
      ]),
    );
  }

  // Returns first _previewCount items or all if expanded
  List<T> _visibleItems<T>(List<T> list, bool showAll) =>
      showAll ? list : list.take(_previewCount).toList();

  Widget _seeMoreBtn({required int total, required bool expanded, required VoidCallback onTap}) {
    final hidden = total - _previewCount;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 4, bottom: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0077BE).withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF0077BE).withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
              color: const Color(0xFF0077BE), size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              expanded ? 'See Less' : 'See $hidden More',
              style: const TextStyle(
                color: Color(0xFF0077BE),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String label, IconData icon, Color color) {
    return Row(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
    ]);
  }

  Widget _emptyCard(String msg, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(msg, textAlign: TextAlign.center,
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildPendingCard(Map<String, dynamic> fee) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: _glass(child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(fee['title']?.toString() ?? 'Fee',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 3),
            Row(children: [
              const Icon(Icons.calendar_today_rounded, size: 11, color: Color(0xFFD32F2F)),
              const SizedBox(width: 4),
              Text('Due: ${_fmtDate(fee['due_date'])}',
                  style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ]),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_fmtAmt(fee['amount']),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14,
                    color: Color(0xFFD32F2F))),
          ),
        ]),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFFFF9800).withOpacity(0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.3)),
          ),
          child: const Text('⚠ Please pay at the Admin counter or contact billing.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFFF9800), fontSize: 11, fontWeight: FontWeight.w500)),
        ),
      ])),
    );
  }

  Widget _buildUpcomingCard(Map<String, dynamic> fee) {
    // Visible from 1st of the upcoming month
    final visibleFrom = fee['visible_from']?.toString() ?? fee['due_date']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: _glass(child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF0077BE).withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.upcoming_rounded, color: Color(0xFF0077BE), size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(fee['title']?.toString() ?? 'Fee',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text('From ${_fmtDate(visibleFrom)} • Due ${_fmtDate(fee['due_date'])}',
              style: const TextStyle(color: Colors.black45, fontSize: 11)),
        ])),
        Text(_fmtAmt(fee['amount']),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                color: Color(0xFF0077BE))),
      ])),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> fee) {
    final payment     = fee['payment'] as Map<String, dynamic>?;
    final paymentDate = payment?['payment_date'] ?? fee['due_date'];
    final method      = payment?['payment_method'] ?? 'cash';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: _glass(padding: const EdgeInsets.all(14), child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(fee['title']?.toString() ?? 'Fee',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text('via ${_fmtMethod(method)} • ${_fmtDate(paymentDate)}',
              style: const TextStyle(color: Colors.black45, fontSize: 11)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(_fmtAmt(fee['amount']),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                  color: Color(0xFF4CAF50))),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('PAID',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50))),
          ),
        ]),
      ])),
    );
  }

  // ── helpers ────────────────────────────────────────────────────────

  Widget _buildBg() => Stack(children: [
    Positioned(
      top: -70, right: -70,
      child: Container(
        width: 280, height: 280,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [Color(0xFF00B4DB), Color(0xFF0077BE)]),
        ),
      ),
    ),
    Positioned(
      bottom: -60, left: -60,
      child: Container(
        width: 220, height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF4CAF50).withOpacity(0.07),
        ),
      ),
    ),
  ]);

  Widget _glass({required Widget child, EdgeInsets? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: padding ?? const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.72),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04),
                  blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
