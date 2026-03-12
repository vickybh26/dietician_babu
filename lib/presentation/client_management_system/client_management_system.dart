import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/client_management_service.dart';
import '../../services/firebase_service.dart'; // Added missing import
import '../admin_dashboard_overview/widgets/admin_scaffold.dart';
import 'widgets/pending_approvals_tab_widget.dart';
import 'widgets/active_clients_tab_widget.dart';
import 'widgets/client_detail_modal_widget.dart';
import 'widgets/client_search_filter_widget.dart';
import 'widgets/members_tab_widget.dart';

class ClientManagementSystem extends StatefulWidget {
  const ClientManagementSystem({super.key});

  @override
  State<ClientManagementSystem> createState() => _ClientManagementSystemState();
}

class _ClientManagementSystemState extends State<ClientManagementSystem>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'All';
  
  List<Map<String, dynamic>> _pendingClients = [];
  List<Map<String, dynamic>> _activeClients = [];
  Map<String, List<String>> _clientNudges = {};
  List<String> _selectedClients = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadClientData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadClientData() async {
    try {
      setState(() => _isLoading = true);
      
      // Fetch data in parallel
      final results = await Future.wait([
        ClientManagementService.getPendingApprovals(),
        ClientManagementService.getAllClients(status: 'active'),
        ClientManagementService.getNudges(),
      ]);

      setState(() {
        _pendingClients = results[0] as List<Map<String, dynamic>>;
        _activeClients = results[1] as List<Map<String, dynamic>>;
        _clientNudges = results[2] as Map<String, List<String>>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading clients: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Client Management',
      body: Column(
        children: [
          _buildHeader(),

          // Hide search/filter bar on Members tab (index 3 — it has its own search)
          if (_tabController.index < 3)
            ClientSearchFilterWidget(
              searchQuery: _searchQuery,
              selectedFilter: _selectedFilter,
              onSearchChanged: (query) {
                setState(() => _searchQuery = query);
              },
              onFilterChanged: (filter) {
                setState(() => _selectedFilter = filter);
              },
            ),

          _buildTabBar(),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      PendingApprovalsTabWidget(
                        clients: _pendingClients,
                        selectedClients: _selectedClients,
                        onClientSelected: _handleClientSelection,
                        onApproveClient: _approveClient,
                        onRejectClient: _rejectClient,
                        onBulkApprove: _bulkApproveClients,
                        onViewDetails: _showClientDetails,
                      ),
                      ActiveClientsTabWidget(
                        clients: _activeClients,
                        searchQuery: _searchQuery,
                        clientNudges: _clientNudges,
                        onViewDetails: _showClientDetails,
                        onUpdateStatus: _updateClientStatus,
                        onSendMessage: _sendMessage,
                      ),
                      _buildFlaggedAccountsTab(),
                      const MembersTabWidget(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final int nudgeCount = _clientNudges.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                    Text(
                      'Client Management',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage approvals, targets & communications',
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loadClientData,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh Data',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard('Pending', _pendingClients.length.toString(), const Color(0xFFF57C00)),
              const SizedBox(width: 12),
              _buildStatCard('Active', _activeClients.length.toString(), const Color(0xFF388E3C)),
              const SizedBox(width: 12),
              _buildStatCard('Nudges', nudgeCount.toString(), const Color(0xFFD32F2F),
                  showBell: nudgeCount > 0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, {bool showBell = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                showBell ? Icons.notifications_active : Icons.bar_chart,
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerHeight: 0,
        indicator: BoxDecoration(
          color: const Color(0xFF1976D2),
          borderRadius: BorderRadius.circular(20),
        ),
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400),
        padding: EdgeInsets.zero,
        tabs: [
          Tab(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text('Pending (${_pendingClients.length})'),
            ),
          ),
          const Tab(child: Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('Active'))),
          const Tab(child: Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('Flagged'))),
          const Tab(child: Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('Members'))),
        ],
      ),
    );
  }

  Widget _buildFlaggedAccountsTab() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.flag_outlined, size: 28, color: Colors.grey[400]),
          ),
          const SizedBox(height: 12),
          Text(
            'No flagged accounts',
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            'Flagged clients will appear here',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  void _handleClientSelection(String clientId, bool selected) {
    setState(() {
      if (selected) {
        _selectedClients.add(clientId);
      } else {
        _selectedClients.remove(clientId);
      }
    });
  }

  Future<void> _approveClient(String clientId) async {
    await ClientManagementService.approveClient(clientId);
    _loadClientData();
  }

  Future<void> _rejectClient(String clientId) async {
    await ClientManagementService.rejectClient(clientId, 'Rejected by admin');
    _loadClientData();
  }

  Future<void> _bulkApproveClients() async {
    await ClientManagementService.bulkApproveClients(_selectedClients);
    _selectedClients.clear();
    _loadClientData();
  }

  Future<void> _updateClientStatus(String clientId, String status) async {
    await ClientManagementService.updateClientStatus(clientId, status);
    _loadClientData();
  }

  Future<void> _sendMessage(String clientId) async {
    // Placeholder for send message dialog
  }

  void _showClientDetails(String uid) async {
    final clientData = await ClientManagementService.getClientProfile(uid);
    if (!mounted || clientData == null) return;

    showDialog(
      context: context,
      builder: (context) => ClientDetailModalWidget(
        clientData: clientData,
        nudges: _clientNudges[uid] ?? [],
        onSaveTargets: (calories, water, country) async {
          await ClientManagementService.updateClientProfile(uid, {
            'targetCalories': calories,
            'targetWaterMl': water,
            'country': country,
          });
          
          // Mark nudges as resolved
          final nudgeSnap = await FirebaseService.instance.db
              .collection('nudges')
              .where('clientId', isEqualTo: uid)
              .get();
          
          final batch = FirebaseService.instance.db.batch();
          for (var doc in nudgeSnap.docs) {
            batch.update(doc.reference, {'status': 'resolved'});
          }
          await batch.commit();
          
          _loadClientData();
        },
      ),
    );
  }
}
