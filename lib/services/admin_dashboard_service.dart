import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboardService {
  static final _supabase = Supabase.instance.client;

  // Dashboard Analytics
  static Future<Map<String, dynamic>> getDashboardAnalytics() async {
    try {
      // Get active subscriptions count and growth
      final activeSubscriptions = await _supabase
          .from('subscriptions')
          .select()
          .eq('status', 'active')
          .count();

      // Get total revenue this month
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      
      final revenueResponse = await _supabase
          .from('orders')
          .select('amount')
          .eq('status', 'completed')
          .gte('created_at', startOfMonth.toIso8601String());

      final totalRevenue = revenueResponse.fold<double>(0, (sum, order) => sum + (order['amount'] / 100));

      // Get pending client approvals
      final pendingApprovals = await _supabase
          .from('profiles')
          .select()
          .eq('role', 'client')
          .is_('updated_at', null)
          .count();

      // Get client acquisition data for chart
      final clientGrowth = await _supabase
          .from('profiles')
          .select('created_at')
          .eq('role', 'client')
          .gte('created_at', DateTime.now().subtract(const Duration(days: 30)).toIso8601String())
          .order('created_at');

      return {
        'activeSubscriptions': activeSubscriptions.count,
        'totalRevenue': totalRevenue,
        'pendingApprovals': pendingApprovals.count,
        'clientGrowth': clientGrowth,
        'revenueGrowth': 12.5, // Mock growth percentage
      };
    } catch (e) {
      throw Exception('Failed to fetch dashboard analytics: $e');
    }
  }

  // Recent Activity Feed
  static Future<List<Map<String, dynamic>>> getRecentActivity() async {
    try {
      // Get recent subscriptions
      final recentSubscriptions = await _supabase
          .from('subscriptions')
          .select('''
            id,
            created_at,
            status,
            client_id,
            profiles!client_id (full_name, email)
          ''')
          .order('created_at', ascending: false)
          .limit(10);

      // Get recent orders
      final recentOrders = await _supabase
          .from('orders')
          .select('id, created_at, status, amount, user_id')
          .order('created_at', ascending: false)
          .limit(10);

      // Combine and format activities
      List<Map<String, dynamic>> activities = [];

      for (var sub in recentSubscriptions) {
        activities.add({
          'type': 'subscription',
          'message': '${sub['profiles']['full_name']} ${sub['status']} subscription',
          'timestamp': sub['created_at'],
          'priority': sub['status'] == 'active' ? 'high' : 'medium',
        });
      }

      for (var order in recentOrders) {
        activities.add({
          'type': 'payment',
          'message': 'Payment of ₹${(order['amount'] / 100).toStringAsFixed(2)} ${order['status']}',
          'timestamp': order['created_at'],
          'priority': order['status'] == 'failed' ? 'urgent' : 'low',
        });
      }

      // Sort by timestamp
      activities.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
      return activities.take(15).toList();
    } catch (e) {
      throw Exception('Failed to fetch recent activity: $e');
    }
  }

  // Subscription Analytics
  static Future<Map<String, dynamic>> getSubscriptionAnalytics() async {
    try {
      final subscriptions = await _supabase
          .from('subscriptions')
          .select('''
            status,
            monthly_fee,
            created_at,
            plan_id,
            diet_plans (title)
          ''');

      // Group by status
      Map<String, int> statusCounts = {};
      Map<String, double> revenueByPlan = {};
      
      for (var sub in subscriptions) {
        final status = sub['status'] as String;
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;

        if (sub['monthly_fee'] != null && sub['diet_plans'] != null) {
          final planTitle = sub['diet_plans']['title'] as String;
          final fee = double.parse(sub['monthly_fee'].toString());
          revenueByPlan[planTitle] = (revenueByPlan[planTitle] ?? 0) + fee;
        }
      }

      return {
        'statusBreakdown': statusCounts,
        'revenueByPlan': revenueByPlan,
        'totalSubscriptions': subscriptions.length,
      };
    } catch (e) {
      throw Exception('Failed to fetch subscription analytics: $e');
    }
  }
}