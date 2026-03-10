import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/firebase_service.dart';
import './widgets/achievement_badge_widget.dart';
import './widgets/measurement_card_widget.dart';
import './widgets/photo_comparison_widget.dart';
import './widgets/progress_chart_widget.dart';
import './widgets/quick_entry_bottom_sheet.dart';
import './widgets/stats_card_widget.dart';
import './widgets/time_period_selector_widget.dart';

class ProgressTracking extends StatefulWidget {
  const ProgressTracking({Key? key}) : super(key: key);

  @override
  State<ProgressTracking> createState() => _ProgressTrackingState();
}

class _ProgressTrackingState extends State<ProgressTracking>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = '1M';
  int _currentBottomNavIndex = 1; // Progress tab active

  // ── Weight (from weeklyUpdates) ───────────────────────────────────────────
  List<Map<String, dynamic>> _weightData = [];
  double _currentWeight = 0.0;
  double _weightChange = 0.0;
  bool _loadingWeight = true;

  // ── Measurements (from clients/{uid}/measurements subcollection) ──────────
  List<Map<String, dynamic>> _measurementData = [];
  bool _loadingMeasurements = true;

  // ── Nutrition (derived from active plan) ──────────────────────────────────
  List<Map<String, dynamic>> _nutritionData = [];
  int _dailyCaloriesFromPlan = 0;
  bool _loadingNutrition = true;

  // ── Activity (from clients/{uid}.dailyStats) ───────────────────────────────
  int _todaySteps = 0;
  double _todayDistanceKm = 0.0;
  int _todayCaloriesBurned = 0;
  int _todayActiveMinutes = 0;
  List<Map<String, dynamic>> _weeklyStepData = [];
  bool _loadingActivity = true;

  // ── Achievements (computed from real data) ─────────────────────────────────
  List<Map<String, dynamic>> _achievementData = [
    {'title': 'First Week', 'description': 'Complete your first week', 'iconName': 'star', 'isUnlocked': false},
    {'title': '5kg Lost', 'description': 'Lost 5 kilograms', 'iconName': 'trending_down', 'isUnlocked': false},
    {'title': 'Consistent', 'description': '4+ check-ins (≈30 days)', 'iconName': 'local_fire_department', 'isUnlocked': false},
    {'title': 'Goal Reached', 'description': 'Reached target weight', 'iconName': 'emoji_events', 'isUnlocked': false},
  ];
  double _goalWeightKg = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadWeightData();
    _loadMeasurements();
    _loadActivityStats();
    _loadNutritionFromPlan();
  }

  Future<void> _loadWeightData() async {
    final uid = FirebaseService.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loadingWeight = false);
      return;
    }
    try {
      // Load from both sources in parallel
      final results = await Future.wait([
        FirebaseService.instance.weeklyUpdates
            .where('clientId', isEqualTo: uid)
            .orderBy('submittedAt')
            .get(),
        FirebaseService.instance.clients
            .doc(uid)
            .collection('weightHistory')
            .orderBy('recordedAt')
            .get(),
        FirebaseService.instance.clients.doc(uid).get(),
      ]);

      final weeklySnap = results[0] as QuerySnapshot<Map<String, dynamic>>;
      final historySnap = results[1] as QuerySnapshot<Map<String, dynamic>>;
      final clientSnap = results[2] as DocumentSnapshot<Map<String, dynamic>>;

      // Build a unified list of {date: DateTime, weight: double}
      final entries = <Map<String, dynamic>>[];

      for (final doc in weeklySnap.docs) {
        final ts = doc.data()['submittedAt'] as Timestamp?;
        final w = (doc.data()['weightKg'] as num?)?.toDouble() ?? 0.0;
        if (ts != null && w > 0) {
          entries.add({'date': ts.toDate(), 'weight': w});
        }
      }
      for (final doc in historySnap.docs) {
        final ts = doc.data()['recordedAt'] as Timestamp?;
        final w = (doc.data()['weightKg'] as num?)?.toDouble() ?? 0.0;
        if (ts != null && w > 0) {
          entries.add({'date': ts.toDate(), 'weight': w});
        }
      }

      // Sort combined list by date ascending
      entries.sort((a, b) =>
          (a['date'] as DateTime).compareTo(b['date'] as DateTime));

      // Fallback: use client doc weight if no history yet
      if (entries.isEmpty) {
        final curW =
            (clientSnap.data()?['weightKg'] as num?)?.toDouble() ?? 0.0;
        if (mounted) {
          setState(() {
            _currentWeight = curW;
            _weightChange = 0.0;
            _weightData = [];
            _loadingWeight = false;
          });
        }
        return;
      }

      // Take last 8 points for chart
      const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final chartEntries =
          entries.length > 8 ? entries.sublist(entries.length - 8) : entries;
      final chartData = chartEntries.map((e) {
        final d = e['date'] as DateTime;
        return {
          'label': '${months[d.month]} ${d.day}',
          'value': e['weight'] as double,
        };
      }).toList();

      final firstWeight = (entries.first['weight'] as double);
      final lastWeight = (entries.last['weight'] as double);
      final change = firstWeight > 0 ? lastWeight - firstWeight : 0.0;

      if (mounted) {
        setState(() {
          _weightData = chartData;
          _currentWeight = lastWeight;
          _weightChange = change;
          _loadingWeight = false;
        });
        // Recompute achievements now that we have weight data
        _computeAchievements(
          checkinCount: entries.length,
          weightChange: change,
          goalWeightKg: _goalWeightKg,
          currentWeight: lastWeight,
        );
      }
    } catch (e) {
      debugPrint('_loadWeightData error: $e');
      if (mounted) setState(() => _loadingWeight = false);
    }
  }

  // ── Load Measurements ─────────────────────────────────────────────────────
  Future<void> _loadMeasurements() async {
    final uid = FirebaseService.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loadingMeasurements = false);
      return;
    }
    try {
      final snap = await FirebaseService.instance.clients
          .doc(uid)
          .collection('measurements')
          .orderBy('recordedAt', descending: true)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        if (mounted) setState(() => _loadingMeasurements = false);
        return;
      }
      final data = snap.docs.first.data();
      final parts = ['waist', 'chest', 'arms', 'thighs'];
      final List<Map<String, dynamic>> loaded = [];
      for (final part in parts) {
        final val = (data[part] as num?)?.toDouble();
        if (val != null && val > 0) {
          loaded.add({
            'bodyPart': part[0].toUpperCase() + part.substring(1),
            'measurement': val.toStringAsFixed(1),
            'unit': 'cm',
            'change': '',
            'isPositiveChange': true,
          });
        }
      }
      if (mounted) setState(() { _measurementData = loaded; _loadingMeasurements = false; });
    } catch (e) {
      debugPrint('_loadMeasurements error: $e');
      if (mounted) setState(() => _loadingMeasurements = false);
    }
  }

  // ── Load Activity Stats ───────────────────────────────────────────────────
  Future<void> _loadActivityStats() async {
    final uid = FirebaseService.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loadingActivity = false);
      return;
    }
    try {
      final snap = await FirebaseService.instance.clients.doc(uid).get();
      final dailyStats = snap.data()?['dailyStats'] as Map<String, dynamic>? ?? {};
      final weeklyData = <Map<String, dynamic>>[];
      final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      for (int i = 6; i >= 0; i--) {
        final day = DateTime.now().subtract(Duration(days: i));
        final key = day.toIso8601String().substring(0, 10);
        final dayData = dailyStats[key] as Map<String, dynamic>?;
        final steps = (dayData?['stepCount'] as num?)?.toInt() ?? 0;
        weeklyData.add({'label': dayLabels[day.weekday - 1], 'value': steps});
      }

      final todayKey = DateTime.now().toIso8601String().substring(0, 10);
      final todayData = dailyStats[todayKey] as Map<String, dynamic>?;
      final steps = (todayData?['stepCount'] as num?)?.toInt() ?? 0;
      final activeMin = (todayData?['activeMinutes'] as num?)?.toInt() ?? (steps ~/ 120);

      if (mounted) {
        setState(() {
          _todaySteps = steps;
          _todayDistanceKm = double.parse((steps * 0.000762).toStringAsFixed(2));
          _todayCaloriesBurned = (steps * 0.04).round();
          _todayActiveMinutes = activeMin;
          _weeklyStepData = weeklyData;
          _loadingActivity = false;
        });
      }
    } catch (e) {
      debugPrint('_loadActivityStats error: $e');
      if (mounted) setState(() => _loadingActivity = false);
    }
  }

  // ── Load Nutrition from Active Plan ───────────────────────────────────────
  Future<void> _loadNutritionFromPlan() async {
    final uid = FirebaseService.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loadingNutrition = false);
      return;
    }
    try {
      final snap = await FirebaseService.instance.plans
          .where('clientId', isEqualTo: uid)
          .where('format', isEqualTo: 'structured')
          .orderBy('uploadedAt', descending: true)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) {
        if (mounted) setState(() => _loadingNutrition = false);
        return;
      }
      final plan = snap.docs.first.data();
      final days = (plan['weekPlan'] as List?) ?? [];
      final dayIdx = DateTime.now().weekday - 1;
      if (dayIdx >= days.length) {
        if (mounted) setState(() => _loadingNutrition = false);
        return;
      }
      final dayData = days[dayIdx] as Map<String, dynamic>;
      // Sum total calories for the day across all meal slots
      int totalCal = 0;
      for (final key in ['breakfast', 'midMorning', 'lunch', 'eveningSnack', 'dinner']) {
        final items = (dayData[key] as List?) ?? [];
        for (final item in items) {
          totalCal += ((item as Map<String, dynamic>)['calories'] as num?)?.toInt() ?? 0;
        }
      }
      // Approximate macro split (standard balanced diet percentages as fallback)
      // If plan contains explicit macros, use those instead
      final macros = plan['macros'] as Map<String, dynamic>?;
      final int protein = macros != null ? (macros['proteinPct'] as num?)?.toInt() ?? 25 : 25;
      final int carbs   = macros != null ? (macros['carbPct'] as num?)?.toInt() ?? 50 : 50;
      final int fats    = macros != null ? (macros['fatPct'] as num?)?.toInt() ?? 20 : 20;
      final int fiber   = 100 - protein - carbs - fats;

      if (mounted) {
        setState(() {
          _dailyCaloriesFromPlan = totalCal;
          _nutritionData = [
            {'label': 'Protein', 'value': protein, 'percentage': protein},
            {'label': 'Carbs',   'value': carbs,   'percentage': carbs},
            {'label': 'Fats',    'value': fats,    'percentage': fats},
            {'label': 'Fiber',   'value': fiber.clamp(0, 100), 'percentage': fiber.clamp(0, 100)},
          ];
          _loadingNutrition = false;
        });
      }
    } catch (e) {
      debugPrint('_loadNutritionFromPlan error: $e');
      if (mounted) setState(() => _loadingNutrition = false);
    }
  }

  // ── Compute Achievements ──────────────────────────────────────────────────
  void _computeAchievements({
    required int checkinCount,
    required double weightChange,
    required double goalWeightKg,
    required double currentWeight,
  }) {
    if (!mounted) return;
    setState(() {
      _achievementData = [
        {
          'title': 'First Week',
          'description': 'Complete your first check-in',
          'iconName': 'star',
          'isUnlocked': checkinCount >= 1,
        },
        {
          'title': '5kg Lost',
          'description': 'Lost 5 kilograms',
          'iconName': 'trending_down',
          'isUnlocked': weightChange <= -5.0,
        },
        {
          'title': 'Consistent',
          'description': '4+ check-ins (≈30 days)',
          'iconName': 'local_fire_department',
          'isUnlocked': checkinCount >= 4,
        },
        {
          'title': 'Goal Reached',
          'description': 'Reached target weight',
          'iconName': 'emoji_events',
          'isUnlocked': goalWeightKg > 0 && currentWeight > 0 && currentWeight <= goalWeightKg,
        },
      ];
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildWeightView(),
                _buildMeasurementsView(),
                _buildNutritionView(),
                _buildActivityView(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text('Progress Tracking'),
      leading: IconButton(
        icon: CustomIconWidget(
          iconName: 'arrow_back',
          color: AppTheme.textPrimaryLight,
          size: 24,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: CustomIconWidget(
            iconName: 'share',
            color: AppTheme.textPrimaryLight,
            size: 24,
          ),
          onPressed: _shareProgress,
        ),
        IconButton(
          icon: CustomIconWidget(
            iconName: 'more_vert',
            color: AppTheme.textPrimaryLight,
            size: 24,
          ),
          onPressed: _showMoreOptions,
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.lightTheme.colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        tabs: [
          Tab(text: 'Weight'),
          Tab(text: 'Measurements'),
          Tab(text: 'Nutrition'),
          Tab(text: 'Activity'),
        ],
      ),
    );
  }

  Widget _buildWeightView() {
    if (_loadingWeight) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasData = _weightData.isNotEmpty;
    final trendText = _weightChange == 0
        ? 'No change'
        : '${_weightChange > 0 ? '+' : ''}${_weightChange.toStringAsFixed(1)} kg';
    final isLoss = _weightChange < 0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          StatsCardWidget(
            title: 'Current Weight',
            value: _currentWeight > 0
                ? _currentWeight.toStringAsFixed(1)
                : '—',
            unit: 'kg',
            trend: hasData ? trendText : 'No check-ins yet',
            isPositiveTrend: isLoss, // losing weight is positive
          ),
          SizedBox(height: 2.h),
          if (!hasData)
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.bar_chart_rounded,
                      size: 48,
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant),
                  SizedBox(height: 2.h),
                  Text(
                    'No check-ins yet',
                    style: AppTheme.lightTheme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Submit a Weekly Check-in to start tracking your weight progress.',
                    textAlign: TextAlign.center,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/weekly-checkin'),
                    child: const Text('Submit Check-in'),
                  ),
                ],
              ),
            )
          else ...[
            TimePeriodSelectorWidget(
              periods: ['1W', '1M', '3M', '1Y'],
              selectedPeriod: _selectedPeriod,
              onPeriodSelected: (period) {
                setState(() {
                  _selectedPeriod = period;
                });
              },
            ),
            SizedBox(height: 2.h),
            ProgressChartWidget(
              chartData: _weightData,
              chartType: 'line',
              yAxisLabel: 'Weight Progress (kg)',
              primaryColor: AppTheme.primaryLight,
            ),
          ],
          SizedBox(height: 2.h),
          PhotoComparisonWidget(
            beforeImageUrl: '',
            afterImageUrl: '',
            onAddPhoto: _addProgressPhoto,
          ),
          SizedBox(height: 2.h),
          _buildAchievementsSection(),
        ],
      ),
    );
  }

  Widget _buildMeasurementsView() {
    if (_loadingMeasurements) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_measurementData.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.straighten_rounded, size: 48,
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant),
              SizedBox(height: 2.h),
              Text('No measurements yet',
                  style: AppTheme.lightTheme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              SizedBox(height: 1.h),
              Text('Log your body measurements to start tracking changes.',
                  textAlign: TextAlign.center,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant)),
              SizedBox(height: 2.h),
              ElevatedButton(
                onPressed: () => _showQuickEntryBottomSheet('measurement'),
                child: const Text('Log Measurements'),
              ),
            ],
          ),
        ),
      );
    }
    final waist = _measurementData.firstWhere(
        (m) => m['bodyPart'] == 'Waist', orElse: () => {});
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          StatsCardWidget(
            title: 'Waist Measurement',
            value: waist.isNotEmpty ? waist['measurement'] as String : '—',
            unit: 'cm',
            trend: waist.isNotEmpty && (waist['change'] as String).isNotEmpty
                ? waist['change'] as String
                : 'First entry',
            isPositiveTrend: waist.isNotEmpty
                ? waist['isPositiveChange'] as bool
                : true,
          ),
          SizedBox(height: 2.h),
          ..._measurementData.map((measurement) {
            return MeasurementCardWidget(
              bodyPart: measurement['bodyPart'] as String,
              measurement: measurement['measurement'] as String,
              unit: measurement['unit'] as String,
              change: measurement['change'] as String,
              isPositiveChange: measurement['isPositiveChange'] as bool,
              onTap: () => _showQuickEntryBottomSheet('measurement'),
            );
          }).toList(),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showQuickEntryBottomSheet('measurement'),
              icon: const Icon(Icons.add),
              label: const Text('Update Measurements'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionView() {
    if (_loadingNutrition) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_nutritionData.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pie_chart_outline_rounded, size: 48,
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant),
              SizedBox(height: 2.h),
              Text('No active diet plan',
                  style: AppTheme.lightTheme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              SizedBox(height: 1.h),
              Text('Nutrition data is derived from your assigned diet plan.',
                  textAlign: TextAlign.center,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          StatsCardWidget(
            title: 'Daily Calories (Plan)',
            value: _dailyCaloriesFromPlan > 0
                ? _dailyCaloriesFromPlan.toString()
                : '—',
            unit: 'kcal',
            trend: 'From today\'s plan',
            isPositiveTrend: true,
          ),
          SizedBox(height: 2.h),
          ProgressChartWidget(
            chartData: _nutritionData,
            chartType: 'pie',
            yAxisLabel: 'Macro Distribution',
            primaryColor: AppTheme.secondaryLight,
          ),
          SizedBox(height: 2.h),
          _buildNutritionSummary(),
        ],
      ),
    );
  }

  Widget _buildActivityView() {
    if (_loadingActivity) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          StatsCardWidget(
            title: 'Today\'s Steps',
            value: _todaySteps > 0 ? _todaySteps.toString() : '0',
            unit: 'steps',
            trend: '${_todayDistanceKm.toStringAsFixed(2)} km walked',
            isPositiveTrend: _todaySteps > 0,
          ),
          SizedBox(height: 2.h),
          _buildActivityCards(),
          SizedBox(height: 2.h),
          ProgressChartWidget(
            chartData: _weeklyStepData.isNotEmpty
                ? _weeklyStepData
                : List.generate(7, (i) => {'label': 'Day ${i + 1}', 'value': 0}),
            chartType: 'line',
            yAxisLabel: 'Weekly Steps',
            primaryColor: AppTheme.warningLight,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(3.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Achievements',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _achievementData.map((achievement) {
              return AchievementBadgeWidget(
                title: achievement['title'] as String,
                description: achievement['description'] as String,
                iconName: achievement['iconName'] as String,
                isUnlocked: achievement['isUnlocked'] as bool,
                onTap: () => _showAchievementDetails(achievement),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionSummary() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(3.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nutrition Summary',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          ..._nutritionData.map((nutrition) {
            return Padding(
              padding: EdgeInsets.only(bottom: 1.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    nutrition['label'] as String,
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                  Text(
                    '${nutrition['percentage']}%',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildActivityCards() {
    final activityData = [
      {
        'title': 'Calories Burned',
        'value': _todayCaloriesBurned.toString(),
        'unit': 'kcal',
        'icon': 'local_fire_department',
        'color': AppTheme.errorLight,
      },
      {
        'title': 'Active Minutes',
        'value': _todayActiveMinutes.toString(),
        'unit': 'min',
        'icon': 'timer',
        'color': AppTheme.warningLight,
      },
      {
        'title': 'Distance',
        'value': _todayDistanceKm.toStringAsFixed(2),
        'unit': 'km',
        'icon': 'directions_walk',
        'color': AppTheme.successLight,
      },
    ];

    return Row(
      children: activityData.map((activity) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 1.w),
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(2.w),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 10.w,
                  height: 10.w,
                  decoration: BoxDecoration(
                    color: (activity['color'] as Color).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: activity['icon'] as String,
                      color: activity['color'] as Color,
                      size: 20,
                    ),
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  '${activity['value']} ${activity['unit']}',
                  style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  activity['title'] as String,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentBottomNavIndex,
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'home',
            color: _currentBottomNavIndex == 0
                ? AppTheme.primaryLight
                : AppTheme.textSecondaryLight,
            size: 24,
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'trending_up',
            color: _currentBottomNavIndex == 1
                ? AppTheme.primaryLight
                : AppTheme.textSecondaryLight,
            size: 24,
          ),
          label: 'Progress',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'restaurant',
            color: _currentBottomNavIndex == 2
                ? AppTheme.primaryLight
                : AppTheme.textSecondaryLight,
            size: 24,
          ),
          label: 'Meals',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'chat',
            color: _currentBottomNavIndex == 3
                ? AppTheme.primaryLight
                : AppTheme.textSecondaryLight,
            size: 24,
          ),
          label: 'Chat',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'person',
            color: _currentBottomNavIndex == 4
                ? AppTheme.primaryLight
                : AppTheme.textSecondaryLight,
            size: 24,
          ),
          label: 'Profile',
        ),
      ],
      onTap: (index) {
        setState(() {
          _currentBottomNavIndex = index;
        });
        _navigateToTab(index);
      },
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _showQuickEntryOptions,
      child: CustomIconWidget(
        iconName: 'add',
        color: AppTheme.onSecondaryLight,
        size: 24,
      ),
    );
  }

  void _navigateToTab(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/dashboard-home');
        break;
      case 1:
        // Already on progress tracking
        break;
      case 2:
        // Navigate to meals (not implemented)
        break;
      case 3:
        // Navigate to chat (not implemented)
        break;
      case 4:
        Navigator.pushNamed(context, '/settings-profile');
        break;
    }
  }

  void _showQuickEntryOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(6.w),
            topRight: Radius.circular(6.w),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Quick Entry',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 3.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickEntryOption('Weight', 'monitor_weight', 'weight'),
                _buildQuickEntryOption(
                    'Measurements', 'straighten', 'measurement'),
                _buildQuickEntryOption(
                    'Activity', 'directions_run', 'activity'),
              ],
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickEntryOption(String title, String iconName, String type) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _showQuickEntryBottomSheet(type);
      },
      child: Column(
        children: [
          Container(
            width: 15.w,
            height: 15.w,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: iconName,
                color: AppTheme.primaryLight,
                size: 28,
              ),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            title,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textPrimaryLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickEntryBottomSheet(String entryType) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => QuickEntryBottomSheet(
        entryType: entryType,
        onSave: (data) {
          // Handle saving the entry data
          _saveEntryData(data);
        },
      ),
    );
  }

  Future<void> _saveEntryData(Map<String, dynamic> data) async {
    final uid = FirebaseService.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final type = data['type'] as String;
      if (type == 'measurement') {
        // Save to measurements subcollection
        await FirebaseService.instance.clients
            .doc(uid)
            .collection('measurements')
            .add({
          'waist':  (data['waist']  as num?)?.toDouble() ?? 0,
          'chest':  (data['chest']  as num?)?.toDouble() ?? 0,
          'arms':   (data['arms']   as num?)?.toDouble() ?? 0,
          'thighs': (data['thighs'] as num?)?.toDouble() ?? 0,
          'unit': 'cm',
          'recordedAt': FieldValue.serverTimestamp(),
        });
        await _loadMeasurements(); // Refresh UI
      } else if (type == 'activity') {
        // Persist manual activity entry to dailyStats
        final todayKey = DateTime.now().toIso8601String().substring(0, 10);
        final steps = (data['steps'] as num?)?.toInt() ?? 0;
        final calories = (data['calories'] as num?)?.toInt() ?? 0;
        final duration = (data['duration'] as num?)?.toInt() ?? 0;
        await FirebaseService.instance.clients.doc(uid).set({
          'dailyStats': {
            todayKey: {
              if (steps > 0) 'stepCount': steps,
              if (calories > 0) 'caloriesBurned': calories,
              if (duration > 0) 'activeMinutes': duration,
            },
          },
        }, SetOptions(merge: true));
        await _loadActivityStats(); // Refresh UI
      } else if (type == 'weight') {
        // Weight entries go to weightHistory subcollection
        final kg = (data['weight'] as num?)?.toDouble() ?? 0;
        if (kg > 0) {
          await FirebaseService.instance.clients
              .doc(uid)
              .collection('weightHistory')
              .add({'weightKg': kg, 'recordedAt': FieldValue.serverTimestamp()});
          await FirebaseService.instance.clients
              .doc(uid)
              .set({'weightKg': kg}, SetOptions(merge: true));
          await _loadWeightData(); // Refresh chart
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$type entry saved!'),
            backgroundColor: AppTheme.successLight,
          ),
        );
      }
    } catch (e) {
      debugPrint('_saveEntryData error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save entry. Please try again.'),
            backgroundColor: AppTheme.errorLight,
          ),
        );
      }
    }
  }

  void _addProgressPhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Photo capture feature coming soon!'),
        backgroundColor: AppTheme.warningLight,
      ),
    );
  }

  void _editMeasurement(String bodyPart) {
    _showQuickEntryBottomSheet('measurement');
  }

  void _showAchievementDetails(Map<String, dynamic> achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(achievement['title'] as String),
        content: Text(achievement['description'] as String),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _shareProgress() {
    // Implement progress sharing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share progress feature coming soon!'),
        backgroundColor: AppTheme.primaryLight,
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(6.w),
            topRight: Radius.circular(6.w),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CustomIconWidget(
                iconName: 'file_download',
                color: AppTheme.textPrimaryLight,
                size: 24,
              ),
              title: Text('Export Data'),
              onTap: () {
                Navigator.pop(context);
                // Implement data export
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'settings',
                color: AppTheme.textPrimaryLight,
                size: 24,
              ),
              title: Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings-profile');
              },
            ),
          ],
        ),
      ),
    );
  }
}
