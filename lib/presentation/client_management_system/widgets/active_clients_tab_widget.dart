import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActiveClientsTabWidget extends StatelessWidget {
  final List<Map<String, dynamic>> clients;
  final String searchQuery;
  final Map<String, List<String>> clientNudges; // New field
  final bool isInactive;
  final Function(String) onViewDetails;
  final Function(String, String) onUpdateStatus;
  final Function(String) onSendMessage;

  const ActiveClientsTabWidget({
    super.key,
    required this.clients,
    required this.searchQuery,
    required this.clientNudges,
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
        _buildSummaryHeader(filteredClients.length),
        
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
                  _buildTableHeader(),
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
    List<Map<String, dynamic>> result = clients;

    // Filter by Search Query
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((client) {
        final name = (client['name'] ?? '').toLowerCase();
        final email = (client['email'] ?? '').toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    }

    // Filter by Nudges (if active)
    if (searchQuery == "FILTER_NUDGES") {
      result = result.where((client) => clientNudges.containsKey(client['uid'])).toList();
    }
    
    return result;
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
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('All systems running', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green[700])),
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
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('Client', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 14))),
          Expanded(flex: 2, child: Text('Subscription', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 14))),
          Expanded(flex: 1, child: Text('Targets', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 14))),
          Expanded(flex: 1, child: Text('Status', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 14))),
          const SizedBox(width: 120),
        ],
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> client, bool isEven) {
    final uid = client['uid'] ?? '';
    final hasNudge = clientNudges.containsKey(uid);
    final nudgeTypes = clientNudges[uid] ?? [];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isEven ? Colors.grey[25] : Colors.white,
        border: const Border(bottom: BorderSide(color: Colors.grey, width: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: (hasNudge ? Colors.red : const Color(0xFF1976D2)).withOpacity(0.1),
                  child: hasNudge 
                    ? const Icon(Icons.notifications_active, color: Colors.red, size: 18)
                    : Text(_getInitials(client['name'] ?? 'Unknown'), style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1976D2), fontSize: 12)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(client['name'] ?? 'Unknown', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.grey[800], fontSize: 14)),
                      if (hasNudge) Text('Requested: ${nudgeTypes.join(", ")}', style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            flex: 2,
            child: Text(client['subscriptionPlan'] ?? 'No Plan', style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: Colors.grey[800], fontSize: 14)),
          ),

          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${client['targetCalories'] ?? 0} cal', style: const TextStyle(fontSize: 12)),
                Text('${client['targetWaterMl'] ?? 0} ml', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: _getStatusColor(client['subscriptionStatus']).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Text(client['subscriptionStatus'] ?? 'none', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _getStatusColor(client['subscriptionStatus'])), textAlign: TextAlign.center),
            ),
          ),
          
          SizedBox(
            width: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => onViewDetails(uid),
                  icon: Icon(hasNudge ? Icons.edit_notifications : Icons.settings, size: 18),
                  color: hasNudge ? Colors.red : Colors.blue,
                  tooltip: 'Update Targets',
                ),
                IconButton(
                  onPressed: () => onSendMessage(uid),
                  icon: const Icon(Icons.message, size: 18),
                  tooltip: 'Send Message',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text('No clients found'));
  }

  String _getInitials(String name) {
    return name.split(' ').map((word) => word.isNotEmpty ? word[0].toUpperCase() : '').take(2).join('');
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active': return Colors.green;
      case 'inactive': return Colors.orange;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }
}
