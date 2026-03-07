import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../services/firebase_service.dart';
import '../../routes/app_routes.dart';
import '../admin_dashboard_overview/widgets/admin_scaffold.dart';

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
      for (final doc in plansSnap.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;

        // Fetch client name
        final clientId = data['clientId'] as String?;
        if (clientId != null) {
          final userSnap = await _fs.users.doc(clientId).get();
          data['clientName'] = userSnap.data()?['displayName'] ??
              userSnap.data()?['name'] ??
              userSnap.data()?['email'] ??
              'Unknown';
        } else {
          data['clientName'] = 'Unknown';
        }

        plans.add(data);
      }

      setState(() {
        _plans = plans;
        _filteredPlans = plans;
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
        final matchesSearch = _searchQuery.isEmpty ||
            (plan['title'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (plan['clientName'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesType = _filterType == 'All' ||
            (plan['type'] ?? '') == _filterType ||
            (plan['format'] == 'structured' && _filterType == 'AI Generated') ||
            (plan['format'] != 'structured' && _filterType == 'PDF');
        return matchesSearch && matchesType;
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

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Diet Plans',
      body: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Diet Plans', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                Text('${_plans.length} plans created', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600])),
              ],
            ),
          ),
          IconButton(onPressed: _loadPlans, icon: const Icon(Icons.refresh), tooltip: 'Refresh'),
          const SizedBox(width: 4),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.adminDietPlanCreator).then((_) => _loadPlans()),
            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
            label: const Text('Create AI Plan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF61b239),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
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
                hintText: 'Search by client or plan name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
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

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final isAI = plan['format'] == 'structured' || plan['type'] == 'AI Generated';
    final uploadedAt = plan['uploadedAt'] is Timestamp
        ? (plan['uploadedAt'] as Timestamp).toDate()
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isAI ? const Color(0xFF61b239).withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isAI ? Icons.auto_awesome_rounded : Icons.picture_as_pdf,
                color: isAI ? const Color(0xFF61b239) : Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
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
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isAI ? const Color(0xFF61b239).withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isAI ? 'AI Generated' : 'PDF',
                          style: TextStyle(
                            fontSize: 11,
                            color: isAI ? const Color(0xFF61b239) : Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(plan['clientName'] ?? '', style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13)),
                      const SizedBox(width: 16),
                      if (uploadedAt != null) ...[
                        const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(DateFormat('dd MMM yyyy').format(uploadedAt),
                            style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ],
                  ),
                  if (plan['notes'] != null && plan['notes'].toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(plan['notes'], style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            // Actions
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deletePlan(plan['id'], plan['title'] ?? 'Untitled'),
              tooltip: 'Delete Plan',
            ),
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
          Text('No plans yet', style: GoogleFonts.inter(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.adminDietPlanCreator),
            icon: const Icon(Icons.add),
            label: const Text('Create First Plan'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF61b239), foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}
