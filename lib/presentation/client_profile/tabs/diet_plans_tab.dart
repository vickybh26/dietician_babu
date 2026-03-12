import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../services/client_profile_service.dart';
import '../../../routes/app_routes.dart';

/// Tab 2 — Assigned Diet Plans
/// Streams plans from plans/{planId} where clientId == uid.
class DietPlansTab extends StatelessWidget {
  final String clientId;

  const DietPlansTab({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ClientProfileService.streamClientPlans(clientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final plans = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, plans.length),
            if (plans.isEmpty)
              _buildEmpty()
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: plans.length,
                  itemBuilder: (context, index) =>
                      _PlanCard(plan: plans[index], clientId: clientId),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          Text(
            'Assigned Plans ($count)',
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900]),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.adminDietPlanCreator),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Create Plan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu_outlined,
                size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No plans assigned yet',
                style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[500])),
            const SizedBox(height: 8),
            Text('Create a diet plan and assign it to this client.',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final String clientId;

  const _PlanCard({required this.plan, required this.clientId});

  String _formatDate(dynamic ts) {
    if (ts == null) return 'N/A';
    try {
      final dt = (ts as Timestamp).toDate();
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return 'N/A';
    }
  }

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'ai':
        return const Color(0xFF7C3AED);
      case 'pdf':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF0288D1);
    }
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'ai':
        return Icons.auto_awesome_outlined;
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = plan['type'] ?? 'manual';
    final isActive = plan['isActive'] == true;
    final status = plan['status'] ?? 'active';
    final isArchived = status == 'archived';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? const Color(0xFF1976D2).withOpacity(0.4)
              : Colors.grey[200]!,
          width: isActive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Type icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _typeColor(type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_typeIcon(type), color: _typeColor(type), size: 22),
            ),
            const SizedBox(width: 16),

            // Plan details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          plan['title'] ?? 'Unnamed Plan',
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[900]),
                        ),
                      ),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Text('ACTIVE',
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.green)),
                        ),
                      if (isArchived)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('ARCHIVED',
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _badge(type.toUpperCase(), _typeColor(type)),
                      const SizedBox(width: 8),
                      Text(
                        'Assigned: ${_formatDate(plan['uploadedAt'])}',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  if (plan['description'] != null &&
                      (plan['description'] as String).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        plan['description'],
                        style: GoogleFonts.inter(
                            fontSize: 12, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),

            // Actions
            PopupMenuButton<String>(
              onSelected: (value) => _handleAction(context, value),
              itemBuilder: (_) => [
                if (!isActive && !isArchived)
                  const PopupMenuItem(
                      value: 'activate',
                      child: ListTile(
                          leading: Icon(Icons.check_circle_outlined,
                              color: Colors.green),
                          title: Text('Set as Active'),
                          dense: true)),
                const PopupMenuItem(
                    value: 'view',
                    child: ListTile(
                        leading: Icon(Icons.visibility_outlined,
                            color: Colors.blue),
                        title: Text('View Plan'),
                        dense: true)),
                if (!isArchived)
                  const PopupMenuItem(
                      value: 'archive',
                      child: ListTile(
                          leading:
                              Icon(Icons.archive_outlined, color: Colors.grey),
                          title: Text('Archive'),
                          dense: true)),
              ],
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.more_vert, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      );

  Future<void> _handleAction(BuildContext context, String action) async {
    final planId = plan['id'] as String?;
    if (planId == null) return;

    switch (action) {
      case 'activate':
        await ClientProfileService.setActivePlan(clientId, planId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Plan set as active')));
        }
        break;
      case 'archive':
        await ClientProfileService.archivePlan(planId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Plan archived')));
        }
        break;
      case 'view':
        Navigator.pushNamed(context, AppRoutes.dietPlansManagement);
        break;
    }
  }
}
