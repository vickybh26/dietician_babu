import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class AdminDashboardService {
  static final _fs = FirebaseService.instance;

  static Future<Map<String, dynamic>> getDashboardAnalytics() async {
    try {
      final activeSubs = await _fs.clients
          .where('subscriptionStatus', isEqualTo: 'active')
          .get();

      final allClients = await _fs.users
          .where('role', isEqualTo: 'client')
          .get();

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final payments = await _fs.payments
          .where('status', isEqualTo: 'success')
          .where('paidAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .get();

      final totalRevenue = payments.docs.fold<double>(
          0, (sum, doc) => sum + ((doc.data()['priceInr'] as num?)?.toDouble() ?? 0));

      final pendingClients = await _fs.clients
          .where('subscriptionStatus', isEqualTo: 'none')
          .get();

      return {
        'activeSubscriptions': activeSubs.docs.length,
        'totalClients': allClients.docs.length,
        'totalRevenue': totalRevenue,
        'pendingApprovals': pendingClients.docs.length,
        'revenueGrowth': 12.5,
      };
    } catch (e) {
      throw Exception('Failed to fetch dashboard analytics: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getRecentActivity() async {
    try {
      final recentPayments = await _fs.payments
          .orderBy('paidAt', descending: true)
          .limit(5)
          .get();

      final recentCheckins = await _fs.weeklyUpdates
          .orderBy('submittedAt', descending: true)
          .limit(5)
          .get();

      List<Map<String, dynamic>> activities = [];

      for (final doc in recentPayments.docs) {
        final data = doc.data();
        final paidAt = (data['paidAt'] as Timestamp?)?.toDate();
        activities.add({
          'type': 'payment',
          'message': '${data['planName'] ?? 'Plan'} purchased — ₹${data['priceInr'] ?? 0}',
          'timestamp': paidAt?.toIso8601String() ?? '',
          'priority': 'high',
        });
      }

      for (final doc in recentCheckins.docs) {
        final data = doc.data();
        final submittedAt = (data['submittedAt'] as Timestamp?)?.toDate();
        activities.add({
          'type': 'checkin',
          'message': 'Weekly check-in submitted (${data['mood'] ?? 'mood logged'})',
          'timestamp': submittedAt?.toIso8601String() ?? '',
          'priority': 'medium',
        });
      }

      activities.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
      return activities.take(10).toList();
    } catch (e) {
      throw Exception('Failed to fetch recent activity: $e');
    }
  }
}
