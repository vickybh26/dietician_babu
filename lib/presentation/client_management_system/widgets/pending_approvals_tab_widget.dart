import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PendingApprovalsTabWidget extends StatelessWidget {
  final List<Map<String, dynamic>> clients;
  final List<String> selectedClients;
  final Function(String, bool) onClientSelected;
  final Function(String) onApproveClient;
  final Function(String) onRejectClient;
  final VoidCallback onBulkApprove;
  final Function(String) onViewDetails;

  const PendingApprovalsTabWidget({
    super.key,
    required this.clients,
    required this.selectedClients,
    required this.onClientSelected,
    required this.onApproveClient,
    required this.onRejectClient,
    required this.onBulkApprove,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    if (clients.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Bulk Actions Bar
        if (selectedClients.isNotEmpty) _buildBulkActionsBar(),
        
        // Client Cards
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: clients.length,
            itemBuilder: (context, index) {
              final client = clients[index];
              final isSelected = selectedClients.contains(client['id']);
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected 
                        ? const Color(0xFF1976D2) 
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with selection checkbox and client info
                      Row(
                        children: [
                          Checkbox(
                            value: isSelected,
                            onChanged: (value) => onClientSelected(
                              client['id'],
                              value ?? false,
                            ),
                            activeColor: const Color(0xFF1976D2),
                          ),
                          const SizedBox(width: 12),
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: const Color(0xFF1976D2).withOpacity(0.1),
                            child: Text(
                              _getInitials(client['full_name'] ?? 'Unknown'),
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1976D2),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  client['full_name'] ?? 'Unknown',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  client['email'] ?? '',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (client['phone'] != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    client['phone'],
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Registration date
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Applied ${_formatDate(client['created_at'])}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Client Information Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoItem(
                              'Age',
                              _calculateAge(client['date_of_birth']),
                              Icons.cake,
                            ),
                          ),
                          Expanded(
                            child: _buildInfoItem(
                              'Plan',
                              _getSubscriptionPlan(client['subscriptions']),
                              Icons.restaurant_menu,
                            ),
                          ),
                          Expanded(
                            child: _buildInfoItem(
                              'Monthly Fee',
                              _getMonthlyFee(client['subscriptions']),
                              Icons.payment,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => onApproveClient(client['id']),
                              icon: const Icon(Icons.check_circle),
                              label: const Text('Approve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => onRejectClient(client['id']),
                              icon: const Icon(Icons.cancel),
                              label: const Text('Reject'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: () => onViewDetails(client['id']),
                            icon: const Icon(Icons.visibility),
                            tooltip: 'View Details',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              foregroundColor: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBulkActionsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1976D2).withOpacity(0.1),
        border: const Border(
          bottom: BorderSide(color: Colors.grey, width: 0.2),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${selectedClients.length} client(s) selected',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1976D2),
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: onBulkApprove,
            icon: const Icon(Icons.check_circle),
            label: const Text('Approve Selected'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: Colors.grey[600]),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No Pending Approvals',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'All client applications have been processed',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    return name
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .take(2)
        .join('');
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  String _calculateAge(String? dobString) {
    if (dobString == null) return 'N/A';
    try {
      final dob = DateTime.parse(dobString);
      final now = DateTime.now();
      final age = now.year - dob.year;
      return '$age years';
    } catch (e) {
      return 'N/A';
    }
  }

  String _getSubscriptionPlan(List? subscriptions) {
    if (subscriptions == null || subscriptions.isEmpty) {
      return 'No Plan';
    }
    final subscription = subscriptions.first;
    final dietPlan = subscription['diet_plans'];
    return dietPlan?['title'] ?? 'Custom Plan';
  }

  String _getMonthlyFee(List? subscriptions) {
    if (subscriptions == null || subscriptions.isEmpty) {
      return '₹0';
    }
    final subscription = subscriptions.first;
    final fee = subscription['monthly_fee'];
    return fee != null ? '₹${fee.toString()}' : '₹0';
  }
}