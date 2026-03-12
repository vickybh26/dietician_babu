import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class StatsCardWidget extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final String trend;
  final bool isPositiveTrend;
  final Color? backgroundColor;

  const StatsCardWidget({
    Key? key,
    required this.title,
    required this.value,
    required this.unit,
    required this.trend,
    required this.isPositiveTrend,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.lightTheme.colorScheme.surface,
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
            title,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: AppTheme.lightTheme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              SizedBox(width: 1.w),
              Padding(
                padding: EdgeInsets.only(bottom: 1.h),
                child: Text(
                  unit,
                  style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: isPositiveTrend
                      ? AppTheme.successLight.withValues(alpha: 0.1)
                      : AppTheme.errorLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2.w),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomIconWidget(
                      iconName:
                          isPositiveTrend ? 'trending_up' : 'trending_down',
                      color: isPositiveTrend
                          ? AppTheme.successLight
                          : AppTheme.errorLight,
                      size: 16,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      trend,
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: isPositiveTrend
                            ? AppTheme.successLight
                            : AppTheme.errorLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
