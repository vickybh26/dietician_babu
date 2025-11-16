import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class NotificationSettingsWidget extends StatefulWidget {
  final Map<String, bool> notificationSettings;
  final Function(String, bool) onSettingChanged;

  const NotificationSettingsWidget({
    Key? key,
    required this.notificationSettings,
    required this.onSettingChanged,
  }) : super(key: key);

  @override
  State<NotificationSettingsWidget> createState() =>
      _NotificationSettingsWidgetState();
}

class _NotificationSettingsWidgetState
    extends State<NotificationSettingsWidget> {
  late Map<String, bool> settings;

  @override
  void initState() {
    super.initState();
    settings = Map.from(widget.notificationSettings);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
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
        children: [
          _buildNotificationItem(
            'Meal Reminders',
            'Get reminded about your meals',
            'restaurant',
            'meal_reminders',
            Colors.orange,
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppTheme.lightTheme.dividerColor,
            indent: 4.w,
            endIndent: 4.w,
          ),
          _buildNotificationItem(
            'Water Alerts',
            'Stay hydrated with water reminders',
            'water_drop',
            'water_alerts',
            Colors.blue,
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppTheme.lightTheme.dividerColor,
            indent: 4.w,
            endIndent: 4.w,
          ),
          _buildNotificationItem(
            'Consultation Notifications',
            'Upcoming appointments and messages',
            'video_call',
            'consultation_notifications',
            Colors.green,
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppTheme.lightTheme.dividerColor,
            indent: 4.w,
            endIndent: 4.w,
          ),
          _buildNotificationItem(
            'Progress Updates',
            'Weekly progress and achievements',
            'trending_up',
            'progress_updates',
            Colors.purple,
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppTheme.lightTheme.dividerColor,
            indent: 4.w,
            endIndent: 4.w,
          ),
          _buildNotificationItem(
            'Marketing & Tips',
            'Health tips and promotional content',
            'lightbulb',
            'marketing_tips',
            Colors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    String title,
    String subtitle,
    String iconName,
    String settingKey,
    Color iconColor,
  ) {
    final isEnabled = settings[settingKey] ?? false;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
      leading: Container(
        width: 10.w,
        height: 10.w,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(2.w),
        ),
        child: Center(
          child: CustomIconWidget(
            iconName: iconName,
            color: iconColor,
            size: 20,
          ),
        ),
      ),
      title: Text(
        title,
        style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
          color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Switch(
        value: isEnabled,
        onChanged: (value) {
          setState(() {
            settings[settingKey] = value;
          });
          widget.onSettingChanged(settingKey, value);
        },
        activeColor: AppTheme.lightTheme.primaryColor,
      ),
    );
  }
}
