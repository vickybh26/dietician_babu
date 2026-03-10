import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/firebase_service.dart';
import './widgets/consultation_reminder_widget.dart';
import './widgets/daily_calorie_progress_widget.dart';
import './widgets/meal_plan_preview_widget.dart';
import './widgets/step_counter_widget.dart';
import './widgets/water_intake_tracker_widget.dart';

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome>
    with TickerProviderStateMixin {
  int _currentIndex = 0;

  // Real user data from Firestore
  String _userName = 'Welcome';
  String _subscriptionPlan = 'none';
  String _subscriptionStatus = 'none';
  String _country = 'India';

  // Static dashboard data
  final Map<String, dynamic> _userData = {
    "targetCalories": 0, // Default to 0 to trigger nudge if not set
    "consumedCalories": 0,
    "targetWater": 0,    // Default to 0 to trigger nudge if not set
    "currentWater": 0,
    "targetSteps": 10000,
    "currentSteps": 0,
    "distanceKm": 0.0,
  };

  bool _isCalorieTargetSet = false;
  bool _isWaterTargetSet = false;

  List<Map<String, dynamic>> _todayMeals = [];

  Map<String, dynamic>? _upcomingConsultation;

  // Pedometer
  int _stepBaseline = -1;
  bool _stepPermissionDenied = false;
  StreamSubscription<StepCount>? _stepCountSubscription;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initPedometer();
  }

  @override
  void dispose() {
    _stepCountSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseService.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final clientSnap =
          await FirebaseService.instance.clients.doc(uid).get();
      final userSnap =
          await FirebaseService.instance.users.doc(uid).get();

      if (mounted) {
        final todayKey = DateTime.now().toIso8601String().substring(0, 10);
        int savedWaterMl = 0;
        int savedStepCount = 0;
        int savedConsumedCal = 0;
        int targetCal = 0;
        int targetWater = 0;
        bool calSet = false;
        bool waterSet = false;
        String country = 'India';
        Map<String, dynamic>? consultation;

        if (clientSnap.exists) {
          final data = clientSnap.data()!;

          final dailyStats = data['dailyStats'] as Map<String, dynamic>?;
          final todayStats = dailyStats?[todayKey] as Map<String, dynamic>?;
          savedWaterMl = (todayStats?['waterMl'] as num?)?.toInt() ?? 0;
          savedStepCount = (todayStats?['stepCount'] as num?)?.toInt() ?? 0;
          savedConsumedCal =
              (todayStats?['consumedCalories'] as num?)?.toInt() ?? 0;

          // Check if admin has explicitly set targets
          if (data['targetCalories'] != null && (data['targetCalories'] as num) > 0) {
            targetCal = (data['targetCalories'] as num).toInt();
            calSet = true;
          }
          if (data['targetWaterMl'] != null && (data['targetWaterMl'] as num) > 0) {
            targetWater = (data['targetWaterMl'] as num).toInt();
            waterSet = true;
          }

          country = data['country'] as String? ?? 'India';

          final nc = data['nextConsultation'] as Map<String, dynamic>?;
          if (nc != null && (nc['doctorName'] as String? ?? '').isNotEmpty) {
            String dateDisplay = nc['date'] as String? ?? '';
            try {
              final dt = DateTime.parse(dateDisplay);
              final today = DateTime.now();
              final diff = DateTime(dt.year, dt.month, dt.day)
                  .difference(DateTime(today.year, today.month, today.day))
                  .inDays;
              if (diff == 0) dateDisplay = 'Today';
              else if (diff == 1) dateDisplay = 'Tomorrow';
              else if (diff > 1) dateDisplay = '${dt.day}/${dt.month}/${dt.year}';
              else dateDisplay = 'Past';
            } catch (_) {}
            consultation = {
              'doctorName': nc['doctorName'],
              'date': dateDisplay,
              'time': nc['time'] ?? '',
              'type': nc['type'] ?? 'video',
            };
          }
        }

        setState(() {
          final phone = userSnap.data()?['phone'] as String? ?? '';
          final email = userSnap.data()?['email'] as String? ?? '';
          _userName = userSnap.data()?['name'] as String? ??
              (phone.isNotEmpty ? phone : email.split('@').first);

          if (clientSnap.exists) {
            _subscriptionPlan =
                clientSnap.data()?['subscriptionPlan'] as String? ?? 'none';
            _subscriptionStatus =
                clientSnap.data()?['subscriptionStatus'] as String? ?? 'none';
          }

          _userData['currentWater'] = savedWaterMl;
          _userData['currentSteps'] = savedStepCount;
          _userData['consumedCalories'] = savedConsumedCal;
          _userData['targetCalories'] = targetCal;
          _userData['targetWater'] = targetWater;
          _isCalorieTargetSet = calSet;
          _isWaterTargetSet = waterSet;
          _country = country;
          _upcomingConsultation = consultation;
        });
        _loadTodayMealsFromPlan();
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  // ── Pedometer ─────────────────────────────────────────────────────────────
  Future<void> _initPedometer() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.activityRecognition.request();
        if (!status.isGranted) {
          if (mounted) setState(() => _stepPermissionDenied = true);
          return;
        }
      }
      _stepCountSubscription = Pedometer.stepCountStream.listen(
        (StepCount event) async {
          final uid = FirebaseService.instance.currentUser?.uid;
          if (uid == null) return;
          final todayKey = DateTime.now().toIso8601String().substring(0, 10);

          if (_stepBaseline < 0) {
            final snap =
                await FirebaseService.instance.clients.doc(uid).get();
            final daily =
                snap.data()?['dailyStats'] as Map<String, dynamic>?;
            final today = daily?[todayKey] as Map<String, dynamic>?;
            final saved = (today?['stepBaseline'] as num?)?.toInt();
            if (saved != null) {
              _stepBaseline = saved;
            } else {
              _stepBaseline = event.steps;
              FirebaseService.instance.clients.doc(uid).set({
                'dailyStats': {
                  todayKey: {'stepBaseline': _stepBaseline}
                },
              }, SetOptions(merge: true)).catchError((_) {});
            }
          }

          final daily = (event.steps - _stepBaseline).clamp(0, 999999);
          if (mounted) {
            setState(() {
              _userData['currentSteps'] = daily;
              _userData['distanceKm'] =
                  double.parse((daily * 0.000762).toStringAsFixed(2));
            });
          }
          FirebaseService.instance.clients.doc(uid).set({
            'dailyStats': {
              todayKey: {'stepCount': daily}
            },
          }, SetOptions(merge: true)).catchError((_) {});
        },
        onError: (error) => debugPrint('Pedometer error: $error'),
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('Pedometer init error: $e');
    }
  }

  // ── Meal plan from Firestore ───────────────────────────────────────────────
  Future<void> _loadTodayMealsFromPlan() async {
    final uid = FirebaseService.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final snap = await FirebaseService.instance.plans
          .where('clientId', isEqualTo: uid)
          .where('format', isEqualTo: 'structured')
          .orderBy('uploadedAt', descending: true)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return;

      final plan = snap.docs.first.data() as Map<String, dynamic>;
      final days = (plan['weekPlan'] as List?) ?? [];
      final dayIdx = DateTime.now().weekday - 1; 
      if (dayIdx >= days.length) return;

      final dayData = days[dayIdx] as Map<String, dynamic>;
      const mealKeys = [
        'breakfast', 'midMorning', 'lunch', 'eveningSnack', 'dinner'
      ];

      // Regional Meal Times
      final Map<String, String> mealTimes;
      if (_country.toLowerCase() == 'usa') {
        mealTimes = {
          'breakfast': '7:00 AM',
          'midMorning': '10:00 AM',
          'lunch': '12:00 PM',
          'eveningSnack': '3:30 PM',
          'dinner': '6:30 PM',
        };
      } else if (_country.toLowerCase() == 'uk') {
        mealTimes = {
          'breakfast': '7:30 AM',
          'midMorning': '10:30 AM',
          'lunch': '1:00 PM',
          'eveningSnack': '4:00 PM',
          'dinner': '7:00 PM',
        };
      } else {
        // Default (India)
        mealTimes = {
          'breakfast': '8:30 AM',
          'midMorning': '11:00 AM',
          'lunch': '1:30 PM',
          'eveningSnack': '5:00 PM',
          'dinner': '8:30 PM',
        };
      }

      final meals = <Map<String, dynamic>>[];
      for (final key in mealKeys) {
        final items = (dayData[key] as List?) ?? [];
        for (final item in items) {
          final m = item as Map<String, dynamic>;
          meals.add({
            'id': '${key}_${m['name']}',
            'name': m['name'] ?? '',
            'type': key,
            'calories': (m['calories'] as num?)?.toInt() ?? 0,
            'quantity': m['quantity'] ?? '',
            'time': mealTimes[key] ?? '',
            'isLogged': false,
          });
        }
      }

      if (mounted && meals.isNotEmpty) {
        setState(() => _todayMeals = meals);
      }
    } catch (e) {
      debugPrint('Failed to load meal plan: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            margin: EdgeInsets.only(right: 3.w),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/Logo_DB-removebg-preview-1757171544580.png',
                width: 8.w,
                height: 8.w,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome', // Changed from Good Morning
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                _userName,
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Container(
          margin: EdgeInsets.only(right: 4.w),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/settings-profile'),
                child: Container(
                  width: 10.w,
                  height: 10.w,
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: CustomIconWidget(
                    iconName: 'person',
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              GestureDetector(
                onTap: _handleLogout,
                child: Container(
                  width: 10.w,
                  height: 10.w,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.logout_rounded,
                      color: Colors.red, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogout() async {
    await FirebaseService.instance.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/landing');
    }
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            SizedBox(height: 1.h),

            _buildQuickActions(),

            // Daily Calorie Progress with Nudge
            DailyCalorieProgressWidget(
              consumedCalories: _userData['consumedCalories'] as int,
              targetCalories: _userData['targetCalories'] as int,
              isTargetSet: _isCalorieTargetSet,
              onTap: _showCalorieDetails,
              onNudgeAdmin: () => _nudgeAdmin('calories'),
            ),

            // Water Intake Tracker with Nudge
            WaterIntakeTrackerWidget(
              currentIntake: _userData['currentWater'] as int,
              targetIntake: _userData['targetWater'] as int,
              isTargetSet: _isWaterTargetSet,
              onAdd250ml: () => _addWater(250),
              onAdd500ml: () => _addWater(500),
              onNudgeAdmin: () => _nudgeAdmin('water'),
            ),

            MealPlanPreviewWidget(
              todayMeals: _todayMeals,
              onLogMeal: _showMealLogging,
            ),

            StepCounterWidget(
              currentSteps: _userData['currentSteps'] as int,
              targetSteps: _userData['targetSteps'] as int,
              distanceKm: _userData['distanceKm'] as double,
            ),

            ConsultationReminderWidget(
              upcomingConsultation: _upcomingConsultation,
              onViewDetails: _viewConsultationDetails,
              onScheduleNew: _scheduleNewConsultation,
            ),

            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }

  void _nudgeAdmin(String type) async {
    final uid = FirebaseService.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseService.instance.db.collection('nudges').add({
        'clientId': uid,
        'clientName': _userName,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nudge sent to dietician for $type!')),
        );
      }
    } catch (e) {
      debugPrint('Failed to nudge admin: $e');
    }
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _onBottomNavTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      selectedItemColor: AppTheme.lightTheme.colorScheme.primary,
      unselectedItemColor: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
      elevation: 8,
      items: [
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'home',
            color: _currentIndex == 0
                ? AppTheme.lightTheme.colorScheme.primary
                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'person',
            color: _currentIndex == 1
                ? AppTheme.lightTheme.colorScheme.primary
                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Profile',
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _showQuickLogBottomSheet,
      backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
      foregroundColor: AppTheme.lightTheme.colorScheme.onSecondary,
      elevation: 4,
      icon: CustomIconWidget(
        iconName: 'add',
        color: AppTheme.lightTheme.colorScheme.onSecondary,
        size: 20,
      ),
      label: Text(
        'Quick Log',
        style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppTheme.lightTheme.colorScheme.onSecondary,
        ),
      ),
    );
  }

  // ── Quick Actions ─────────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    final bool hasSubscription =
        _subscriptionStatus == 'active';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hasSubscription)
            GestureDetector(
              onTap: () =>
                  Navigator.pushNamed(context, '/subscription-plans'),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(3.w),
                margin: EdgeInsets.only(bottom: 2.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFf5a40d), Color(0xFFe8960a)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFFf5a40d).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3))
                  ],
                ),
                child: Row(
                  children: [
                    const Text('🌟', style: TextStyle(fontSize: 22)),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('No active plan',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                          Text('Tap to subscribe and get your diet plan',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.white, size: 16),
                  ],
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(3.w),
              margin: EdgeInsets.only(bottom: 2.h),
              decoration: BoxDecoration(
                color: const Color(0xFF61b239).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFF61b239).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Text('✅', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 3.w),
                  Text(
                    '$_subscriptionPlan Plan — Active',
                    style: const TextStyle(
                        color: Color(0xFF61b239),
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                  ),
                ],
              ),
            ),

          Text(
            'Quick Access',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 1.5.h),
          Row(
            children: [
              _actionTile('📋', 'My Diet Plan', '/diet-plan-viewer',
                  const Color(0xFF61b239)),
              SizedBox(width: 3.w),
              _actionTile('📝', 'Weekly\nCheck-in', '/weekly-checkin',
                  const Color(0xFF2196F3)),
            ],
          ),
          SizedBox(height: 2.w),
          Row(
            children: [
              _actionTile('📈', 'My Progress', '/progress-tracking',
                  const Color(0xFF9c27b0)),
              SizedBox(width: 3.w),
              _actionTile('💳', 'Subscription', '/subscription-plans',
                  const Color(0xFFf5a40d)),
            ],
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _actionTile(
      String emoji, String label, String route, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, route),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 3.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: color.withOpacity(0.85)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Event handlers
  Future<void> _handleRefresh() async {
    await _loadUserData();
  }

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
        setState(() => _currentIndex = 0);
        break;
      case 1:
        // Profile — navigate to full Settings/Profile screen
        Navigator.pushNamed(context, '/settings-profile');
        break;
    }
  }

  void _showCalorieDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCalorieDetailsBottomSheet(),
    );
  }

  void _addWater(int amount) {
    final newTotal = ((_userData['currentWater'] as int) + amount)
        .clamp(0, (_userData['targetWater'] as int) + 1000) as int;
    setState(() => _userData['currentWater'] = newTotal);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${amount}ml water! Total: ${newTotal}ml'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.blue,
      ),
    );

    final uid = FirebaseService.instance.currentUser?.uid;
    if (uid != null) {
      final todayKey = DateTime.now().toIso8601String().substring(0, 10);
      FirebaseService.instance.clients.doc(uid).set({
        'dailyStats': {todayKey: {'waterMl': newTotal}},
      }, SetOptions(merge: true)).catchError((e) {
        debugPrint('Failed to persist water intake: $e');
      });
    }
  }

  void _logWeight() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Weight'),
        content: TextFormField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Weight (kg)',
            hintText: 'e.g. 72.5',
            prefixIcon: Icon(Icons.monitor_weight_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final kg = double.tryParse(ctrl.text.trim());
              if (kg == null || kg <= 0 || kg > 300) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid weight')),
                );
                return;
              }
              Navigator.pop(ctx);
              final uid = FirebaseService.instance.currentUser?.uid;
              if (uid == null) return;
              try {
                await FirebaseService.instance.clients.doc(uid).set(
                  {'weightKg': kg},
                  SetOptions(merge: true),
                );
                await FirebaseService.instance.clients
                    .doc(uid)
                    .collection('weightHistory')
                    .add({
                  'weightKg': kg,
                  'recordedAt': FieldValue.serverTimestamp(),
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Weight logged: ${kg.toStringAsFixed(1)} kg ✓'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to save weight: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showMealLogging() {
    _logMeal();
  }

  void _logMeal() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    final nameCtrl = TextEditingController();
    final calCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        String selectedType = 'breakfast';
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Log Meal'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Food name',
                    hintText: 'e.g. Rice and Dal',
                    prefixIcon: Icon(Icons.restaurant),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: calCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Calories (kcal)',
                    hintText: 'e.g. 350',
                    prefixIcon: Icon(Icons.local_fire_department),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Meal type',
                    prefixIcon: Icon(Icons.schedule),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'breakfast', child: Text('Breakfast')),
                    DropdownMenuItem(
                        value: 'midMorning', child: Text('Mid-Morning')),
                    DropdownMenuItem(value: 'lunch', child: Text('Lunch')),
                    DropdownMenuItem(
                        value: 'eveningSnack', child: Text('Evening Snack')),
                    DropdownMenuItem(value: 'dinner', child: Text('Dinner')),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => selectedType = v!),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final cal = int.tryParse(calCtrl.text.trim()) ?? 0;
                  if (name.isEmpty) return;
                  Navigator.pop(ctx);
                  final uid = FirebaseService.instance.currentUser?.uid;
                  if (uid == null) return;
                  final todayKey =
                      DateTime.now().toIso8601String().substring(0, 10);
                  try {
                    await FirebaseService.instance.clients
                        .doc(uid)
                        .collection('mealLogs')
                        .add({
                      'name': name,
                      'calories': cal,
                      'mealType': selectedType,
                      'loggedAt': FieldValue.serverTimestamp(),
                      'date': todayKey,
                    });
                    final newCal =
                        (_userData['consumedCalories'] as int) + cal;
                    await FirebaseService.instance.clients.doc(uid).set({
                      'dailyStats': {
                        todayKey: {'consumedCalories': newCal}
                      },
                    }, SetOptions(merge: true));
                    if (mounted) {
                      setState(
                          () => _userData['consumedCalories'] = newCal);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Meal logged: $name ($cal kcal) ✓'),
                        backgroundColor: Colors.green,
                      ));
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to log meal: $e')));
                    }
                  }
                },
                child: const Text('Log'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _logExercise() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    final typeCtrl = TextEditingController();
    final durationCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Exercise'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: typeCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Activity type',
                hintText: 'e.g. Walking, Yoga, Cycling',
                prefixIcon: Icon(Icons.fitness_center),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: durationCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Duration (minutes)',
                hintText: 'e.g. 30',
                prefixIcon: Icon(Icons.timer),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final type = typeCtrl.text.trim();
              final mins = int.tryParse(durationCtrl.text.trim()) ?? 0;
              if (type.isEmpty) return;
              Navigator.pop(ctx);
              final uid = FirebaseService.instance.currentUser?.uid;
              if (uid == null) return;
              try {
                await FirebaseService.instance.clients
                    .doc(uid)
                    .collection('exerciseLogs')
                    .add({
                  'type': type,
                  'durationMinutes': mins,
                  'loggedAt': FieldValue.serverTimestamp(),
                  'date':
                      DateTime.now().toIso8601String().substring(0, 10),
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content:
                        Text('Exercise logged: $type ($mins min) ✓'),
                    backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to log exercise: $e')));
                }
              }
            },
            child: const Text('Log'),
          ),
        ],
      ),
    );
  }

  void _viewConsultationDetails() {
    if (_upcomingConsultation == null) return;
    showDialog(
      context: context,
      builder: (context) => _buildConsultationDialog(),
    );
  }

  void _scheduleNewConsultation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening consultation scheduler...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showQuickLogBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildQuickLogBottomSheet(),
    );
  }

  // Bottom sheet builders
  Widget _buildCalorieDetailsBottomSheet() {
    return Container(
      height: 50.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Calorie Breakdown',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          _buildNutrientRow(
              'Consumed', '${_userData['consumedCalories']} cal', Colors.green),
          _buildNutrientRow(
              'Remaining',
              '${_userData['targetCalories'] - _userData['consumedCalories']} cal',
              Colors.orange),
          _buildNutrientRow('Target', '${_userData['targetCalories']} cal',
              AppTheme.lightTheme.colorScheme.primary),
        ],
      ),
    );
  }


  Widget _buildQuickLogBottomSheet() {
    return Container(
      height: 40.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Quick Log',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                  child: _buildQuickLogOption(
                      'Log Meal', 'restaurant', _logMeal)),
              SizedBox(width: 2.w),
              Expanded(
                  child: _buildQuickLogOption(
                      'Add Water', 'water_drop', () => _addWater(250))),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                  child: _buildQuickLogOption(
                      'Log Weight', 'monitor_weight', _logWeight)),
              SizedBox(width: 2.w),
              Expanded(
                  child: _buildQuickLogOption(
                      'Add Exercise', 'fitness_center', _logExercise)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationDialog() {
    return AlertDialog(
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        'Upcoming Consultation',
        style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConsultationDetailRow(
              'Doctor', 'Dr. ${_upcomingConsultation!['doctorName']}'),
          _buildConsultationDetailRow(
              'Date', _upcomingConsultation!['date'] as String),
          _buildConsultationDetailRow(
              'Time', _upcomingConsultation!['time'] as String),
          _buildConsultationDetailRow('Type', 'Video Call'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  // Helper widgets
  Widget _buildNutrientRow(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLogOption(
      String title, String iconName, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            CustomIconWidget(
              iconName: iconName,
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 24,
            ),
            SizedBox(height: 1.h),
            Text(
              title,
              style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsultationDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20.w,
            child: Text(
              '$label:',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
