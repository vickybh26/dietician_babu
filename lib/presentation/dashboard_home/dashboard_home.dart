import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/consultation_reminder_widget.dart';
import './widgets/daily_calorie_progress_widget.dart';
import './widgets/meal_plan_preview_widget.dart';
import './widgets/motivational_message_widget.dart';
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
  bool _isLoading = false;

  // Mock data for dashboard
  final Map<String, dynamic> _userData = {
    "name": "Priya Sharma",
    "targetCalories": 1800,
    "consumedCalories": 1245,
    "targetWater": 2500,
    "currentWater": 1750,
    "targetSteps": 10000,
    "currentSteps": 7234,
    "distanceKm": 5.2,
  };

  final List<Map<String, dynamic>> _todayMeals = [
    {
      "id": 1,
      "name": "Oats with Berries",
      "type": "breakfast",
      "calories": 320,
      "time": "8:00 AM",
      "isLogged": true,
    },
    {
      "id": 2,
      "name": "Grilled Chicken Salad",
      "type": "lunch",
      "calories": 450,
      "time": "1:00 PM",
      "isLogged": true,
    },
    {
      "id": 3,
      "name": "Quinoa Bowl with Vegetables",
      "type": "dinner",
      "calories": 520,
      "time": "7:30 PM",
      "isLogged": false,
    },
  ];

  final Map<String, dynamic>? _upcomingConsultation = {
    "doctorName": "Anjali Mehta",
    "date": "Tomorrow",
    "time": "3:00 PM",
    "type": "video",
  };

  final List<Map<String, dynamic>> _motivationalMessages = [
    {
      "message":
          "Great job! You're 69% towards your daily calorie goal. Keep it up!",
      "type": "encouragement",
    },
    {
      "message":
          "Don't forget to drink more water. You're 750ml away from your goal.",
      "type": "info",
    },
    {
      "message":
          "Amazing progress on your steps today! Only 2,766 more to reach your goal.",
      "type": "success",
    },
  ];

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
                'Good Morning',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                _userData['name'] as String,
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
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'wb_sunny',
                      color: Colors.orange,
                      size: 16,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      '24°C',
                      style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 2.w),
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            SizedBox(height: 1.h),
            // Motivational Message
            if (_motivationalMessages.isNotEmpty)
              MotivationalMessageWidget(
                message: _motivationalMessages.first['message'] as String,
                messageType: _motivationalMessages.first['type'] as String,
                onDismiss: () => _dismissMessage(0),
              ),

            // Daily Calorie Progress
            DailyCalorieProgressWidget(
              consumedCalories: _userData['consumedCalories'] as int,
              targetCalories: _userData['targetCalories'] as int,
              onTap: _showCalorieDetails,
            ),

            // Water Intake Tracker
            WaterIntakeTrackerWidget(
              currentIntake: _userData['currentWater'] as int,
              targetIntake: _userData['targetWater'] as int,
              onAdd250ml: () => _addWater(250),
              onAdd500ml: () => _addWater(500),
            ),

            // Today's Meal Plan
            MealPlanPreviewWidget(
              todayMeals: _todayMeals,
              onLogMeal: _showMealLogging,
            ),

            // Step Counter
            StepCounterWidget(
              currentSteps: _userData['currentSteps'] as int,
              targetSteps: _userData['targetSteps'] as int,
              distanceKm: _userData['distanceKm'] as double,
            ),

            // Consultation Reminder
            ConsultationReminderWidget(
              upcomingConsultation: _upcomingConsultation,
              onViewDetails: _viewConsultationDetails,
              onScheduleNew: _scheduleNewConsultation,
            ),

            SizedBox(height: 10.h), // Bottom padding for FAB
          ],
        ),
      ),
    );
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
            iconName: 'restaurant_menu',
            color: _currentIndex == 1
                ? AppTheme.lightTheme.colorScheme.primary
                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Meals',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'trending_up',
            color: _currentIndex == 2
                ? AppTheme.lightTheme.colorScheme.primary
                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Progress',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'chat',
            color: _currentIndex == 3
                ? AppTheme.lightTheme.colorScheme.primary
                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Chat',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'person',
            color: _currentIndex == 4
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

  // Event handlers
  Future<void> _handleRefresh() async {
    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _isLoading = false);
  }

  void _onBottomNavTap(int index) {
    setState(() => _currentIndex = index);

    // Navigate to different screens based on index
    switch (index) {
      case 0:
        // Already on home
        break;
      case 1:
        // Navigate to meals screen
        break;
      case 2:
        Navigator.pushNamed(context, '/progress-tracking');
        break;
      case 3:
        // Navigate to chat screen
        break;
      case 4:
        Navigator.pushNamed(context, '/settings-profile');
        break;
    }
  }

  void _dismissMessage(int index) {
    setState(() {
      if (index < _motivationalMessages.length) {
        _motivationalMessages.removeAt(index);
      }
    });
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
    setState(() {
      final currentWater = _userData['currentWater'] as int;
      final targetWater = _userData['targetWater'] as int;
      _userData['currentWater'] =
          (currentWater + amount).clamp(0, targetWater + 1000);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${amount}ml water!'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showMealLogging() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildMealLoggingBottomSheet(),
    );
  }

  void _viewConsultationDetails() {
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

  Widget _buildMealLoggingBottomSheet() {
    return Container(
      height: 60.h,
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
            'Log Your Meal',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          _buildQuickLogOption('Scan Barcode', 'qr_code_scanner', () {}),
          _buildQuickLogOption('Search Food', 'search', () {}),
          _buildQuickLogOption('Take Photo', 'camera_alt', () {}),
          _buildQuickLogOption('Voice Input', 'mic', () {}),
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
                  child: _buildQuickLogOption('Log Meal', 'restaurant', () {})),
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
                      'Log Weight', 'monitor_weight', () {})),
              SizedBox(width: 2.w),
              Expanded(
                  child: _buildQuickLogOption(
                      'Add Exercise', 'fitness_center', () {})),
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
              'Date', _upcomingConsultation['date'] as String),
          _buildConsultationDetailRow(
              'Time', _upcomingConsultation['time'] as String),
          _buildConsultationDetailRow('Type', 'Video Call'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Joining consultation...')),
            );
          },
          child: Text('Join Call'),
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
