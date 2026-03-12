import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/client_profile_service.dart';
import '../../services/client_management_service.dart';
import '../admin_dashboard_overview/widgets/admin_scaffold.dart';
import 'tabs/personal_info_tab.dart';
import 'tabs/diet_plans_tab.dart';
import 'tabs/progress_tracker_tab.dart';
import 'tabs/notes_tab.dart';
import 'tabs/appointments_tab.dart';
import 'tabs/food_diary_tab.dart';
import 'tabs/lab_reports_tab.dart';
import 'tabs/documents_tab.dart';

/// Full-page client profile with 4 tabs.
/// Receives [clientId] as a route argument: Navigator.pushNamed(ctx, AppRoutes.clientProfile, arguments: uid)
class ClientProfileScreen extends StatefulWidget {
  final String clientId;

  const ClientProfileScreen({super.key, required this.clientId});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _profile = {};
  bool _isLoading = true;

  static const _tabs = [
    _TabDef(Icons.person_outlined, 'Personal Info'),
    _TabDef(Icons.restaurant_menu_outlined, 'Diet Plans'),
    _TabDef(Icons.show_chart_outlined, 'Progress'),
    _TabDef(Icons.notes_outlined, 'Notes'),
    _TabDef(Icons.calendar_today_outlined, 'Appointments'),
    _TabDef(Icons.dinner_dining_outlined, 'Food Diary'),
    _TabDef(Icons.science_outlined, 'Lab Reports'),
    _TabDef(Icons.folder_outlined, 'Documents'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile =
          await ClientProfileService.getFullProfile(widget.clientId);
      if (mounted) setState(() { _profile = profile; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String get _name => _profile['name'] ?? 'Client';
  String get _email => _profile['email'] ?? '';
  String get _status => _profile['subscriptionStatus'] ?? 'none';

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'active': return Colors.green;
      case 'approved': return const Color(0xFF0288D1);
      case 'inactive': return Colors.orange;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _initials(String name) => name
      .split(' ')
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0].toUpperCase())
      .join();

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Client Profile',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(),
                _buildTabBar(),
                Expanded(child: _buildTabBody()),
              ],
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Back button
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Back to Clients',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                ),
              ),
              const SizedBox(width: 16),

              // Avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFF1976D2).withOpacity(0.12),
                child: Text(
                  _initials(_name),
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1976D2),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Name + email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _name,
                      style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900]),
                    ),
                    if (_email.isNotEmpty)
                      Text(_email,
                          style: GoogleFonts.inter(
                              fontSize: 13, color: Colors.grey[600])),
                  ],
                ),
              ),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor(_status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _statusColor(_status).withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _statusColor(_status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _status.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _statusColor(_status),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Quick message button
              OutlinedButton.icon(
                onPressed: _showSendMessageDialog,
                icon: const Icon(Icons.message_outlined, size: 16),
                label: const Text('Message'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1976D2),
                  side: const BorderSide(color: Color(0xFF1976D2)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Quick stats row
          Padding(
            padding: const EdgeInsets.only(left: 92.0, top: 4, bottom: 8),
            child: Wrap(
              spacing: 24,
              children: [
                _miniStat('Plan',
                    _profile['subscriptionPlan'] ?? 'None'),
                _miniStat('Calories',
                    '${_profile['targetCalories'] ?? 0} kcal'),
                _miniStat('Water',
                    '${_profile['targetWaterMl'] ?? 0} ml'),
                if (_profile['goal'] != null)
                  _miniStat('Goal', _profile['goal']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) => RichText(
        text: TextSpan(
          style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[700]),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Color(0xFF1976D2)),
            ),
          ],
        ),
      );

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: const Color(0xFF1976D2),
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: const Color(0xFF1976D2),
            indicatorWeight: 3,
            labelStyle:
                GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
            tabs: _tabs
                .map((t) => Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(t.icon, size: 16),
                          const SizedBox(width: 6),
                          Text(t.label),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBody() {
    return TabBarView(
      controller: _tabController,
      children: [
        PersonalInfoTab(
          clientId: widget.clientId,
          profile: _profile,
          onUpdated: _loadProfile,
        ),
        DietPlansTab(clientId: widget.clientId),
        ProgressTrackerTab(clientId: widget.clientId),
        NotesTab(clientId: widget.clientId),
        AppointmentsTab(clientId: widget.clientId),
        FoodDiaryTab(clientId: widget.clientId),
        LabReportsTab(clientId: widget.clientId),
        DocumentsTab(clientId: widget.clientId),
      ],
    );
  }

  void _showSendMessageDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Send Message to $_name',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Type your message…',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              await ClientManagementService.sendMessageToClient(
                  widget.clientId, ctrl.text.trim());
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message sent!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}

class _TabDef {
  final IconData icon;
  final String label;
  const _TabDef(this.icon, this.label);
}
