import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../services/firebase_service.dart';
import '../admin_dashboard_overview/widgets/admin_scaffold.dart';

// ─── Restore Requests Screen ─────────────────────────────────────────────────
// Shows all pending WhatsApp-plan restore requests from clients.
// Admin verifies and fills in: plan type, plans used, plans pending.

class RestoreRequestsScreen extends StatefulWidget {
  const RestoreRequestsScreen({super.key});

  @override
  State<RestoreRequestsScreen> createState() => _RestoreRequestsScreenState();
}

class _RestoreRequestsScreenState extends State<RestoreRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = ['Pending', 'Approved', 'All'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Restore Requests',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Restore Requests',
                    style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A2E))),
                const SizedBox(height: 4),
                Text('WhatsApp plan migration requests from clients',
                    style: GoogleFonts.inter(
                        fontSize: 14, color: const Color(0xFF6B7280))),
              ],
            ),
          ),

          // ── Tabs ──────────────────────────────────────────────────────────
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            isScrollable: false,
            labelColor: const Color(0xFF1976D2),
            unselectedLabelColor: const Color(0xFF6B7280),
            indicatorColor: const Color(0xFF1976D2),
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
            tabs: _tabs.map((t) => Tab(text: t)).toList(),
          ),
          const Divider(height: 1),

          // ── Tab Views ─────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _RequestList(statusFilter: 'pending'),
                _RequestList(statusFilter: 'approved'),
                _RequestList(statusFilter: null),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Request list for a given status filter ────────────────────────────────
class _RequestList extends StatelessWidget {
  final String? statusFilter;
  const _RequestList({this.statusFilter});

  @override
  Widget build(BuildContext context) {
    // Load all docs ordered by requestedAt; filter by status client-side.
    // This avoids needing a composite index on (status, requestedAt).
    final Query q = FirebaseService.instance.db
        .collection('restoreRequests')
        .orderBy('requestedAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: q.snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        final allDocs = snap.data?.docs ?? [];
        // Client-side status filter
        final docs = statusFilter == null
            ? allDocs
            : allDocs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                return (data['status'] as String?) == statusFilter;
              }).toList();
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    size: 56, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  statusFilter == 'pending'
                      ? 'No pending requests'
                      : 'No requests found',
                  style: GoogleFonts.inter(
                      color: const Color(0xFF9CA3AF), fontSize: 15),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            return _RequestCard(docId: doc.id, data: data);
          },
        );
      },
    );
  }
}

// ─── Individual request card ──────────────────────────────────────────────
class _RequestCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  const _RequestCard({required this.docId, required this.data});

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String? ?? 'pending';
    final ts = data['requestedAt'] as Timestamp?;
    final dateStr = ts != null
        ? DateFormat('d MMM y, h:mm a').format(ts.toDate())
        : '—';

    Color statusColor;
    Color statusBg;
    IconData statusIcon;
    switch (status) {
      case 'approved':
        statusColor = const Color(0xFF059669);
        statusBg = const Color(0xFFD1FAE5);
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        statusColor = const Color(0xFFDC2626);
        statusBg = const Color(0xFFFEE2E2);
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = const Color(0xFFD97706);
        statusBg = const Color(0xFFFEF3C7);
        statusIcon = Icons.pending_rounded;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row: avatar + name + status chip ──────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF1976D2).withValues(alpha: 0.1),
                  child: Text(
                    (data['name'] as String? ?? '?').isNotEmpty
                        ? (data['name'] as String)[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Color(0xFF1976D2), fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] as String? ?? 'Unknown',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      Text(
                        data['email'] as String? ?? data['phone'] as String? ?? '',
                        style: GoogleFonts.inter(
                            color: const Color(0xFF6B7280), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 14),
                      const SizedBox(width: 4),
                      Text(status[0].toUpperCase() + status.substring(1),
                          style: GoogleFonts.inter(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // ── Plan details (if approved) ─────────────────────────────────
            if (status == 'approved') ...[
              Row(
                children: [
                  _DetailChip(
                    label: 'Plan',
                    value: data['planType'] as String? ?? '—',
                    icon: Icons.workspace_premium_rounded,
                    color: const Color(0xFF7C3AED),
                  ),
                  const SizedBox(width: 8),
                  _DetailChip(
                    label: 'Used',
                    value: '${data['plansUsed'] ?? 0}',
                    icon: Icons.check_rounded,
                    color: const Color(0xFF059669),
                  ),
                  const SizedBox(width: 8),
                  _DetailChip(
                    label: 'Pending',
                    value: '${data['plansPending'] ?? 0}',
                    icon: Icons.schedule_rounded,
                    color: const Color(0xFFD97706),
                  ),
                ],
              ),
              if ((data['adminNotes'] as String? ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Notes: ${data['adminNotes']}',
                  style: GoogleFonts.inter(
                      color: const Color(0xFF6B7280), fontSize: 12,
                      fontStyle: FontStyle.italic),
                ),
              ],
              const SizedBox(height: 10),
            ],

            // ── Footer: date + action button ──────────────────────────────
            Row(
              children: [
                Icon(Icons.access_time_rounded,
                    size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(dateStr,
                    style: GoogleFonts.inter(
                        color: const Color(0xFF9CA3AF), fontSize: 12)),
                const Spacer(),
                if (status == 'pending')
                  ElevatedButton.icon(
                    onPressed: () => _showApproveDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.edit_note_rounded, size: 16),
                    label: Text('Assign Plan',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showApproveDialog(BuildContext context) {
    final planTypeCtrl = TextEditingController();
    final usedCtrl = TextEditingController(text: '0');
    final pendingCtrl = TextEditingController(text: '0');
    final notesCtrl = TextEditingController();
    String selectedType = 'Regular';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setS) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text('Assign Plan Details',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, fontSize: 18)),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Client info summary
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person_rounded,
                              color: Color(0xFF6B7280), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${data['name']}  ·  ${data['phone'] ?? data['email'] ?? ''}',
                              style: GoogleFonts.inter(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Plan type selector
                    Text('Plan Type',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600, fontSize: 13,
                            color: const Color(0xFF374151))),
                    const SizedBox(height: 8),
                    Row(
                      children: ['Regular', 'Super'].map((type) {
                        final selected = selectedType == type;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setS(() {
                              selectedType = type;
                              planTypeCtrl.text = type;
                            }),
                            child: Container(
                              margin: EdgeInsets.only(
                                  right: type == 'Regular' ? 8 : 0),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFF1976D2)
                                    : const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFF1976D2)
                                      : const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    type == 'Super'
                                        ? Icons.workspace_premium_rounded
                                        : Icons.star_outline_rounded,
                                    size: 16,
                                    color: selected
                                        ? Colors.white
                                        : const Color(0xFF6B7280),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(type,
                                      style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          color: selected
                                              ? Colors.white
                                              : const Color(0xFF374151))),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Plans used / pending
                    Row(
                      children: [
                        Expanded(
                          child: _NumberField(
                            controller: usedCtrl,
                            label: 'Plans Used',
                            hint: '0',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _NumberField(
                            controller: pendingCtrl,
                            label: 'Plans Pending',
                            hint: '0',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Admin notes
                    Text('Admin Notes (optional)',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600, fontSize: 13,
                            color: const Color(0xFF374151))),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'e.g. Client confirmed on call, started 2023',
                        hintStyle: GoogleFonts.inter(
                            color: const Color(0xFF9CA3AF), fontSize: 13),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: Color(0xFFE5E7EB))),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel',
                    style: GoogleFonts.inter(color: const Color(0xFF6B7280))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                onPressed: () async {
                  await _approveRequest(
                    planType: selectedType,
                    plansUsed: int.tryParse(usedCtrl.text) ?? 0,
                    plansPending: int.tryParse(pendingCtrl.text) ?? 0,
                    adminNotes: notesCtrl.text.trim(),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Text('Approve & Save',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _approveRequest({
    required String planType,
    required int plansUsed,
    required int plansPending,
    required String adminNotes,
  }) async {
    try {
      final batch = FirebaseService.instance.db.batch();

      // 1. Update the restore request doc
      final reqRef = FirebaseService.instance.db
          .collection('restoreRequests')
          .doc(docId);
      batch.update(reqRef, {
        'status':       'approved',
        'planType':     planType,
        'plansUsed':    plansUsed,
        'plansPending': plansPending,
        'adminNotes':   adminNotes,
        'resolvedAt':   FieldValue.serverTimestamp(),
      });

      // 2. Update the client's Firestore profile with the plan details
      final uid = data['uid'] as String? ?? '';
      if (uid.isNotEmpty) {
        final clientRef = FirebaseService.instance.clients.doc(uid);
        batch.set(clientRef, {
          'whatsappPlanType':     planType,
          'whatsappPlansUsed':    plansUsed,
          'whatsappPlansPending': plansPending,
          'whatsappMigrated':     true,
          'subscriptionPlan':     planType.toLowerCase(),
          'subscriptionStatus':   plansPending > 0 ? 'active' : 'completed',
          'updatedAt':            FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Approve restore error: $e');
    }
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _DetailChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _DetailChip(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text('$label: ',
              style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFF6B7280))),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  const _NumberField(
      {required this.controller, required this.label, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: const Color(0xFF374151))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
                color: const Color(0xFF9CA3AF), fontSize: 13),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}
