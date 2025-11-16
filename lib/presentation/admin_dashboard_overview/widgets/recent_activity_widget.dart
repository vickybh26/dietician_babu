import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RecentActivityWidget extends StatelessWidget {
  final List<Map<String, dynamic>> activities;

  const RecentActivityWidget({
    super.key,
    required this.activities,
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              IconButton(
                onPressed: () {
                  // Refresh activity feed
                },
                icon: const Icon(
                  Icons.refresh,
                  size: 20,
                  color: Colors.grey,
                ),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Activity List
          activities.isEmpty
              ? _buildEmptyState()
              : SizedBox(
                  height: 300,
                  child: ListView.separated(
                    itemCount: activities.length,
                    separatorBuilder: (context, index) => const Divider(height: 20),
                    itemBuilder: (context, index) {
                      final activity = activities[index];
                      return _buildActivityItem(activity);
                    },
                  ),
                ),
          
          const SizedBox(height: 16),
          
          // View All Button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                // Navigate to full activity log
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Full activity log coming soon!')),
                );
              },
              child: Text(
                'View All Activity',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1976D2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final type = activity['type'] as String;
    final message = activity['message'] as String;
    final timestamp = activity['timestamp'] as String;
    final priority = activity['priority'] as String;

    IconData iconData;
    Color iconColor;
    Color backgroundColor;

    switch (type) {
      case 'subscription':
        iconData = Icons.card_membership;
        iconColor = const Color(0xFF2E7D32);
        backgroundColor = const Color(0xFF2E7D32).withOpacity(0.1);
        break;
      case 'payment':
        iconData = Icons.payment;
        iconColor = const Color(0xFF1976D2);
        backgroundColor = const Color(0xFF1976D2).withOpacity(0.1);
        break;
      case 'client':
        iconData = Icons.person_add;
        iconColor = const Color(0xFFFF9800);
        backgroundColor = const Color(0xFFFF9800).withOpacity(0.1);
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
        backgroundColor = Colors.grey.withOpacity(0.1);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            iconData,
            color: iconColor,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        
        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      message,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (priority == 'urgent')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'URGENT',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _formatTimestamp(timestamp),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No recent activity',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Activity will appear here as it happens',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return 'Recently';
    }
  }
}