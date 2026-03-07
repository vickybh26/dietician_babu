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
      
      final pendingClients = await ClientManagementService.getPendingApprovals();
      final activeClients = await ClientManagementService.getAllClients(status: 'active');
      final inactiveClients = await ClientManagementService.getAllClients(status: 'inactive');
      
      setState(() {
        _pendingClients = pendingClients;
        _activeClients = activeClients;
        _inactiveClients = inactiveClients;
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
          // Header
          _buildHeader(),

          // Search and Filter
          ClientSearchFilterWidget(
            searchQuery: _searchQuery,
            selectedFilter: _selectedFilter,
            onSearchChanged: (query) {
              setState(() => _searchQuery = query);
              _filterClients();
            },
            onFilterChanged: (filter) {
              setState(() => _selectedFilter = filter);
              _filterClients();
            },
          ),

          // Tab Bar
          _buildTabBar(),

          // Tab Content
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
                        onViewDetails: _showClientDetails,
                        onUpdateStatus: _updateClientStatus,
                        onSendMessage: _sendMessage,
                      ),
                      ActiveClientsTabWidget(
                        clients: _inactiveClients,
                        searchQuery: _searchQuery,
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
                      'Manage approvals, subscriptions & communications',
                      style: GoogleFonts.inter(
                        fontSize: 13,
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
              ElevatedButton.icon(
                onPressed: _exportClientData,
                icon: const Icon(Icons.file_download, size: 16),
                label: const Text('Export'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
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
              _buildStatCard('Inactive', _inactiveClients.length.toString(), Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
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
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w400),
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Pending Approvals'),
                if (_pendingClients.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_pendingClients.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Tab(text: 'Active Clients'),
          const Tab(text: 'Inactive Clients'),
          const Tab(text: 'Flagged Accounts'),
        ],
      ),
    );
  }

  Widget _buildFlaggedAccountsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.flag_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No Flagged Accounts',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Accounts with issues will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _filterClients() {
    // Implementation for filtering clients based on search and filter criteria
    _loadClientData();
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
    try {
      final success = await ClientManagementService.approveClient(clientId);
      if (success) {
        _loadClientData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Client approved successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error approving client: $e')),
        );
      }
    }
  }

  Future<void> _rejectClient(String clientId) async {
    final reason = await _showRejectDialog();
    if (reason != null && reason.isNotEmpty) {
      try {
        final success = await ClientManagementService.rejectClient(clientId, reason);
        if (success) {
          _loadClientData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Client rejected')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error rejecting client: $e')),
          );
        }
      }
    }
  }

  Future<void> _bulkApproveClients() async {
    if (_selectedClients.isEmpty) return;
    
    try {
      final success = await ClientManagementService.bulkApproveClients(_selectedClients);
      if (success) {
        setState(() => _selectedClients.clear());
        _loadClientData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${_selectedClients.length} clients approved')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error bulk approving: $e')),
        );
      }
    }
  }

  Future<void> _updateClientStatus(String clientId, String status) async {
    try {
      final success = await ClientManagementService.updateClientStatus(clientId, status);
      if (success) {
        _loadClientData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Client status updated')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }

  Future<void> _sendMessage(String clientId) async {
    final message = await _showMessageDialog();
    if (message != null && message.isNotEmpty) {
      try {
        final success = await ClientManagementService.sendMessageToClient(clientId, message);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Message sent successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sending message: $e')),
          );
        }
      }
    }
  }

  void _showClientDetails(String clientId) async {
    showDialog(
      context: context,
      builder: (context) => ClientDetailModalWidget(clientId: clientId),
    );
  }

  Future<void> _exportClientData() async {
    try {
      final _ = await ClientManagementService.exportClientData();
      // In a real app, this would trigger file download
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export functionality coming soon!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e')),
        );
      }
    }
  }

  Future<String?> _showRejectDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Client'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter reason...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<String?> _showMessageDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Message'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your message:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}