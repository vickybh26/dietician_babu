import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../services/firebase_service.dart';
import '../../routes/app_routes.dart';
import '../admin_dashboard_overview/widgets/admin_scaffold.dart';
import '../admin_diet_plan_creator/admin_diet_plan_creator.dart'
    show tagColor;

class DietPlansManagement extends StatefulWidget {
  const DietPlansManagement({super.key});

  @override
  State<DietPlansManagement> createState() => _DietPlansManagementState();
}

class _DietPlansManagementState extends State<DietPlansManagement> {
  final _fs = FirebaseService.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _plans = [];
  List<Map<String, dynamic>> _filteredPlans = [];
  String _searchQuery = '';
  String _filterType = 'All';
  String? _filterTag; // null = no tag filter

  // All unique tags found across plans
  List<String> _allTags = [];

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() => _isLoading = true);
    try {
      final plansSnap = await _fs.plans
          .orderBy('uploadedAt', descending: true)
          .get();

      final List<Map<String, dynamic>> plans = [];
      final Set<String> tagsSet = {};

      for (final doc in plansSnap.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;

        // Fetch client name (clientId is optional now)
        final clientId = data['clientId'] as String?;
        if (clientId != null) {
          final userSnap = await _fs.users.doc(clientId).get();
          data['clientName'] = userSnap.data()?['displayName'] ??
              userSnap.data()?['name'] ??
              userSnap.data()?['email'] ??
              'Client';
        } else {
          data['clientName'] = null; // unassigned
        }

        // Collect tags
        final tags = (data['tags'] as List?)?.cast<String>() ?? [];
        tagsSet.addAll(tags);

        plans.add(data);
      }

      setState(() {
        _plans = plans;
        _filteredPlans = plans;
        _allTags = tagsSet.toList()..sort();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading plans: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredPlans = _plans.where((plan) {
        final tags = (plan['tags'] as List?)?.cast<String>() ?? [];

        final matchesSearch = _searchQuery.isEmpty ||
            (plan['title'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (plan['clientName'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
            tags.any((t) => t.toLowerCase().contains(_searchQuery.toLowerCase()));

        final matchesType = _filterType == 'All' ||
            (plan['format'] == 'structured' && _filterType == 'AI Generated') ||
            (plan['format'] != 'structured' && _filterType == 'PDF');

        final matchesTag = _filterTag == null || tags.contains(_filterTag);

        return matchesSearch && matchesType && matchesTag;
      }).toList();
    });
  }

  Future<void> _deletePlan(String planId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Plan'),
        content: Text('Delete "$title"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _fs.plans.doc(planId).delete();
      _loadPlans();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan deleted')),
        );
      }
    }
  }

  /// Assign an existing plan to a client
  Future<void> _assignToClient(String planId) async {
    final clientsSnap = await _fs.clients.get();
    if (!mounted) return;

    // Build client list
    final clients = <Map<String, dynamic>>[];
    for (final doc in clientsSnap.docs) {
      final userSnap = await _fs.users.doc(doc.id).get();
      final name = userSnap.data()?['displayName'] ??
          userSnap.data()?['email'] ??
          doc.id;
      clients.add({'uid': doc.id, 'name': name});
    }

    if (!mounted) return;

    final selectedUid = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign to Client'),
        content: SizedBox(
          width: 300,
          child: clients.isEmpty
              ? const Text('No clients found.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: clients.length,
                  itemBuilder: (_, i) => ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(clients[i]['name']),
                    onTap: () => Navigator.pop(ctx, clients[i]['uid']),
                  ),
                ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
        ],
      ),
    );

    if (selectedUid != null) {
      await _fs.plans.doc(planId).set(
          {'clientId': selectedUid}, SetOptions(merge: true));
      await _fs.clients.doc(selectedUid).set({
        'currentPlanId': planId,
        'planAssignedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _loadPlans();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan assigned to client')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Diet Plans',
      body: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          if (_allTags.isNotEmpty) _buildTagFilterRow(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPlans.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredPlans.length,
                        itemBuilder: (ctx, i) => _buildPlanCard(_filteredPlans[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final unassigned = _plans.where((p) => p['clientName'] == null).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Diet Plans',
                        style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800])),
                    Text(
                      '${_plans.length} plans  •  $unassigned unassigned',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              IconButton(
                  onPressed: _loadPlans,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh'),
              const SizedBox(width: 4),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(
                        context, AppRoutes.adminDietPlanCreator)
                    .then((_) => _loadPlans()),
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text('Create AI Plan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF61b239),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey[100],
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (v) {
                _searchQuery = v;
                _applyFilters();
              },
              decoration: InputDecoration(
                hintText: 'Search by title, client or tag...',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: _filterType,
            items: ['All', 'AI Generated', 'PDF']
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) {
              _filterType = v!;
              _applyFilters();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTagFilterRow() {
    return Container(
      height: 40,
      color: Colors.grey[50],
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: const Text('All Tags'),
              selected: _filterTag == null,
              onSelected: (_) { _filterTag = null; _applyFilters(); },
              selectedColor: Colors.grey.shade300,
              labelStyle: TextStyle(
                  fontSize: 11,
                  color: _filterTag == null ? Colors.black : Colors.grey),
            ),
          ),
          ..._allTags.map((tag) {
            final color = tagColor(tag);
            final selected = _filterTag == tag;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(tag),
                selected: selected,
                onSelected: (_) {
                  _filterTag = selected ? null : tag;
                  _applyFilters();
                },
                selectedColor: color.withOpacity(0.15),
                labelStyle: TextStyle(
                    fontSize: 11,
                    color: selected ? color : Colors.grey.shade700,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.normal),
                side: BorderSide(
                    color: selected ? color : Colors.grey.shade300),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final isAI = plan['format'] == 'structured' || plan['type'] == 'AI Generated';
    final uploadedAt = plan['uploadedAt'] is Timestamp
        ? (plan['uploadedAt'] as Timestamp).toDate()
        : null;
    final tags = (plan['tags'] as List?)?.cast<String>() ?? [];
    final clientName = plan['clientName'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isAI
                        ? const Color(0xFF61b239).withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isAI ? Icons.auto_awesome_rounded : Icons.picture_as_pdf,
                    color: isAI ? const Color(0xFF61b239) : Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              plan['title'] ?? 'Untitled Plan',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isAI
                                  ? const Color(0xFF61b239).withOpacity(0.1)
                                  : Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isAI ? 'AI' : 'PDF',
                              style: TextStyle(
                                fontSize: 11,
                                color: isAI
                                    ? const Color(0xFF61b239)
                                    : Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            clientName != null
                                ? Icons.person_outline
                                : Icons.person_off_outlined,
                            size: 14,
                            color: clientName != null
                                ? Colors.grey
                                : Colors.orange.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            clientName ?? 'Unassigned',
                            style: GoogleFonts.inter(
                              color: clientName != null
                                  ? Colors.grey[600]
                                  : Colors.orange.shade600,
                              fontSize: 13,
                              fontWeight: clientName == null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          if (uploadedAt != null) ...[
                            const SizedBox(width: 12),
                            const Icon(Icons.calendar_today_outlined,
                                size: 13, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd MMM yyyy').format(uploadedAt),
                              style: GoogleFonts.inter(
                                  color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Actions
                PopupMenuButton<String>(
                  onSelected: (action) {
                    if (action == 'delete') {
                      _deletePlan(plan['id'], plan['title'] ?? 'Untitled');
                    } else if (action == 'assign') {
                      _assignToClient(plan['id']);
                    }
                  },
                  itemBuilder: (_) => [
                    if (clientName == null)
                      const PopupMenuItem(
                        value: 'assign',
                        child: Row(children: [
                          Icon(Icons.person_add_alt_1_outlined,
                              size: 18, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Assign to Client'),
                        ]),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline,
                            size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete',
                            style: TextStyle(color: Colors.red)),
                      ]),
                    ),
                  ],
                  child: const Icon(Icons.more_vert,
                      color: Colors.grey, size: 20),
                ),
              ],
            ),

            // Tags
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: tags.map((tag) {
                  final color = tagColor(tag);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: color.withOpacity(0.25)),
                    ),
                    child: Text(tag,
                        style: TextStyle(
                            fontSize: 10,
                            color: color,
                            fontWeight: FontWeight.w600)),
                  );
                }).toList(),
              ),
            ],

            // Notes
            if (plan['notes'] != null &&
                plan['notes'].toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(plan['notes'],
                  style: GoogleFonts.inter(
                      color: Colors.grey[500], fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('No plans yet',
              style: GoogleFonts.inter(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(
                context, AppRoutes.adminDietPlanCreator),
            icon: const Icon(Icons.add),
            label: const Text('Create First Plan'),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF61b239),
                foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}
