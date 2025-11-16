import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ActivityLevelWidget extends StatelessWidget {
  final double activityLevel;
  final Function(double) onActivityLevelChanged;

  const ActivityLevelWidget({
    Key? key,
    required this.activityLevel,
    required this.onActivityLevelChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> activityLevels = [
      {
        'value': 1.0,
        'title': 'Sedentary',
        'description': 'Little to no exercise',
        'icon': 'weekend',
      },
      {
        'value': 2.0,
        'title': 'Lightly Active',
        'description': 'Light exercise 1-3 days/week',
        'icon': 'directions_walk',
      },
      {
        'value': 3.0,
        'title': 'Moderately Active',
        'description': 'Moderate exercise 3-5 days/week',
        'icon': 'directions_run',
      },
      {
        'value': 4.0,
        'title': 'Very Active',
        'description': 'Hard exercise 6-7 days/week',
        'icon': 'fitness_center',
      },
      {
        'value': 5.0,
        'title': 'Extremely Active',
        'description': 'Very hard exercise, physical job',
        'icon': 'sports_gymnastics',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How active are you?',
          style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'This helps us calculate your daily calorie needs',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 4.h),
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.lightTheme.dividerColor,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Activity Level',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getActivityLevelTitle(activityLevel),
                      style:
                          AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 3.h),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppTheme.lightTheme.colorScheme.primary,
                  inactiveTrackColor: AppTheme.lightTheme.dividerColor,
                  thumbColor: AppTheme.lightTheme.colorScheme.primary,
                  overlayColor: AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.2),
                  trackHeight: 1.h,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 3.w),
                ),
                child: Slider(
                  value: activityLevel,
                  min: 1.0,
                  max: 5.0,
                  divisions: 4,
                  onChanged: onActivityLevelChanged,
                ),
              ),
              SizedBox(height: 2.h),
              _buildActivityDescription(activityLevel),
            ],
          ),
        ),
        SizedBox(height: 3.h),
        ...activityLevels
            .map((level) => _buildActivityLevelCard(level))
            .toList(),
      ],
    );
  }

  String _getActivityLevelTitle(double value) {
    switch (value.round()) {
      case 1:
        return 'Sedentary';
      case 2:
        return 'Lightly Active';
      case 3:
        return 'Moderately Active';
      case 4:
        return 'Very Active';
      case 5:
        return 'Extremely Active';
      default:
        return 'Sedentary';
    }
  }

  Widget _buildActivityDescription(double value) {
    String description;
    String icon;

    switch (value.round()) {
      case 1:
        description = 'Little to no exercise';
        icon = 'weekend';
        break;
      case 2:
        description = 'Light exercise 1-3 days/week';
        icon = 'directions_walk';
        break;
      case 3:
        description = 'Moderate exercise 3-5 days/week';
        icon = 'directions_run';
        break;
      case 4:
        description = 'Hard exercise 6-7 days/week';
        icon = 'fitness_center';
        break;
      case 5:
        description = 'Very hard exercise, physical job';
        icon = 'sports_gymnastics';
        break;
      default:
        description = 'Little to no exercise';
        icon = 'weekend';
    }

    return Row(
      children: [
        CustomIconWidget(
          iconName: icon,
          color: AppTheme.lightTheme.colorScheme.primary,
          size: 5.w,
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Text(
            description,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityLevelCard(Map<String, dynamic> level) {
    final bool isSelected =
        activityLevel.round() == (level['value'] as double).round();

    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      child: InkWell(
        onTap: () => onActivityLevelChanged(level['value']),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.05)
                : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? AppTheme.lightTheme.colorScheme.primary
                  : Colors.transparent,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              CustomIconWidget(
                iconName: level['icon'],
                color: isSelected
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 5.w,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level['title'],
                      style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? AppTheme.lightTheme.colorScheme.primary
                            : AppTheme.lightTheme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      level['description'],
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
