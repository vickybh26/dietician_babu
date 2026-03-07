import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../services/firebase_service.dart';
import '../admin_dashboard_overview/widgets/admin_scaffold.dart';

class SubscriptionsManagement extends StatefulWidget {
  const SubscriptionsManagement({super.key});

  @override
  State<SubscriptionsManagement> createState() => _SubscriptionsManagementState();
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
        final subStatus = clientData['subscriptionStatus'] as String? ?? 'none';
        if (subStatus == 'none') continue; // skip unsubscribed

        // Fetch user name
        final userSnap = await _fs.users.doc(doc.id).get();
        final userData = userSnap.data() ?? {};

        final expiresAt = clientData['subscriptionExpiresAt'] is Timestamp
            ? (clientData['subscriptionExpiresAt'] as Timestamp).toDate()
            : null;

        final now = DateTime.now();
        String status = subStatus;
        if (expiresAt != null && expiresAt.isBefore(now)) {
          status = 'expired';
        }

        subs.add({
          'uid': doc.id,
          'name': userData['displayName'] ?? userData['name'] ?? userData['email'] ?? 'Unknown',
          'email': userData['email'] ?? '',
          'plan': clientData['subscriptionPlan'] ?? 'Unknown',
          'status': status,
          'expiresAt': expiresAt,
          'daysLeft': expiresAt != null ? expiresAt.difference(now).inDays : null,
        });
      }

      // Sort: active first, then expiring soon, then expired
      subs.sort((a, b) {
        if (a['status'] == 'active' && b['status'] != 'active') return -1;
        if (a['status'] != 'active' && b['status'] == 'active') return 1;
        return 0;
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
          : _subscriptions.where((s) => s['status'] == _filterStatus.toLowerCase()).toList();
    });
  }

  Future<void> _extendSubscription(String uid, String name) async {
    final days = await showDialog<int>(
      context: context,
      builder: (ctx) {
        int selected = 30;
        return StatefulBuilder(builder: (ctx, set) => AlertDialog(
          title: Text('Extend Subscription for $name'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [30, 60, 90].map((d) => RadioListTile<int>(
              value: d,
              groupValue: selected,
              title: Text('$d days'),
              onChanged: (v) => set(() => selected = v!),
            )).toList(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, selected),
              child: const Text('Extend'),
            ),
          ],
        ));
      },
    );

    if (days != null) {
      final clientSnap = await _fs.clients.doc(uid).get();
      final existing = clientSnap.data()?['subscriptionExpiresAt'];
      final base = existing is Timestamp && existing.toDate().isAfter(DateTime.now())
          ? existing.toDate()
          : DateTime.now();
      final newExpiry = base.add(Duration(days: days));

      await _fs.clients.doc(uid).set({
        'subscriptionStatus': 'active',
        'subscriptionExpiresAt': Timestamp.fromDate(newExpiry),
      }, SetOptions(merge: true));

      _loadSubscriptions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Subscription extended by $days days')),
        );
      }
    }
  }

  Future<void> _cancelSubscription(String uid, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: Text('Cancel subscription for $name?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _fs.clients.doc(uid).set({'subscriptionStatus': 'inactive'}, SetOptions(merge: true));
      _loadSubscriptions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subscription cancelled')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _subscriptions.where((s) => s['status'] == 'active').length;
    final expiring = _subscriptions.where((s) {
      final d = s['daysLeft'] as int?;
      return d != null && d >= 0 && d <= 7;
    }).length;
    final expired = _subscriptions.where((s) => s['status'] == 'expired').length;

    return AdminScaffold(
      title: 'Subscriptions',
      body: Column(
        children: [
          _buildHeader(active, expiring, expired),
          _buildFilterRow(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(child: Text('No subscriptions found', style: GoogleFonts.inter(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filtered.length,
                        itemBuilder: (ctx, i) => _buildSubCard(_filtered[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int active, int expiring, int expired) {
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
                    Text('Subscriptions', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                    Text('Manage all client subscription plans', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600])),
                  ],
                ),
              ),
              IconButton(onPressed: _loadSubscriptions, icon: const Icon(Icons.refresh)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _chip('Active', '$active', Colors.green),
              _chip('Expiring Soon', '$expiring', Colors.orange),
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
      child: Text('$count $label', style: GoogleFonts.inter(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildFilterRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: Row(
        children: ['All', 'Active', 'Expired', 'Inactive'].map((f) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(f),
            selected: _filterStatus == f,
            onSelected: (_) {
              _filterStatus = f;
              _applyFilter();
            },
            selectedColor: const Color(0xFF61b239),
            labelStyle: TextStyle(color: _filterStatus == f ? Colors.white : Colors.grey[700]),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildSubCard(Map<String, dynamic> sub) {
    final status = sub['status'] as String;
    final daysLeft = sub['daysLeft'] as int?;
    final expiresAt = sub['expiresAt'] as DateTime?;

    Color statusColor;
    String statusLabel;
    if (status == 'active' && daysLeft != null && daysLeft <= 7) {
      statusColor = Colors.orange;
      statusLabel = 'Expiring in $daysLeft days';
    } else if (status == 'active') {
      statusColor = Colors.green;
      statusLabel = 'Active';
    } else if (status == 'expired') {
      statusColor = Colors.red;
      statusLabel = 'Expired';
    } else {
      statusColor = Colors.grey;
      statusLabel = status.toUpperCase();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: statusColor.withOpacity(0.1),
              child: Text(
                (sub['name'] as String).isNotEmpty ? sub['name'][0].toUpperCase() : '?',
                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sub['name'], style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  Text(sub['email'], style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1976D2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(sub['plan'] ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFF1976D2))),
                      ),
                      const SizedBox(width: 8),
                      if (expiresAt != null)
                        Text('Expires: ${DateFormat('dd MMM yyyy').format(expiresAt)}',
                            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(statusLabel, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => _extendSubscription(sub['uid'], sub['name']),
                      child: const Text('Extend', style: TextStyle(fontSize: 12)),
                    ),
                    TextButton(
                      onPressed: () => _cancelSubscription(sub['uid'], sub['name']),
                      child: const Text('Cancel', style: TextStyle(fontSize: 12, color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
