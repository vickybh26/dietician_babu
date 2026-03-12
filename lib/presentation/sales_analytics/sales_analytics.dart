import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../services/firebase_service.dart';
import '../admin_dashboard_overview/widgets/admin_scaffold.dart';

class SalesAnalytics extends StatefulWidget {
  const SalesAnalytics({super.key});

  @override
  State<SalesAnalytics> createState() => _SalesAnalyticsState();
}

class _SalesAnalyticsState extends State<SalesAnalytics> {
  final _fs = FirebaseService.instance;
  bool _isLoading = true;

  double _totalRevenue = 0;
  double _monthlyRevenue = 0;
  int _totalTransactions = 0;
  int _monthlyTransactions = 0;
  List<Map<String, dynamic>> _transactions = [];
  Map<String, double> _planRevenue = {};
  Map<String, int> _monthlyData = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final allPayments = await _fs.payments
          .where('status', isEqualTo: 'success')
          .orderBy('paidAt', descending: true)
          .get();

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      double total = 0;
      double monthly = 0;
      int totalTx = 0;
      int monthlyTx = 0;
      final Map<String, double> planRev = {};
      final Map<String, int> monthlyData = {};
      final List<Map<String, dynamic>> transactions = [];

      for (final doc in allPayments.docs) {
        final data = doc.data();
        final amount = (data['priceInr'] as num?)?.toDouble() ?? 0;
        final paidAt = (data['paidAt'] as Timestamp?)?.toDate() ?? now;
        final planName = data['planName'] as String? ?? 'Unknown';

        total += amount;
        totalTx++;

        // Monthly breakdown key: "Jan 2025"
        final monthKey = DateFormat('MMM yyyy').format(paidAt);
        monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + 1;

        // Plan revenue breakdown
        planRev[planName] = (planRev[planName] ?? 0) + amount;

        if (paidAt.isAfter(startOfMonth)) {
          monthly += amount;
          monthlyTx++;
        }

        // Fetch client name
        final clientId = data['clientId'] as String?;
        String clientName = 'Unknown';
        if (clientId != null) {
          final userSnap = await _fs.users.doc(clientId).get();
          clientName = userSnap.data()?['displayName'] ??
              userSnap.data()?['name'] ??
              userSnap.data()?['email'] ??
              'Unknown';
        }

        transactions.add({
          'clientName': clientName,
          'planName': planName,
          'amount': amount,
          'paidAt': paidAt,
          'paymentId': data['razorpayPaymentId'] ?? '',
        });
      }

      setState(() {
        _totalRevenue = total;
        _monthlyRevenue = monthly;
        _totalTransactions = totalTx;
        _monthlyTransactions = monthlyTx;
        _transactions = transactions;
        _planRevenue = planRev;
        _monthlyData = monthlyData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Sales Analytics',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildSummaryCards(),
                  const SizedBox(height: 24),
                  LayoutBuilder(builder: (context, constraints) {
                    if (constraints.maxWidth >= 500) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildPlanBreakdown()),
                          const SizedBox(width: 16),
                          Expanded(child: _buildMonthlyBreakdown()),
                        ],
                      );
                    }
                    return Column(children: [
                      _buildPlanBreakdown(),
                      const SizedBox(height: 16),
                      _buildMonthlyBreakdown(),
                    ]);
                  }),
                  const SizedBox(height: 24),
                  _buildTransactionsList(),
                ],
              ),
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
            Text('Sales Analytics', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[800])),
            Text('All payment data from Razorpay transactions', style: GoogleFonts.inter(color: Colors.grey[600])),
          ],
        ),
        IconButton(onPressed: _loadAnalytics, icon: const Icon(Icons.refresh), tooltip: 'Refresh'),
      ],
    );
  }

  Widget _buildSummaryCards() {
    final c1 = _statCard('Total Revenue', '₹${NumberFormat('#,##,###').format(_totalRevenue)}', Icons.account_balance_wallet, const Color(0xFF2E7D32), '$_totalTransactions transactions');
    final c2 = _statCard('This Month', '₹${NumberFormat('#,##,###').format(_monthlyRevenue)}', Icons.calendar_month, const Color(0xFF1976D2), '$_monthlyTransactions new payments');
    final c3 = _statCard('Avg. Order', _totalTransactions > 0 ? '₹${NumberFormat('#,###').format(_totalRevenue / _totalTransactions)}' : '₹0', Icons.trending_up, const Color(0xFFf5a40d), 'Per transaction');
    final c4 = _statCard('Plans Sold', '$_totalTransactions', Icons.receipt_long, const Color(0xFF9C27B0), 'Total subscriptions');

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth >= 600) {
        return Row(children: [c1, const SizedBox(width: 16), c2, const SizedBox(width: 16), c3, const SizedBox(width: 16), c4]);
      }
      return Column(children: [
        Row(children: [c1, const SizedBox(width: 12), c2]),
        const SizedBox(height: 12),
        Row(children: [c3, const SizedBox(width: 12), c4]),
      ]);
    });
  }

  Widget _statCard(String title, String value, IconData icon, Color color, String sub) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey[800])),
            const SizedBox(height: 4),
            Text(title, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600])),
            Text(sub, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanBreakdown() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Revenue by Plan', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (_planRevenue.isEmpty)
            const Text('No data yet', style: TextStyle(color: Colors.grey))
          else
            ..._planRevenue.entries.map((e) {
              final pct = _totalRevenue > 0 ? e.value / _totalRevenue : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key, style: GoogleFonts.inter(fontSize: 13)),
                        Text('₹${NumberFormat('#,##,###').format(e.value)}',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF61b239)),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMonthlyBreakdown() {
    final sorted = _monthlyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final last6 = sorted.length > 6 ? sorted.sublist(sorted.length - 6) : sorted;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Subscriptions by Month', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (last6.isEmpty)
            const Text('No data yet', style: TextStyle(color: Colors.grey))
          else
            ...last6.map((e) {
              final maxVal = last6.map((x) => x.value).reduce((a, b) => a > b ? a : b);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(width: 70, child: Text(e.key, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: maxVal > 0 ? e.value / maxVal : 0,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation(Color(0xFF1976D2)),
                          minHeight: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${e.value}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Transaction History', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          if (_transactions.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('No transactions yet', style: TextStyle(color: Colors.grey)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _transactions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final tx = _transactions[i];
                final paidAt = tx['paidAt'] as DateTime;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF61b239).withOpacity(0.1),
                    child: const Icon(Icons.check, color: Color(0xFF61b239), size: 18),
                  ),
                  title: Text(tx['clientName'], style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                  subtitle: Text('${tx['planName']} • ${DateFormat('dd MMM yyyy').format(paidAt)}',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                  trailing: Text('₹${NumberFormat('#,###').format(tx['amount'])}',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF2E7D32))),
                );
              },
            ),
        ],
      ),
    );
  }
}
