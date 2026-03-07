import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/firebase_service.dart';
import './widgets/language_selector_widget.dart';
import './widgets/notification_settings_widget.dart';
import './widgets/profile_header_widget.dart';
import './widgets/settings_section_widget.dart';
import './widgets/theme_selector_widget.dart';

class SettingsProfile extends StatefulWidget {
  const SettingsProfile({Key? key}) : super(key: key);

  @override
  State<SettingsProfile> createState() => _SettingsProfileState();
}

class _SettingsProfileState extends State<SettingsProfile> {
  // Mock user data
  final Map<String, dynamic> userData = {
    "id": 1,
    "name": "Priya Sharma",
    "email": "priya.sharma@email.com",
    "phone": "+91 98765 43210",
    "avatar":
        "https://images.unsplash.com/photo-1494790108755-2616b612b786?fm=jpg&q=60&w=400&ixlib=rb-4.0.3",
    "currentPlan": "Premium Plan",
    "joinDate": "2024-01-15",
    "daysActive": 45,
    "weightLost": 3.2,
    "currentStreak": 12,
  };

  // Settings state
  String selectedTheme = 'System';
  String selectedLanguage = 'en';
  bool biometricEnabled = true;
  bool offlineSyncEnabled = true;

  Map<String, bool> notificationSettings = {
    'meal_reminders': true,
    'water_alerts': true,
    'consultation_notifications': true,
    'progress_updates': false,
    'marketing_tips': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 2.h),

            // Profile Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: ProfileHeaderWidget(
                userName: userData["name"] as String,
                userEmail: userData["email"] as String,
                currentPlan: userData["currentPlan"] as String,
                avatarUrl: userData["avatar"] as String,
                onAvatarTap: _showAvatarOptions,
              ),
            ),

            SizedBox(height: 3.h),

            // Account Settings Section
            SettingsSectionWidget(
              title: 'Account',
              items: [
                SettingsItemData(
                  title: 'Personal Information',
                  subtitle: 'Edit your profile details',
                  iconName: 'person',
                  iconColor: AppTheme.lightTheme.primaryColor,
                  onTap: _editPersonalInfo,
                ),
                SettingsItemData(
                  title: 'Change Password',
                  subtitle: 'Update your account password',
                  iconName: 'lock',
                  iconColor: Colors.orange,
                  iconBackgroundColor: Colors.orange,
                  onTap: _changePassword,
                ),
                SettingsItemData(
                  title: 'Subscription Management',
                  subtitle: userData["currentPlan"] as String,
                  iconName: 'card_membership',
                  iconColor: Colors.purple,
                  iconBackgroundColor: Colors.purple,
                  onTap: _manageSubscription,
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Preferences Section
            SettingsSectionWidget(
              title: 'Preferences',
              items: [
                SettingsItemData(
                  title: 'Notifications',
                  subtitle: 'Manage your notification preferences',
                  iconName: 'notifications',
                  iconColor: Colors.blue,
                  iconBackgroundColor: Colors.blue,
                  onTap: _showNotificationSettings,
                ),
                SettingsItemData(
                  title: 'Language',
                  subtitle: selectedLanguage == 'en' ? 'English' : 'हिन्दी',
                  iconName: 'language',
                  iconColor: Colors.green,
                  iconBackgroundColor: Colors.green,
                  onTap: _showLanguageSelector,
                ),
                SettingsItemData(
                  title: 'Theme',
                  subtitle: selectedTheme,
                  iconName: 'palette',
                  iconColor: Colors.indigo,
                  iconBackgroundColor: Colors.indigo,
                  onTap: _showThemeSelector,
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Health Data Section
            SettingsSectionWidget(
              title: 'Health Data',
              items: [
                SettingsItemData(
                  title: 'Health App Integration',
                  subtitle: 'Connect with Google Fit / Apple Health',
                  iconName: 'favorite',
                  iconColor: Colors.red,
                  iconBackgroundColor: Colors.red,
                  onTap: _manageHealthIntegration,
                ),
                SettingsItemData(
                  title: 'Export Data',
                  subtitle: 'Download your health data',
                  iconName: 'download',
                  iconColor: Colors.teal,
                  iconBackgroundColor: Colors.teal,
                  onTap: _exportData,
                ),
                SettingsItemData(
                  title: 'Privacy Controls',
                  subtitle: 'Manage data sharing preferences',
                  iconName: 'privacy_tip',
                  iconColor: Colors.amber,
                  iconBackgroundColor: Colors.amber,
                  onTap: _managePrivacy,
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // App Settings Section
            SettingsSectionWidget(
              title: 'App Settings',
              items: [
                SettingsItemData(
                  title: 'Biometric Authentication',
                  subtitle: biometricEnabled ? 'Enabled' : 'Disabled',
                  iconName: 'fingerprint',
                  iconColor: Colors.deepPurple,
                  iconBackgroundColor: Colors.deepPurple,
                  trailing: Switch(
                    value: biometricEnabled,
                    onChanged: _toggleBiometric,
                    activeColor: AppTheme.lightTheme.primaryColor,
                  ),
                ),
                SettingsItemData(
                  title: 'Offline Sync',
                  subtitle: offlineSyncEnabled
                      ? 'Auto sync when online'
                      : 'Manual sync only',
                  iconName: 'sync',
                  iconColor: Colors.cyan,
                  iconBackgroundColor: Colors.cyan,
                  trailing: Switch(
                    value: offlineSyncEnabled,
                    onChanged: _toggleOfflineSync,
                    activeColor: AppTheme.lightTheme.primaryColor,
                  ),
                ),
                SettingsItemData(
                  title: 'Storage & Cache',
                  subtitle: 'Manage app storage (245 MB used)',
                  iconName: 'storage',
                  iconColor: Colors.brown,
                  iconBackgroundColor: Colors.brown,
                  onTap: _manageStorage,
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Support Section
            SettingsSectionWidget(
              title: 'Support',
              items: [
                SettingsItemData(
                  title: 'Help & FAQ',
                  subtitle: 'Get answers to common questions',
                  iconName: 'help',
                  iconColor: Colors.lightBlue,
                  iconBackgroundColor: Colors.lightBlue,
                  onTap: _showHelp,
                ),
                SettingsItemData(
                  title: 'Contact Support',
                  subtitle: 'Chat with our support team',
                  iconName: 'support_agent',
                  iconColor: Colors.lightGreen,
                  iconBackgroundColor: Colors.lightGreen,
                  onTap: _contactSupport,
                ),
                SettingsItemData(
                  title: 'Send Feedback',
                  subtitle: 'Help us improve the app',
                  iconName: 'feedback',
                  iconColor: Colors.pink,
                  iconBackgroundColor: Colors.pink,
                  onTap: _sendFeedback,
                ),
              ],
            ),

            SizedBox(height: 3.h),

            // Logout and Delete Account
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: CustomIconWidget(
                        iconName: 'logout',
                        color: Colors.white,
                        size: 20,
                      ),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.lightTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2.w),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: _deleteAccount,
                      icon: CustomIconWidget(
                        iconName: 'delete_forever',
                        color: Colors.red,
                        size: 20,
                      ),
                      label: const Text('Delete Account'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2.w),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: CustomIconWidget(
          iconName: 'arrow_back',
          color: AppTheme.lightTheme.colorScheme.onSurface,
          size: 24,
        ),
      ),
      title: Text(
        'Settings',
        style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: _showAppInfo,
          icon: CustomIconWidget(
            iconName: 'info',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 24,
          ),
        ),
      ],
    );
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4.w)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.dividerColor,
                borderRadius: BorderRadius.circular(1.w),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Change Profile Picture',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'camera_alt',
                color: AppTheme.lightTheme.primaryColor,
                size: 24,
              ),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'photo_library',
                color: AppTheme.lightTheme.primaryColor,
                size: 24,
              ),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _chooseFromGallery();
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  void _takePhoto() {
    // Implement camera functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Camera functionality will be implemented')),
    );
  }

  void _chooseFromGallery() {
    // Implement gallery selection
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gallery selection will be implemented')),
    );
  }

  void _editPersonalInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Personal Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: userData["name"] as String,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            SizedBox(height: 2.h),
            TextFormField(
              initialValue: userData["email"] as String,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            SizedBox(height: 2.h),
            TextFormField(
              initialValue: userData["phone"] as String,
              decoration: const InputDecoration(
                labelText: 'Phone',
                prefixIcon: Icon(Icons.phone),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated successfully')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            SizedBox(height: 2.h),
            TextFormField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            SizedBox(height: 2.h),
            TextFormField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password changed successfully')),
              );
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _manageSubscription() {
    Navigator.pushNamed(context, '/subscription-management');
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4.w)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            children: [
              Container(
                width: 12.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.dividerColor,
                  borderRadius: BorderRadius.circular(1.w),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Notification Settings',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.h),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: NotificationSettingsWidget(
                    notificationSettings: notificationSettings,
                    onSettingChanged: (key, value) {
                      setState(() {
                        notificationSettings[key] = value;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4.w)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.dividerColor,
                borderRadius: BorderRadius.circular(1.w),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Select Language',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            LanguageSelectorWidget(
              currentLanguage: selectedLanguage,
              onLanguageChanged: (language) {
                setState(() {
                  selectedLanguage = language;
                });
                Navigator.pop(context);
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  void _showThemeSelector() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4.w)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.dividerColor,
                borderRadius: BorderRadius.circular(1.w),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Theme Selection',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            ThemeSelectorWidget(
              currentTheme: selectedTheme,
              onThemeChanged: (theme) {
                setState(() {
                  selectedTheme = theme;
                });
                Navigator.pop(context);
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  void _manageHealthIntegration() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Health App Integration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Connect with health apps to sync your data:'),
            SizedBox(height: 2.h),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'favorite',
                color: Colors.red,
                size: 24,
              ),
              title: const Text('Google Fit'),
              subtitle: const Text('Connected'),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
                activeColor: AppTheme.lightTheme.primaryColor,
              ),
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'favorite',
                color: Colors.blue,
                size: 24,
              ),
              title: const Text('Apple Health'),
              subtitle: const Text('Not connected'),
              trailing: Switch(
                value: false,
                onChanged: (value) {},
                activeColor: AppTheme.lightTheme.primaryColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Health Data'),
        content: const Text(
          'Your health data will be exported as a CSV file. This includes your meal logs, weight tracking, and progress data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Data export started. You will receive an email shortly.')),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _managePrivacy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Controls'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Share anonymized data'),
              subtitle: const Text('Help improve our services'),
              trailing: Switch(
                value: false,
                onChanged: (value) {},
                activeColor: AppTheme.lightTheme.primaryColor,
              ),
            ),
            ListTile(
              title: const Text('Marketing communications'),
              subtitle: const Text('Receive health tips and offers'),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
                activeColor: AppTheme.lightTheme.primaryColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _toggleBiometric(bool value) {
    setState(() {
      biometricEnabled = value;
    });

    if (value) {
      // Simulate biometric setup
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric authentication enabled')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric authentication disabled')),
      );
    }
  }

  void _toggleOfflineSync(bool value) {
    setState(() {
      offlineSyncEnabled = value;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value
            ? 'Offline sync enabled - Data will sync automatically'
            : 'Offline sync disabled - Manual sync required'),
      ),
    );
  }

  void _manageStorage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage & Cache'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Storage Usage:'),
            SizedBox(height: 1.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('App Data'),
                const Text('180 MB'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Cache'),
                const Text('65 MB'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total'),
                Text('245 MB', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cache cleared successfully')),
                  );
                },
                child: const Text('Clear Cache'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    Navigator.pushNamed(context, '/help-faq');
  }

  void _contactSupport() {
    Navigator.pushNamed(context, '/support-chat');
  }

  void _sendFeedback() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Your feedback',
                hintText: 'Tell us what you think about the app...',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                const Text('Rate the app: '),
                ...List.generate(
                  5,
                  (index) => GestureDetector(
                    onTap: () {},
                    child: CustomIconWidget(
                      iconName: 'star',
                      color: index < 4 ? Colors.amber : Colors.grey,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thank you for your feedback!')),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
            'Are you sure you want to logout? Your data will be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseService().signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login-screen',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted. You have 30 days to recover your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showBiometricVerification(() {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Account deletion initiated. Check your email for confirmation.'),
                    backgroundColor: Colors.red,
                  ),
                );
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showBiometricVerification(VoidCallback onSuccess) {
    if (!biometricEnabled) {
      onSuccess();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Biometric Verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: 'fingerprint',
              color: AppTheme.lightTheme.primaryColor,
              size: 64,
            ),
            SizedBox(height: 2.h),
            const Text('Please verify your identity to continue'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Simulate successful verification
              HapticFeedback.lightImpact();
              onSuccess();
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  void _showAppInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dietician Babu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Version: 1.2.3'),
            const Text('Build: 2024.09.06'),
            SizedBox(height: 2.h),
            const Text('Your personalized diet coaching companion'),
            SizedBox(height: 2.h),
            Row(
              children: [
                TextButton(
                  onPressed: () {},
                  child: const Text('Privacy Policy'),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Terms of Service'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
