import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_export.dart';

class QuickActionsWidget extends StatelessWidget {
  final int pendingApprovals;
  final VoidCallback onRefresh;

  const QuickActionsWidget({
    super.key,
    required this.pendingApprovals,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          
          // Action Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            childAspectRatio: 1.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildActionCard(
                context,
                'Approve Clients',
                Icons.check_circle,
                const Color(0xFF2E7D32),
                pendingApprovals > 0 
                    ? '$pendingApprovals pending' 
                    : 'All approved',
                () => Navigator.pushNamed(context, AppRoutes.clientManagementSystem),
                badge: pendingApprovals > 0 ? '$pendingApprovals' : null,
              ),
              _buildActionCard(
                context,
                'Create Diet Plan',
                Icons.restaurant_menu,
                const Color(0xFF1976D2),
                'Add new plan',
                () => _showComingSoon(context, 'Diet Plan Creator'),
              ),
              _buildActionCard(
                context,
                'Send Notifications',
                Icons.notifications_active,
                const Color(0xFFFF9800),
                'Bulk messaging',
                () => _showComingSoon(context, 'Bulk Notifications'),
              ),
              _buildActionCard(
                context,
                'Export Data',
                Icons.file_download,
                const Color(0xFF9C27B0),
                'Generate reports',
                () => _showExportOptions(context),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Additional Quick Links
          Row(
            children: [
              Expanded(
                child: _buildQuickLink(
                  context,
                  'View All Clients',
                  Icons.people,
                  () => Navigator.pushNamed(context, AppRoutes.clientManagementSystem),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickLink(
                  context,
                  'Analytics Dashboard',
                  Icons.analytics,
                  () => _showComingSoon(context, 'Analytics Dashboard'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickLink(
                  context,
                  'Settings',
                  Icons.settings,
                  () => _showComingSoon(context, 'Admin Settings'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String subtitle,
    VoidCallback onTap, {
    String? badge,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              if (badge != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickLink(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.file_download),
              title: const Text('Client Data CSV'),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon(context, 'Client CSV Export');
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Revenue Report PDF'),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon(context, 'Revenue Report');
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('Subscription Report'),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon(context, 'Subscription Report');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}