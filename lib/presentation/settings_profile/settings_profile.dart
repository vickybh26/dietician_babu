import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/firebase_service.dart';
import './widgets/notification_settings_widget.dart';
import './widgets/profile_header_widget.dart';
import './widgets/settings_section_widget.dart';

class SettingsProfile extends StatefulWidget {
  const SettingsProfile({Key? key}) : super(key: key);

  @override
  State<SettingsProfile> createState() => _SettingsProfileState();
}

class _SettingsProfileState extends State<SettingsProfile> {
  // Real user data from Firebase
  String _userName = '';
  String _userEmail = '';
  String _userPhone = '';
  String _currentPlan = 'No active plan';
  bool _isLoading = true;

  // Computed profile stats from Firebase
  int _daysActive = 0;
  double _weightLost = 0.0;
  int _totalCheckIns = 0;

  // Settings state
  bool offlineSyncEnabled = true;

  Map<String, bool> notificationSettings = {
    'meal_reminders': true,
    'water_alerts': true,
    'consultation_notifications': true,
    'progress_updates': false,
    'marketing_tips': false,
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseService.instance.currentUser;
    if (user == null) return;
    try {
      // Fetch user doc, client doc and weekly check-ins in parallel
      final results = await Future.wait([
        FirebaseService.instance.users.doc(user.uid).get(),
        FirebaseService.instance.clients.doc(user.uid).get(),
        FirebaseService.instance.weeklyUpdates
            .where('clientId', isEqualTo: user.uid)
            .orderBy('submittedAt')
            .get(),
      ]);

      final userSnap = results[0] as DocumentSnapshot<Map<String, dynamic>>;
      final clientSnap = results[1] as DocumentSnapshot<Map<String, dynamic>>;
      final checkInsSnap = results[2] as QuerySnapshot<Map<String, dynamic>>;

      if (mounted) {
        // ─── Profile fields ────────────────────────────────────────────────
        final name = userSnap.data()?['name'] as String? ??
            user.displayName ??
            user.email?.split('@').first ??
            'User';
        final email = userSnap.data()?['email'] as String? ?? user.email ?? '';
        final phone = userSnap.data()?['phone'] as String? ?? '';

        // ─── Plan ─────────────────────────────────────────────────────────
        String plan = 'No active plan';
        if (clientSnap.exists) {
          final planName =
              clientSnap.data()?['subscriptionPlan'] as String? ?? '';
          final status =
              clientSnap.data()?['subscriptionStatus'] as String? ?? '';
          if (planName.isNotEmpty && status == 'active') {
            plan = '$planName Plan — Active';
          }
        }

        // ─── Days active ──────────────────────────────────────────────────
        int daysActive = 0;
        final createdAt =
            userSnap.data()?['createdAt'] as Timestamp?;
        if (createdAt != null) {
          daysActive =
              DateTime.now().difference(createdAt.toDate()).inDays;
        }

        // ─── Weight lost (startingWeightKg − currentWeightKg) ─────────────
        double weightLost = 0.0;
        if (clientSnap.exists) {
          final startKg =
              (clientSnap.data()?['startingWeightKg'] as num?)?.toDouble();
          final curKg =
              (clientSnap.data()?['weightKg'] as num?)?.toDouble();
          if (startKg != null && curKg != null && startKg > curKg) {
            weightLost = startKg - curKg;
          }
        }

        // ─── Total check-ins ──────────────────────────────────────────────
        final totalCheckIns = checkInsSnap.docs.length;

        setState(() {
          _userName = name;
          _userEmail = email;
          _userPhone = phone;
          _currentPlan = plan;
          _daysActive = daysActive;
          _weightLost = weightLost;
          _totalCheckIns = totalCheckIns;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('_loadUserData error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
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
                userName: _userName,
                userEmail: _userEmail,
                currentPlan: _currentPlan,
                avatarUrl: '',
                onAvatarTap: _showAvatarOptions,
                daysActive: _daysActive,
                weightLost: _weightLost,
                totalCheckIns: _totalCheckIns,
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
                  subtitle: _currentPlan,
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
                  subtitle: 'Clear cached images and data',
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
    final nameCtrl = TextEditingController(text: _userName);
    final phoneCtrl = TextEditingController(text: _userPhone);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Personal Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            SizedBox(height: 2.h),
            TextFormField(
              initialValue: _userEmail,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Email (cannot be changed)',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            SizedBox(height: 2.h),
            TextFormField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
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
            onPressed: () async {
              final newName = nameCtrl.text.trim();
              final newPhone = phoneCtrl.text.trim();
              Navigator.pop(context);
              try {
                final uid = FirebaseService.instance.currentUser?.uid;
                if (uid != null) {
                  await FirebaseService.instance.users.doc(uid).update({
                    if (newName.isNotEmpty) 'name': newName,
                    if (newPhone.isNotEmpty) 'phone': newPhone,
                  });
                  await _loadUserData(); // refresh UI
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Update failed: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _changePassword() {
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: newPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password (min 6 chars)',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            SizedBox(height: 2.h),
            TextFormField(
              controller: confirmPassCtrl,
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
            onPressed: () async {
              final newPw = newPassCtrl.text;
              final confirmPw = confirmPassCtrl.text;
              if (newPw.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password must be at least 6 characters')),
                );
                return;
              }
              if (newPw != confirmPw) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }
              Navigator.pop(context);
              try {
                await FirebaseService.instance.currentUser
                    ?.updatePassword(newPw);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password changed successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e. Please re-login and try again.')),
                  );
                }
              }
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Help & FAQ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _faqItem('How do I update my diet plan?', 'Contact your dietician or use the Weekly Check-in to share your progress. Your plan will be updated by the admin.'),
            _faqItem('How do I track my progress?', 'Tap the Progress tab at the bottom. You can log weight and view your history after submitting Weekly Check-ins.'),
            _faqItem('How do I make a payment?', 'Go to Settings → Subscription Plans to view and purchase a plan using Razorpay.'),
            _faqItem('My name shows incorrectly — how to fix?', 'Go to Settings → Personal Information and update your name, then tap Save.'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _faqItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(answer, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Future<void> _contactSupport() async {
    const whatsapp = 'https://wa.me/918871448064?text=Hi%2C%20I%20need%20help%20with%20the%20Dietician%20Babu%20app';
    final uri = Uri.parse(whatsapp);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp. Please contact +91 88714 48064')),
        );
      }
    }
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
              await FirebaseService.instance.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/landing',
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Account deletion initiated. Check your email for confirmation.'),
                  backgroundColor: Colors.red,
                ),
              );
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

  void _showAppInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dietician Babu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Version: 1.3.0'),
            const Text('Build: 2026.03.08'),
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
