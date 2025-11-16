import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MotivationalMessageWidget extends StatelessWidget {
  final String message;
  final String messageType;
  final VoidCallback? onDismiss;

  const MotivationalMessageWidget({
    super.key,
    required this.message,
    required this.messageType,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = _getBackgroundColor();
    final Color textColor = _getTextColor();
    final String iconName = _getIconName();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: textColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: CustomIconWidget(
              iconName: iconName,
              color: textColor,
              size: 18,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              message,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onDismiss != null) ...[
            SizedBox(width: 2.w),
            GestureDetector(
              onTap: onDismiss,
              child: Container(
                padding: EdgeInsets.all(1.w),
                child: CustomIconWidget(
                  iconName: 'close',
                  color: textColor.withValues(alpha: 0.7),
                  size: 16,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (messageType.toLowerCase()) {
      case 'success':
        return AppTheme.lightTheme.colorScheme.tertiary.withValues(alpha: 0.1);
      case 'warning':
        return Colors.orange.withValues(alpha: 0.1);
      case 'info':
        return AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1);
      case 'encouragement':
        return Colors.purple.withValues(alpha: 0.1);
      default:
        return AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1);
    }
  }

  Color _getTextColor() {
    switch (messageType.toLowerCase()) {
      case 'success':
        return AppTheme.lightTheme.colorScheme.tertiary;
      case 'warning':
        return Colors.orange;
      case 'info':
        return AppTheme.lightTheme.colorScheme.primary;
      case 'encouragement':
        return Colors.purple;
      default:
        return AppTheme.lightTheme.colorScheme.primary;
    }
  }

  String _getIconName() {
    switch (messageType.toLowerCase()) {
      case 'success':
        return 'check_circle';
      case 'warning':
        return 'warning';
      case 'info':
        return 'info';
      case 'encouragement':
        return 'favorite';
      default:
        return 'lightbulb';
    }
  }
}
