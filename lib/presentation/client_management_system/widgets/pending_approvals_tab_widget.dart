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

    // Optimization: Use a GridView on larger screens (Web)
    final bool isWide = MediaQuery.of(context).size.width > 900;

    return Column(
      children: [
        if (selectedClients.isNotEmpty) _buildBulkActionsBar(),
        
        Expanded(
          child: isWide 
            ? GridView.builder(
                padding: const EdgeInsets.all(24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemCount: clients.length,
                itemBuilder: (context, index) => _buildClientCard(context, clients[index]),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: clients.length,
                itemBuilder: (context, index) => _buildClientCard(context, clients[index]),
              ),
        ),
      ],
    );
  }

  Widget _buildClientCard(BuildContext context, Map<String, dynamic> client) {
    // FIX: Using 'name' instead of 'full_name' to prevent "Unknown"
    final String clientName = client['name'] ?? client['full_name'] ?? 'New User';
    final String clientId = client['uid'] ?? client['id'] ?? '';
    final bool isSelected = selectedClients.contains(clientId);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color(0xFF1976D2) : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (value) => onClientSelected(clientId, value ?? false),
                  activeColor: const Color(0xFF1976D2),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFF1976D2).withOpacity(0.1),
                  child: Text(
                    _getInitials(clientName),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1976D2), fontSize: 12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clientName,
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        client['email'] ?? 'No email',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Text('Pending', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                _buildCompactInfo('Plan', client['subscriptionPlan'] ?? 'None', Icons.restaurant_menu),
                _buildCompactInfo('Goal', client['goal'] ?? 'N/A', Icons.track_changes),
                const Spacer(),
                TextButton(
                  onPressed: () => onViewDetails(clientId),
                  child: const Text('Details'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => onApproveClient(clientId),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, elevation: 0),
                  child: const Text('Approve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactInfo(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Row(
            children: [
              Icon(icon, size: 12, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBulkActionsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF1976D2).withOpacity(0.05),
      child: Row(
        children: [
          Text('${selectedClients.length} selected', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1976D2))),
          const Spacer(),
          ElevatedButton(
            onPressed: onBulkApprove,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve Selected'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text('No pending approvals'));
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    return name.trim().split(' ').map((word) => word.isNotEmpty ? word[0].toUpperCase() : '').take(2).join('');
  }
}
