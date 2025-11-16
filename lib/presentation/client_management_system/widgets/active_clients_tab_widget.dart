import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActiveClientsTabWidget extends StatelessWidget {
  final List<Map<String, dynamic>> clients;
  final String searchQuery;
  final bool isInactive;
  final Function(String) onViewDetails;
  final Function(String, String) onUpdateStatus;
  final Function(String) onSendMessage;

  const ActiveClientsTabWidget({
    super.key,
    required this.clients,
    required this.searchQuery,
    this.isInactive = false,
    required this.onViewDetails,
    required this.onUpdateStatus,
    required this.onSendMessage,
  });

  @override
  Widget build(BuildContext context) {
    final filteredClients = _filterClients();

    if (filteredClients.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Summary Header
        _buildSummaryHeader(filteredClients.length),
        
        // Client Table
        Expanded(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Table Header
                  _buildTableHeader(),
                  
                  // Table Rows
                  ...filteredClients.asMap().entries.map((entry) {
                    final index = entry.key;
                    final client = entry.value;
                    return _buildTableRow(client, index.isEven);
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _filterClients() {
    if (searchQuery.isEmpty) return clients;
    
    return clients.where((client) {
      final name = (client['full_name'] ?? '').toLowerCase();
      final email = (client['email'] ?? '').toLowerCase();
      final query = searchQuery.toLowerCase();
      
      return name.contains(query) || email.contains(query);
    }).toList();
  }

  Widget _buildSummaryHeader(int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.2)),
      ),
      child: Row(
        children: [
          Text(
            '${isInactive ? 'Inactive' : 'Active'} Clients ($count)',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const Spacer(),
          if (!isInactive) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'All systems running',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Client',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Subscription',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Start Date',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Status',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 120), // Actions column
        ],
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> client, bool isEven) {
    final subscription = _getActiveSubscription(client['subscriptions']);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isEven ? Colors.grey[25] : Colors.white,
        border: const Border(
          bottom: BorderSide(color: Colors.grey, width: 0.1),
        ),
      ),
      child: Row(
        children: [
          // Client Info
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF1976D2).withOpacity(0.1),
                  child: Text(
                    _getInitials(client['full_name'] ?? 'Unknown'),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1976D2),
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client['full_name'] ?? 'Unknown',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        client['email'] ?? '',
                        style: GoogleFonts.inter(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Subscription Plan
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subscription != null
                      ? (subscription['diet_plans']?['title'] ?? 'Custom Plan')
                      : 'No Plan',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (subscription != null && subscription['monthly_fee'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '₹${subscription['monthly_fee']}/month',
                    style: GoogleFonts.inter(
                      color: Colors.green[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Start Date
          Expanded(
            flex: 2,
            child: Text(
              subscription != null && subscription['start_date'] != null
                  ? _formatDate(subscription['start_date'])
                  : 'N/A',
              style: GoogleFonts.inter(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          
          // Status
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(subscription?['status']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getStatusText(subscription?['status']),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getStatusColor(subscription?['status']),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          // Actions
          SizedBox(
            width: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => onViewDetails(client['id']),
                  icon: const Icon(Icons.visibility, size: 18),
                  tooltip: 'View Details',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    foregroundColor: Colors.grey[600],
                    minimumSize: const Size(32, 32),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => onSendMessage(client['id']),
                  icon: const Icon(Icons.message, size: 18),
                  tooltip: 'Send Message',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2).withOpacity(0.1),
                    foregroundColor: const Color(0xFF1976D2),
                    minimumSize: const Size(32, 32),
                  ),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  onSelected: (value) => onUpdateStatus(client['id'], value),
                  itemBuilder: (context) => [
                    if (!isInactive)
                      const PopupMenuItem(
                        value: 'suspended',
                        child: Text('Suspend'),
                      ),
                    if (isInactive)
                      const PopupMenuItem(
                        value: 'active',
                        child: Text('Reactivate'),
                      ),
                    const PopupMenuItem(
                      value: 'cancelled',
                      child: Text('Cancel Subscription'),
                    ),
                  ],
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.more_vert,
                      size: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isInactive ? Icons.person_off : Icons.people,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            isInactive ? 'No Inactive Clients' : 'No Active Clients',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isInactive 
                ? 'All clients are currently active'
                : 'No clients have been approved yet',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _getActiveSubscription(List? subscriptions) {
    if (subscriptions == null || subscriptions.isEmpty) return null;
    
    try {
      return subscriptions.firstWhere(
        (sub) => sub['status'] == (isInactive ? 'inactive' : 'active'),
        orElse: () => subscriptions.first,
      );
    } catch (e) {
      return subscriptions.first;
    }
  }

  String _getInitials(String name) {
    return name
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .take(2)
        .join('');
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
      case 'suspended':
        return Colors.orange;
      case 'cancelled':
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'inactive':
        return 'Inactive';
      case 'suspended':
        return 'Suspended';
      case 'cancelled':
        return 'Cancelled';
      case 'expired':
        return 'Expired';
      default:
        return 'Unknown';
    }
  }
}