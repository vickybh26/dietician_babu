import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../services/firebase_service.dart';
import '../admin_dashboard_overview/widgets/admin_scaffold.dart';

class SubscriptionsManagement extends StatefulWidget {
  const SubscriptionsManagement({super.key});

  @override
  State<SubscriptionsManagement> createState() =>
      _SubscriptionsManagementState();
}

class _SubscriptionsManagementState extends State<SubscriptionsManagement> {
  final _fs = FirebaseService.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _subscriptions = [];
  List<Map<String, dynamic>> _filtered = [];
  String _filterStatus = 'All';

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    setState(() => _isLoading = true);
    try {
      final clientsSnap = await _fs.clients.get();
      final List<Map<String, dynamic>> subs = [];

      for (final doc in clientsSnap.docs) {
        final clientData = doc.data();
        final subStatus =
            clientData['subscriptionStatus'] as String? ?? 'none';
        if (subStatus == 'none') continue;

        final userSnap = await _fs.users.doc(doc.id).get();
        final userData = userSnap.data() ?? {};

        final expiresAt = clientData['subscriptionExpiresAt'] is Timestamp
            ? (clientData['subscriptionExpiresAt'] as Timestamp).toDate()
            : null;

        final now = DateTime.now();
        String status = subStatus;
        if (subStatus == 'active' && expiresAt != null && expiresAt.isBefore(now)) {
          status = 'expired';
        }

        subs.add({
          'uid': doc.id,
          'name': userData['displayName'] ??
              userData['name'] ??
              userData['email'] ??
              'Unknown',
          'email': userData['email'] ?? '',
          'plan': clientData['subscriptionPlan'] ?? 'Unknown',
          'status': status,
          'expiresAt': expiresAt,
          'daysLeft': expiresAt != null
              ? expiresAt.difference(now).inDays
              : null,
          'pausedDaysRemaining':
              clientData['pausedDaysRemaining'] as int? ?? 0,
        });
      }

      subs.sort((a, b) {
        const order = {'active': 0, 'paused': 1, 'expired': 2, 'inactive': 3};
        return (order[a['status']] ?? 9)
            .compareTo(order[b['status']] ?? 9);
      });

      setState(() {
        _subscriptions = subs;
        _filtered = subs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading subscriptions: $e')),
        );
      }
    }
  }

  void _applyFilter() {
    setState(() {
      _filtered = _filterStatus == 'All'
          ? _subscriptions
          : _subscriptions
              .where(
                  (s) => s['status'] == _filterStatus.toLowerCase())
              .toList();
    });
  }

  // ─── Extend by weeks ────────────────────────────────────────────────────────

  Future<void> _extendSubscription(String uid, String name) async {
    const options = [1, 2, 3, 4, 6, 8, 12];
    final weeks = await showDialog<int>(
      context: context,
      builder: (ctx) {
        int selected = 4;
        return StatefulBuilder(
          builder: (ctx, set) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text('Extend Subscription',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Client: $name',
                    style: GoogleFonts.inter(
                        color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 12),
                Text('Extend by how many weeks?',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: options.map((w) {
                    final isSelected = selected == w;
                    return ChoiceChip(
                      label: Text('$w wk${w > 1 ? 's' : ''}'),
                      selected: isSelected,
                      onSelected: (_) => set(() => selected = w),
                      selectedColor: const Color(0xFF1976D2).withOpacity(0.15),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? const Color(0xFF1976D2)
                            : Colors.grey.shade700,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF1976D2)
                            : Colors.grey.shade300,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Text(
                  '= ${selected * 7} days',
                  style: GoogleFonts.inter(
                      color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, selected),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white),
                child: const Text('Extend'),
              ),
            ],
          ),
        );
      },
    );

    if (weeks != null) {
      final days = weeks * 7;
      final clientSnap = await _fs.clients.doc(uid).get();
      final existing = clientSnap.data()?['subscriptionExpiresAt'];
      final base =
          existing is Timestamp && existing.toDate().isAfter(DateTime.now())
              ? existing.toDate()
              : DateTime.now();
      final newExpiry = base.add(Duration(days: days));

      await _fs.clients.doc(uid).set({
        'subscriptionStatus': 'active',
        'subscriptionExpiresAt': Timestamp.fromDate(newExpiry),
        // Clear any pause data
        'pausedDaysRemaining': FieldValue.delete(),
        'pausedAt': FieldValue.delete(),
      }, SetOptions(merge: true));

      _loadSubscriptions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Extended by $weeks week${weeks > 1 ? 's' : ''} ($days days)')),
        );
      }
    }
  }

  // ─── Pause ──────────────────────────────────────────────────────────────────

  Future<void> _pauseSubscription(
      String uid, String name, DateTime? expiresAt) async {
    final now = DateTime.now();
    final remaining =
        expiresAt != null ? expiresAt.difference(now).inDays : 0;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Subscription is already expired, cannot pause')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Pause Subscription',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Client: $name',
                style: GoogleFonts.inter(
                    color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 12),
            Text(
              'This will pause $name\'s subscription. The remaining $remaining day${remaining != 1 ? 's' : ''} will be preserved and resumed when you unpause.',
              style:
                  GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade700),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white),
            child: const Text('Pause'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _fs.clients.doc(uid).set({
        'subscriptionStatus': 'paused',
        'pausedDaysRemaining': remaining,
        'pausedAt': FieldValue.serverTimestamp(),
        // Keep expiresAt for reference but status drives the UI
      }, SetOptions(merge: true));

      _loadSubscriptions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Subscription paused. $remaining days preserved.')),
        );
      }
    }
  }

  // ─── Resume ─────────────────────────────────────────────────────────────────

  Future<void> _resumeSubscription(
      String uid, String name, int pausedDays) async {
    if (pausedDays <= 0) {
      // Just reactivate without extra days
      await _fs.clients.doc(uid).set({
        'subscriptionStatus': 'active',
        'subscriptionExpiresAt':
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 1))),
        'pausedDaysRemaining': FieldValue.delete(),
        'pausedAt': FieldValue.delete(),
      }, SetOptions(merge: true));
    } else {
      final newExpiry =
          DateTime.now().add(Duration(days: pausedDays));
      await _fs.clients.doc(uid).set({
        'subscriptionStatus': 'active',
        'subscriptionExpiresAt': Timestamp.fromDate(newExpiry),
        'pausedDaysRemaining': FieldValue.delete(),
        'pausedAt': FieldValue.delete(),
      }, SetOptions(merge: true));
    }

    _loadSubscriptions();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Subscription resumed for $name. $pausedDays days restored.')),
      );
    }
  }

  // ─── Cancel ─────────────────────────────────────────────────────────────────

  Future<void> _cancelSubscription(String uid, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: Text('Cancel subscription for $name?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _fs.clients
          .doc(uid)
          .set({'subscriptionStatus': 'inactive'}, SetOptions(merge: true));
      _loadSubscriptions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subscription cancelled')));
      }
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final active =
        _subscriptions.where((s) => s['status'] == 'active').length;
    final paused =
        _subscriptions.where((s) => s['status'] == 'paused').length;
    final expiring = _subscriptions.where((s) {
      final d = s['daysLeft'] as int?;
      return s['status'] == 'active' && d != null && d >= 0 && d <= 7;
    }).length;
    final expired =
        _subscriptions.where((s) => s['status'] == 'expired').length;

    return AdminScaffold(
      title: 'Subscriptions',
      body: Column(
        children: [
          _buildHeader(active, paused, expiring, expired),
          _buildFilterRow(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Text('No subscriptions found',
                            style: GoogleFonts.inter(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filtered.length,
                        itemBuilder: (ctx, i) =>
                            _buildSubCard(_filtered[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
      int active, int paused, int expiring, int expired) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Subscriptions',
                        style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800])),
                    Text('Manage all client subscriptions',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: Colors.grey[600])),
                  ],
                ),
              ),
              IconButton(
                  onPressed: _loadSubscriptions,
                  icon: const Icon(Icons.refresh)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _chip('Active', '$active', Colors.green),
              if (paused > 0) _chip('Paused', '$paused', Colors.orange),
              if (expiring > 0)
                _chip('Expiring', '$expiring', Colors.amber.shade700),
              _chip('Expired', '$expired', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text('$count $label',
          style: GoogleFonts.inter(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildFilterRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ['All', 'Active', 'Paused', 'Expired', 'Inactive']
              .map((f) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: _filterStatus == f,
                      onSelected: (_) {
                        _filterStatus = f;
                        _applyFilter();
                      },
                      selectedColor: const Color(0xFF61b239),
                      labelStyle: TextStyle(
                          color: _filterStatus == f
                              ? Colors.white
                              : Colors.grey[700]),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildSubCard(Map<String, dynamic> sub) {
    final status = sub['status'] as String;
    final daysLeft = sub['daysLeft'] as int?;
    final expiresAt = sub['expiresAt'] as DateTime?;
    final pausedDays = sub['pausedDaysRemaining'] as int? ?? 0;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (status) {
      case 'paused':
        statusColor = Colors.orange;
        statusLabel = 'Paused ($pausedDays days left)';
        statusIcon = Icons.pause_circle_outline;
        break;
      case 'active' when daysLeft != null && daysLeft <= 7:
        statusColor = Colors.amber.shade700;
        statusLabel = 'Expiring in $daysLeft days';
        statusIcon = Icons.warning_amber_outlined;
        break;
      case 'active':
        statusColor = Colors.green;
        statusLabel = 'Active';
        statusIcon = Icons.check_circle_outline;
        break;
      case 'expired':
        statusColor = Colors.red;
        statusLabel = 'Expired';
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = status.toUpperCase();
        statusIcon = Icons.circle_outlined;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.1),
                  child: Text(
                    (sub['name'] as String).isNotEmpty
                        ? sub['name'][0].toUpperCase()
                        : '?',
                    style: TextStyle(
                        color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sub['name'],
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600)),
                      Text(sub['email'],
                          style: GoogleFonts.inter(
                              fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1976D2).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(sub['plan'] ?? '',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF1976D2))),
                          ),
                          const SizedBox(width: 8),
                          if (expiresAt != null && status != 'paused')
                            Text(
                                'Exp: ${DateFormat('dd MMM yy').format(expiresAt)}',
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.grey[500])),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon,
                          size: 13, color: statusColor),
                      const SizedBox(width: 4),
                      Text(statusLabel,
                          style: TextStyle(
                              fontSize: 11,
                              color: statusColor,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),

            // Action buttons
            const SizedBox(height: 10),
            Row(
              children: [
                // Extend button (always)
                _actionButton(
                  label: 'Extend',
                  icon: Icons.add_circle_outline,
                  color: const Color(0xFF1976D2),
                  onTap: () =>
                      _extendSubscription(sub['uid'], sub['name']),
                ),
                const SizedBox(width: 8),

                // Pause / Resume depending on status
                if (status == 'paused')
                  _actionButton(
                    label: 'Resume',
                    icon: Icons.play_circle_outline,
                    color: Colors.green,
                    onTap: () => _resumeSubscription(
                        sub['uid'], sub['name'], pausedDays),
                  )
                else if (status == 'active')
                  _actionButton(
                    label: 'Pause',
                    icon: Icons.pause_circle_outline,
                    color: Colors.orange,
                    onTap: () => _pauseSubscription(
                        sub['uid'], sub['name'], expiresAt),
                  ),

                const Spacer(),

                // Cancel (only for active/paused)
                if (status == 'active' || status == 'paused')
                  TextButton(
                    onPressed: () =>
                        _cancelSubscription(sub['uid'], sub['name']),
                    child: const Text('Cancel',
                        style:
                            TextStyle(fontSize: 12, color: Colors.red)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
