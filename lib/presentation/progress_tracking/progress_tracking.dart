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

  // Weight data loaded from Firestore weeklyUpdates
  List<Map<String, dynamic>> _weightData = [];
  double _currentWeight = 0.0;
  double _weightChange = 0.0;
  bool _loadingWeight = true;

  final List<Map<String, dynamic>> _nutritionData = [
    {'label': 'Protein', 'value': 30, 'percentage': 30},
    {'label': 'Carbs', 'value': 45, 'percentage': 45},
    {'label': 'Fats', 'value': 20, 'percentage': 20},
    {'label': 'Fiber', 'value': 5, 'percentage': 5},
  ];

  final List<Map<String, dynamic>> _measurementData = [
    {
      'bodyPart': 'Waist',
      'measurement': '82.5',
      'unit': 'cm',
      'change': '-2.3 cm',
      'isPositiveChange': true,
    },
    {
      'bodyPart': 'Chest',
      'measurement': '98.2',
      'unit': 'cm',
      'change': '+1.5 cm',
      'isPositiveChange': true,
    },
    {
      'bodyPart': 'Arms',
      'measurement': '35.8',
      'unit': 'cm',
      'change': '+0.8 cm',
      'isPositiveChange': true,
    },
    {
      'bodyPart': 'Thighs',
      'measurement': '58.3',
      'unit': 'cm',
      'change': '-1.2 cm',
      'isPositiveChange': true,
    },
  ];

  final List<Map<String, dynamic>> _achievementData = [
    {
      'title': 'First Week',
      'description': 'Complete your first week',
      'iconName': 'star',
      'isUnlocked': true,
    },
    {
      'title': '5kg Lost',
      'description': 'Lost 5 kilograms',
      'iconName': 'trending_down',
      'isUnlocked': true,
    },
    {
      'title': 'Consistent',
      'description': '30 days streak',
      'iconName': 'local_fire_department',
      'isUnlocked': false,
    },
    {
      'title': 'Goal Reached',
      'description': 'Reached target weight',
      'iconName': 'emoji_events',
      'isUnlocked': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadWeightData();
  }

  Future<void> _loadWeightData() async {
    final uid = FirebaseService.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loadingWeight = false);
      return;
    }
    try {
      final snap = await FirebaseService.instance.weeklyUpdates
          .where('clientId', isEqualTo: uid)
          .orderBy('submittedAt')
          .get();

      if (snap.docs.isEmpty) {
        // Also try client doc for current weight
        final clientSnap =
            await FirebaseService.instance.clients.doc(uid).get();
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

      // Build chart data — use month+year as label for older entries,
      // or "Wk N" for recent entries (last 8)
      final docs = snap.docs;
      final chartDocs = docs.length > 8 ? docs.sublist(docs.length - 8) : docs;

      final chartData = chartDocs.map((doc) {
        final ts = doc.data()['submittedAt'] as Timestamp?;
        final w = (doc.data()['weightKg'] as num?)?.toDouble() ?? 0.0;
        String label;
        if (ts != null) {
          final d = ts.toDate();
          const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
              'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          label = '${months[d.month]} ${d.day}';
        } else {
          label = '—';
        }
        return {'label': label, 'value': w};
      }).toList();

      final firstWeight =
          (docs.first.data()['weightKg'] as num?)?.toDouble() ?? 0.0;
      final lastWeight =
          (docs.last.data()['weightKg'] as num?)?.toDouble() ?? 0.0;
      final change = firstWeight > 0 ? lastWeight - firstWeight : 0.0;

      if (mounted) {
        setState(() {
          _weightData = chartData;
          _currentWeight = lastWeight;
          _weightChange = change;
          _loadingWeight = false;
        });
      }
    } catch (e) {
      debugPrint('_loadWeightData error: $e');
      if (mounted) setState(() => _loadingWeight = false);
    }
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
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          StatsCardWidget(
            title: 'Waist Measurement',
            value: '82.5',
            unit: 'cm',
            trend: '-2.3 cm',
            isPositiveTrend: true,
          ),
          SizedBox(height: 2.h),
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
          ..._measurementData.map((measurement) {
            return MeasurementCardWidget(
              bodyPart: measurement['bodyPart'] as String,
              measurement: measurement['measurement'] as String,
              unit: measurement['unit'] as String,
              change: measurement['change'] as String,
              isPositiveChange: measurement['isPositiveChange'] as bool,
              onTap: () => _editMeasurement(measurement['bodyPart'] as String),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildNutritionView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          StatsCardWidget(
            title: 'Daily Calories',
            value: '1,850',
            unit: 'kcal',
            trend: '-150 kcal',
            isPositiveTrend: true,
          ),
          SizedBox(height: 2.h),
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
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          StatsCardWidget(
            title: 'Daily Steps',
            value: '8,542',
            unit: 'steps',
            trend: '+1,200',
            isPositiveTrend: true,
          ),
          SizedBox(height: 2.h),
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
          _buildActivityCards(),
          SizedBox(height: 2.h),
          ProgressChartWidget(
            chartData: [
              {'label': 'Mon', 'value': 7500},
              {'label': 'Tue', 'value': 8200},
              {'label': 'Wed', 'value': 6800},
              {'label': 'Thu', 'value': 9100},
              {'label': 'Fri', 'value': 8500},
              {'label': 'Sat', 'value': 10200},
              {'label': 'Sun', 'value': 7800},
            ],
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
        'value': '420',
        'unit': 'kcal',
        'icon': 'local_fire_department',
        'color': AppTheme.errorLight,
      },
      {
        'title': 'Active Minutes',
        'value': '45',
        'unit': 'min',
        'icon': 'timer',
        'color': AppTheme.warningLight,
      },
      {
        'title': 'Distance',
        'value': '6.2',
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

  void _saveEntryData(Map<String, dynamic> data) {
    // Implement data saving logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${data['type']} entry saved successfully!'),
        backgroundColor: AppTheme.successLight,
      ),
    );
  }

  void _addProgressPhoto() {
    // Implement photo capture/selection
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Photo capture feature coming soon!'),
        backgroundColor: AppTheme.warningLight,
      ),
    );
  }

  void _editMeasurement(String bodyPart) {
    // Implement measurement editing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit $bodyPart measurement'),
        backgroundColor: AppTheme.primaryLight,
      ),
    );
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
