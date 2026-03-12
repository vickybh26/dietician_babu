import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class GoalSelectionWidget extends StatelessWidget {
  final String selectedGoal;
  final Function(String) onGoalSelected;

  const GoalSelectionWidget({
    Key? key,
    required this.selectedGoal,
    required this.onGoalSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> goals = [
      {
        'id': 'weight_loss',
        'title': 'Weight Loss',
        'description': 'Lose weight in a healthy and sustainable way',
        'icon': 'trending_down',
        'color': AppTheme.lightTheme.colorScheme.error,
      },
      {
        'id': 'muscle_gain',
        'title': 'Muscle Gain',
        'description': 'Build lean muscle mass and strength',
        'icon': 'fitness_center',
        'color': AppTheme.lightTheme.colorScheme.secondary,
      },
      {
        'id': 'maintenance',
        'title': 'Maintenance',
        'description': 'Maintain current weight and improve health',
        'icon': 'balance',
        'color': AppTheme.lightTheme.colorScheme.primary,
      },
      {
        'id': 'general_health',
        'title': 'General Health',
        'description': 'Improve overall health and wellness',
        'icon': 'favorite',
        'color': AppTheme.lightTheme.colorScheme.tertiary,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What\'s your primary goal?',
          style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'This helps us create a personalized plan just for you',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 3.h),
        ...goals.map((goal) => _buildGoalCard(goal)).toList(),
      ],
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal) {
    final bool isSelected = selectedGoal == goal['id'];

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      child: InkWell(
        onTap: () => onGoalSelected(goal['id']),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: isSelected
                ? (goal['color'] as Color).withValues(alpha: 0.1)
                : AppTheme.lightTheme.colorScheme.surface,
            border: Border.all(
              color: isSelected
                  ? goal['color'] as Color
                  : AppTheme.lightTheme.dividerColor,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: (goal['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: goal['icon'],
                  color: goal['color'] as Color,
                  size: 6.w,
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal['title'],
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      goal['description'],
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                CustomIconWidget(
                  iconName: 'check_circle',
                  color: goal['color'] as Color,
                  size: 6.w,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
