import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class AdminDashboardService {
  static final _fs = FirebaseService.instance;

  static Future<Map<String, dynamic>> getDashboardAnalytics() async {
    try {
      // 1. Active Subscriptions — query then filter by expiry in Dart
      //    (Firestore doesn't update subscriptionStatus on expiry automatically)
      final activeSubsSnap = await _fs.clients
          .where('subscriptionStatus', isEqualTo: 'active')
          .get();
      final now2 = DateTime.now();
      final activeSubCount = activeSubsSnap.docs.where((doc) {
        final expiresAt = doc.data()['subscriptionExpiresAt'];
        if (expiresAt is! Timestamp) return true; // no expiry = unlimited
        return expiresAt.toDate().isAfter(now2);
      }).length;

      // 2. Total Clients
      final allClients = await _fs.users
          .where('role', isEqualTo: 'client')
          .get();

      // 3. Revenue Calculation (Current Month vs Last Month)
      final now = DateTime.now();
      final startOfCurrentMonth = DateTime(now.year, now.month, 1);
      final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
      
      final currentMonthPayments = await _fs.payments
          .where('status', isEqualTo: 'success')
          .where('paidAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfCurrentMonth))
          .get();

      final lastMonthPayments = await _fs.payments
          .where('status', isEqualTo: 'success')
          .where('paidAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfLastMonth))
          .where('paidAt', isLessThan: Timestamp.fromDate(startOfCurrentMonth))
          .get();

      final currentRevenue = currentMonthPayments.docs.fold<double>(
          0, (sum, doc) => sum + ((doc.data()['priceInr'] as num?)?.toDouble() ?? 0));
      
      final lastRevenue = lastMonthPayments.docs.fold<double>(
          0, (sum, doc) => sum + ((doc.data()['priceInr'] as num?)?.toDouble() ?? 0));

      // Calculate Growth %
      double revenueGrowth = 0.0;
      if (lastRevenue > 0) {
        revenueGrowth = ((currentRevenue - lastRevenue) / lastRevenue) * 100;
      } else if (currentRevenue > 0) {
        revenueGrowth = 100.0; // 100% growth if there was no revenue last month
      }

      // Calculate Avg Order Value for current month
      final currentPaymentCount = currentMonthPayments.docs.length;
      final avgOrderValue =
          currentPaymentCount > 0 ? currentRevenue / currentPaymentCount : 0.0;

      // 4. Pending Approvals (status 'none' or 'pending')
      final pendingClients = await _fs.clients
          .where('subscriptionStatus', whereIn: ['none', 'pending'])
          .get();

      // 5. Phase 1: Clients with at least one active plan
      int clientsWithPlans = 0;
      try {
        final activePlans = await _fs.plans
            .where('isActive', isEqualTo: true)
            .get();
        final uidsWithPlan =
            activePlans.docs.map((d) => d.data()['clientId']).toSet();
        clientsWithPlans = uidsWithPlan.length;
      } catch (_) {}

      // 6. Phase 1: Weekly check-ins this month
      int checkinsThisMonth = 0;
      try {
        final checkinSnap = await _fs.weeklyUpdates
            .where('submittedAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfCurrentMonth))
            .get();
        checkinsThisMonth = checkinSnap.docs.length;
      } catch (_) {}

      return {
        'activeSubscriptions': activeSubCount,
        'totalClients': allClients.docs.length,
        'totalRevenue': currentRevenue,
        'pendingApprovals': pendingClients.docs.length,
        'revenueGrowth': revenueGrowth,
        'avgOrderValue': avgOrderValue,
        'clientsWithPlans': clientsWithPlans,     // Phase 1
        'checkinsThisMonth': checkinsThisMonth,   // Phase 1
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

      // Phase 1: Recent client signups
      try {
        final recentSignups = await _fs.users
            .where('role', isEqualTo: 'client')
            .orderBy('createdAt', descending: true)
            .limit(3)
            .get();
        for (final doc in recentSignups.docs) {
          final data = doc.data();
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
          activities.add({
            'type': 'client',
            'message':
                '${data['name'] ?? data['email'] ?? 'New client'} joined',
            'timestamp': createdAt?.toIso8601String() ?? '',
            'priority': 'low',
            'clientId': doc.id,
          });
        }
      } catch (_) {}

      activities.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
      return activities.take(10).toList();
    } catch (e) {
      throw Exception('Failed to fetch recent activity: $e');
    }
  }
}
