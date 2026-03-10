import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/client_management_service.dart';
import '../admin_dashboard_overview/widgets/admin_scaffold.dart';
import 'widgets/pending_approvals_tab_widget.dart';
import 'widgets/active_clients_tab_widget.dart';
import 'widgets/client_detail_modal_widget.dart';
import 'widgets/client_search_filter_widget.dart';

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
  List<Map<String, dynamic>> _inactiveClients = [];
  Map<String, List<String>> _clientNudges = {};
  List<String> _selectedClients = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        ClientManagementService.getAllClients(status: 'inactive'),
        ClientManagementService.getNudges(),
      ]);
      
      setState(() {
        _pendingClients = results[0] as List<Map<String, dynamic>>;
        _activeClients = results[1] as List<Map<String, dynamic>>;
        _inactiveClients = results[2] as List<Map<String, dynamic>>;
        _clientNudges = results[3] as Map<String, List<String>>;
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
                        clientNudges: _clientNudges, // Pass nudges here
                        onViewDetails: _showClientDetails,
                        onUpdateStatus: _updateClientStatus,
                        onSendMessage: _sendMessage,
                      ),
                      ActiveClientsTabWidget(
                        clients: _inactiveClients,
                        searchQuery: _searchQuery,
                        clientNudges: _clientNudges,
                        isInactive: true,
                        onViewDetails: _showClientDetails,
                        onUpdateStatus: _updateClientStatus,
                        onSendMessage: _sendMessage,
                      ),
                      _buildFlaggedAccountsTab(),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Client Management',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      'Manage approvals, targets & communications',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loadClientData,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh Data',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard('Pending', _pendingClients.length.toString(), Colors.orange),
              const SizedBox(width: 12),
              _buildStatCard('Active', _activeClients.length.toString(), Colors.green),
              const SizedBox(width: 12),
              _buildStatCard('Nudges', nudgeCount.toString(), Colors.red, showBell: nudgeCount > 0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, {bool showBell = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showBell) const Icon(Icons.notifications_active, color: Colors.red, size: 16),
                if (showBell) const SizedBox(width: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF1976D2),
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: const Color(0xFF1976D2),
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400),
        tabs: [
          Tab(text: 'Pending (${_pendingClients.length})'),
          const Tab(text: 'Active'),
          const Tab(text: 'Inactive'),
          const Tab(text: 'Flagged'),
        ],
      ),
    );
  }

  Widget _buildFlaggedAccountsTab() {
    return const Center(child: Text('No flagged accounts'));
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
