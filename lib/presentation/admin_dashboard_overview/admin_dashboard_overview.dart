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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          // Sidebar
          const AdminSidebarWidget(),
          
          // Main Content
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        _buildHeader(),
                        const SizedBox(height: 24),
                        
                        // Stats Cards
                        _buildStatsCards(),
                        const SizedBox(height: 24),
                        
                        // Charts and Activity Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Revenue Chart
                            Expanded(
                              flex: 2,
                              child: RevenueChartWidget(
                                analytics: _analytics,
                                selectedTimeRange: _selectedTimeRange,
                                onTimeRangeChanged: (range) {
                                  setState(() => _selectedTimeRange = range);
                                  _loadDashboardData();
                                },
                              ),
                            ),
                            const SizedBox(width: 24),
                            
                            // Recent Activity
                            Expanded(
                              flex: 1,
                              child: RecentActivityWidget(
                                activities: _recentActivity,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Quick Actions
                        QuickActionsWidget(
                          pendingApprovals: _analytics['pendingApprovals'] ?? 0,
                          onRefresh: _loadDashboardData,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard Overview',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            Text(
              'Welcome back! Here\'s what\'s happening with your business today.',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Data',
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.adminDietPlanCreator);
              },
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Create Diet Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFf5a40d),
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.clientManagementSystem);
              },
              icon: const Icon(Icons.people),
              label: const Text('Manage Clients'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return Row(
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
        const SizedBox(width: 16),
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
        const SizedBox(width: 16),
        Expanded(
          child: StatsCardWidget(
            title: 'Pending Approvals',
            value: '${_analytics['pendingApprovals'] ?? 0}',
            change: _analytics['pendingApprovals'] != null && _analytics['pendingApprovals'] > 0 
                ? 'Needs attention' 
                : 'All caught up',
            changeColor: _analytics['pendingApprovals'] != null && _analytics['pendingApprovals'] > 0 
                ? Colors.orange 
                : Colors.green,
            icon: Icons.pending_actions,
            iconColor: const Color(0xFFFF9800),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatsCardWidget(
            title: 'Total Clients',
            value: '${_analytics['totalClients'] ?? 0}',
            change: 'All registered',
            changeColor: Colors.green,
            icon: Icons.favorite,
            iconColor: const Color(0xFFE91E63),
          ),
        ),
      ],
    );
  }
}