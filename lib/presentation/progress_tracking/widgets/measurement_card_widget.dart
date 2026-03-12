import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MeasurementCardWidget extends StatelessWidget {
  final String bodyPart;
  final String measurement;
  final String unit;
  final String change;
  final bool isPositiveChange;
  final VoidCallback onTap;

  const MeasurementCardWidget({
    Key? key,
    required this.bodyPart,
    required this.measurement,
    required this.unit,
    required this.change,
    required this.isPositiveChange,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(4.w),
        margin: EdgeInsets.only(bottom: 2.h),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(3.w),
          border: Border.all(
            color: AppTheme.dividerLight,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2.w),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: _getBodyPartIcon(bodyPart),
                  color: AppTheme.primaryLight,
                  size: 24,
                ),
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bodyPart,
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    children: [
                      Text(
                        '$measurement $unit',
                        style:
                            AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 2.w, vertical: 0.3.h),
                        decoration: BoxDecoration(
                          color: isPositiveChange
                              ? AppTheme.successLight.withValues(alpha: 0.1)
                              : AppTheme.errorLight.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(1.w),
                        ),
                        child: Text(
                          change,
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: isPositiveChange
                                ? AppTheme.successLight
                                : AppTheme.errorLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            CustomIconWidget(
              iconName: 'chevron_right',
              color: AppTheme.textSecondaryLight,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _getBodyPartIcon(String bodyPart) {
    switch (bodyPart.toLowerCase()) {
      case 'waist':
        return 'straighten';
      case 'chest':
        return 'favorite';
      case 'arms':
        return 'fitness_center';
      case 'thighs':
        return 'directions_walk';
      case 'hips':
        return 'accessibility';
      default:
        return 'straighten';
    }
  }
}
