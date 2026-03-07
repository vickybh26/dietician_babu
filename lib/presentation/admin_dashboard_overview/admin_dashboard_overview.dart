import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../services/admin_dashboard_service.dart';
import 'widgets/stats_card_widget.dart';
import 'widgets/revenue_chart_widget.dart';
import 'widgets/recent_activity_widget.dart';
import 'widgets/quick_actions_widget.dart';
import 'widgets/admin_sidebar_widget.dart';
import 'widgets/admin_scaffold.dart';

class AdminDashboardOverview extends StatefulWidget {
  const AdminDashboardOverview({super.key});

  @override
  State<AdminDashboardOverview> createState() => _AdminDashboardOverviewState();
}

class _AdminDashboardOverviewState extends State<AdminDashboardOverview> {
  bool _isLoading = true;
  Map<String, dynamic> _analytics = {};
  List<Map<String, dynamic>> _recentActivity = [];
  String _selectedTimeRange = 'This Month';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() => _isLoading = true);
      
      final analytics = await AdminDashboardService.getDashboardAnalytics();
      final activity = await AdminDashboardService.getRecentActivity();
      
      setState(() {
        _analytics = analytics;
        _recentActivity = activity;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Dashboard',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildStatsCards(),
                  const SizedBox(height: 24),
                  RevenueChartWidget(
                    analytics: _analytics,
                    selectedTimeRange: _selectedTimeRange,
                    onTimeRangeChanged: (range) {
                      setState(() => _selectedTimeRange = range);
                      _loadDashboardData();
                    },
                  ),
                  const SizedBox(height: 24),
                  RecentActivityWidget(activities: _recentActivity),
                  const SizedBox(height: 24),
                  QuickActionsWidget(
                    pendingApprovals: _analytics['pendingApprovals'] ?? 0,
                    onRefresh: _loadDashboardData,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard Overview',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Here\'s what\'s happening today.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _loadDashboardData,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    final pending = _analytics['pendingApprovals'] ?? 0;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatsCardWidget(
                title: 'Active Subscriptions',
                value: '${_analytics['activeSubscriptions'] ?? 0}',
                change: '+${_analytics['revenueGrowth']?.toStringAsFixed(1) ?? '0'}%',
                changeColor: Colors.green,
                icon: Icons.people_alt,
                iconColor: const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatsCardWidget(
                title: 'Monthly Revenue',
                value: '₹${(_analytics['totalRevenue'] ?? 0).toStringAsFixed(0)}',
                change: 'This month',
                changeColor: Colors.green,
                icon: Icons.trending_up,
                iconColor: const Color(0xFF1976D2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatsCardWidget(
                title: 'Pending Approvals',
                value: '$pending',
                change: pending > 0 ? 'Action needed' : 'All clear',
                changeColor: pending > 0 ? Colors.orange : Colors.green,
                icon: Icons.pending_actions,
                iconColor: const Color(0xFFFF9800),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatsCardWidget(
                title: 'Total Clients',
                value: '${_analytics['totalClients'] ?? 0}',
                change: 'Registered',
                changeColor: Colors.green,
                icon: Icons.favorite,
                iconColor: const Color(0xFFE91E63),
              ),
            ),
          ],
        ),
      ],
    );
  }
}