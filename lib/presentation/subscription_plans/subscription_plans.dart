import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:sizer/sizer.dart';

import '../../services/firebase_service.dart';
import '../../config/secrets.dart';
import '../../theme/app_theme.dart';

class SubscriptionPlans extends StatefulWidget {
  const SubscriptionPlans({Key? key}) : super(key: key);
  @override
  State<SubscriptionPlans> createState() => _SubscriptionPlansState();
}

class _SubscriptionPlansState extends State<SubscriptionPlans> {
  late Razorpay _razorpay;
  bool _isProcessing = false;
  int _selectedPlanIndex = 1; // default to middle plan

  final List<Map<String, dynamic>> _plans = [
    {
      'name': 'Regular',
      'subtitle': 'Get started',
      'priceInr': 2499,
      'durationDays': 30,
      'emoji': '🥗',
      'color': const Color(0xFF61b239),
      'features': [
        '1 personalised diet plan',
        'Weekly check-in tracking',
        'Email support',
        'Progress charts',
      ],
    },
    {
      'name': 'Rapid',
      'subtitle': 'Most popular',
      'priceInr': 4499,
      'durationDays': 60,
      'emoji': '⚡',
      'color': const Color(0xFFf5a40d),
      'features': [
        '2 personalised diet plans',
        'Weekly check-in tracking',
        'WhatsApp + Email support',
        'Progress charts',
        'Follow-up consultation',
      ],
      'badge': 'POPULAR',
    },
    {
      'name': 'Super',
      'subtitle': 'Best results',
      'priceInr': 5999,
      'durationDays': 90,
      'emoji': '🏆',
      'color': const Color(0xFF9c27b0),
      'features': [
        '3 personalised diet plans',
        'Weekly check-in tracking',
        'Priority WhatsApp support',
        'Advanced progress tracking',
        'Monthly consultations',
        'Custom meal planning',
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final uid = FirebaseService.instance.currentUser?.uid;
    if (uid == null) return;

    final plan = _plans[_selectedPlanIndex];
    final now = DateTime.now();
    final expiry =
        now.add(Duration(days: plan['durationDays'] as int));

    try {
      // Save payment record
      await FirebaseService.instance.payments.add({
        'clientId': uid,
        'planName': plan['name'],
        'priceInr': plan['priceInr'],
        'razorpayPaymentId': response.paymentId ?? '',
        'razorpayOrderId': response.orderId ?? '',
        'status': 'success',
        'paidAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiry),
      });

      // Update client subscription status
      await FirebaseService.instance.clients.doc(uid).set({
        'subscriptionPlan': plan['name'],
        'subscriptionStatus': 'active',
        'subscriptionExpiresAt': Timestamp.fromDate(expiry),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() => _isProcessing = false);
        _showSuccessDialog(plan['name'] as String);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showSnack('Payment recorded but profile update failed. Contact support.', error: true);
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      setState(() => _isProcessing = false);
      _showSnack('Payment failed: ${response.message ?? 'Unknown error'}', error: true);
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      setState(() => _isProcessing = false);
      _showSnack('External wallet: ${response.walletName}');
    }
  }

  void _startPayment(Map<String, dynamic> plan) {
    final user = FirebaseService.instance.currentUser;
    if (user == null) return;

    setState(() => _isProcessing = true);

    final options = {
      'key': AppSecrets.razorpayKey,
      'amount': (plan['priceInr'] as int) * 100, // in paise
      'name': 'Dietician Babu',
      'description': '${plan['name']} Plan – ${plan['durationDays']} days',
      'prefill': {
        'contact': user.phoneNumber ?? '',
        'email': user.email ?? '',
      },
      'theme': {
        'color': '#61b239',
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      setState(() => _isProcessing = false);
      _showSnack('Could not open payment gateway: $e', error: true);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red.shade600 : Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showSuccessDialog(String planName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                  color: Colors.green.shade50, shape: BoxShape.circle),
              child: Icon(Icons.check_circle_rounded,
                  color: Colors.green.shade500, size: 48),
            ),
            SizedBox(height: 2.h),
            const Text('Payment Successful! 🎉',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            SizedBox(height: 1.h),
            Text(
              'You are now on the $planName plan. Your dietician will be in touch soon!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.pushReplacementNamed(context, '/dashboard-home');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Go to Dashboard'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Choose a Plan'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: [
                  SizedBox(height: 1.h),
                  Text(
                    'Start your nutrition journey today',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 2.h),
                  ...List.generate(_plans.length, (i) {
                    final plan = _plans[i];
                    final isSelected = _selectedPlanIndex == i;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedPlanIndex = i),
                      child: _PlanCard(
                          plan: plan, isSelected: isSelected),
                    );
                  }),
                  SizedBox(height: 2.h),
                  // Secure payment note
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_rounded,
                          size: 14, color: Colors.grey.shade500),
                      SizedBox(width: 1.w),
                      Text(
                        'Secure payment via Razorpay',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                ],
              ),
            ),
          ),

          // Bottom CTA
          Container(
            padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 3.h),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -4))
              ],
            ),
            child: Column(
              children: [
                Text(
                  '${_plans[_selectedPlanIndex]['emoji']}  ${_plans[_selectedPlanIndex]['name']} Plan  –  '
                  '₹${_plans[_selectedPlanIndex]['priceInr']} / ${_plans[_selectedPlanIndex]['durationDays']} days',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
                SizedBox(height: 1.5.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessing
                        ? null
                        : () => _startPayment(_plans[_selectedPlanIndex]),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          AppTheme.lightTheme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 1.8.h),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Pay Now  🔒',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                  ),
                ),
                SizedBox(height: 0.5.h),
                TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard-home'),
                  child: Text(
                    'Already subscribed? Enter the app →',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final bool isSelected;
  const _PlanCard({required this.plan, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final color = plan['color'] as Color;
    final badge = plan['badge'] as String?;
    final features = plan['features'] as List<String>;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? color : Colors.grey.shade200,
          width: isSelected ? 2.5 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                    color: color.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ]
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              color: isSelected ? color : Colors.grey.shade50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
            child: Row(
              children: [
                Text(plan['emoji'] as String,
                    style: const TextStyle(fontSize: 24)),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan['name'] as String,
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color:
                                isSelected ? Colors.white : Colors.grey.shade900),
                      ),
                      Text(
                        plan['subtitle'] as String,
                        style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? Colors.white70
                                : Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${plan['priceInr']}',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: isSelected ? Colors.white : color),
                    ),
                    Text(
                      '${plan['durationDays']} days',
                      style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? Colors.white70
                              : Colors.grey.shade500),
                    ),
                  ],
                ),
                if (badge != null) ...[
                  SizedBox(width: 2.w),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                          color: color,
                          fontSize: 9,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Features
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              children: features
                  .map((f) => Padding(
                        padding: EdgeInsets.only(bottom: 0.8.h),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_rounded,
                                size: 16,
                                color: isSelected ? color : Colors.green.shade500),
                            SizedBox(width: 2.w),
                            Text(f,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade800)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
