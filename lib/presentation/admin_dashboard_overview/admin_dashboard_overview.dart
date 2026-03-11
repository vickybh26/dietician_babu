import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/admin_dashboard_service.dart';
import 'widgets/stats_card_widget.dart';
import 'widgets/revenue_chart_widget.dart';
import 'widgets/recent_activity_widget.dart';
import 'widgets/quick_actions_widget.dart';
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
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 28),
                  _SectionHeader('Overview'),
                  _buildStatsGrid(),
                  const SizedBox(height: 28),
                  _SectionHeader(
                    'Revenue',
                    action: TextButton.icon(
                      onPressed: _loadDashboardData,
                      icon: const Icon(Icons.refresh_rounded, size: 14),
                      label: Text(
                        'Refresh',
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                    ),
                  ),
                  RevenueChartWidget(
                    analytics: _analytics,
                    selectedTimeRange: _selectedTimeRange,
                    onTimeRangeChanged: (range) {
                      setState(() => _selectedTimeRange = range);
                      _loadDashboardData();
                    },
                  ),
                  const SizedBox(height: 28),
                  _SectionHeader('Recent Activity'),
                  RecentActivityWidget(activities: _recentActivity),
                  const SizedBox(height: 28),
                  _SectionHeader('Quick Actions'),
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
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Here\'s what\'s happening today.',
                style: GoogleFonts.inter(fontSize: 15, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _loadDashboardData,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh',
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey[100],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  /// Responsive stats grid: 2 columns on narrow screens, 4 on wide (≥900px).
  Widget _buildStatsGrid() {
    final pending = _analytics['pendingApprovals'] ?? 0;
    final growth = _analytics['revenueGrowth'] as double? ?? 0.0;

    final cards = [
      StatsCardWidget(
        title: 'Active Subscriptions',
        value: '${_analytics['activeSubscriptions'] ?? 0}',
        change: growth >= 0 ? '+$growth%' : '$growth%',
        changeColor: growth >= 0 ? Colors.green : Colors.red,
        icon: Icons.people_alt_outlined,
        iconColor: const Color(0xFF2E7D32),
      ),
      StatsCardWidget(
        title: 'Monthly Revenue',
        value: '₹${(_analytics['totalRevenue'] ?? 0).toStringAsFixed(0)}',
        change: 'This month',
        changeColor: Colors.blue,
        icon: Icons.trending_up,
        iconColor: const Color(0xFF1976D2),
      ),
      StatsCardWidget(
        title: 'Pending Approvals',
        value: '$pending',
        change: pending > 0 ? 'Action needed' : 'All clear',
        changeColor: pending > 0 ? Colors.orange : Colors.green,
        icon: Icons.pending_actions_outlined,
        iconColor: const Color(0xFFFF9800),
      ),
      StatsCardWidget(
        title: 'Total Clients',
        value: '${_analytics['totalClients'] ?? 0}',
        change: 'Registered',
        changeColor: Colors.grey,
        icon: Icons.group_outlined,
        iconColor: const Color(0xFFE91E63),
      ),
    ];

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final cols = constraints.maxWidth >= 900 ? 4 : 2;
        return GridView.count(
          crossAxisCount: cols,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.7,
          children: cards,
        );
      },
    );
  }
}

// ── Private section header ────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const _SectionHeader(this.title, {this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          if (action != null) ...[const Spacer(), action!],
        ],
      ),
    );
  }
}
