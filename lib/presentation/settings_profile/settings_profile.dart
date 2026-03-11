import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/firebase_service.dart';
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
  bool _shareAnonymizedData = false;
  bool _marketingComms = false;

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

        // ─── Load persisted preferences ────────────────────────────────────
        final prefs = userSnap.data()?['preferences'] as Map<String, dynamic>?;
        final savedNotifs = prefs?['notifications'] as Map<String, dynamic>?;
        setState(() {
          _userName = name;
          _userEmail = email;
          _userPhone = phone;
          _currentPlan = plan;
          _daysActive = daysActive;
          _weightLost = weightLost;
          _totalCheckIns = totalCheckIns;
          _isLoading = false;
          final prefs = userSnap.data()?['preferences'] as Map<String, dynamic>?;
          _shareAnonymizedData = (prefs?['shareAnonymizedData'] as bool?) ?? false;
          _marketingComms = (prefs?['marketingComms'] as bool?) ?? false;
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

            // Health Data Section
            SettingsSectionWidget(
              title: 'Privacy',
              items: [
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
    final uid = FirebaseService.instance.currentUser?.uid;
    if (uid == null) return;

    // Load full client + user data then show edit dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    Future.wait([
      FirebaseService.instance.users.doc(uid).get(),
      FirebaseService.instance.clients.doc(uid).get(),
    ]).then((results) {
      if (!mounted) return;
      Navigator.pop(context); // close loader

      final userD = results[0].data() as Map<String, dynamic>? ?? {};
      final clientD = results[1].data() as Map<String, dynamic>? ?? {};

      final nameCtrl = TextEditingController(text: userD['name'] as String? ?? _userName);
      final phoneCtrl = TextEditingController(text: userD['phone'] as String? ?? _userPhone);
      final cityCtrl = TextEditingController(text: userD['city'] as String? ?? '');
      final countryCtrl = TextEditingController(text: userD['country'] as String? ?? 'India');

      // Read-only onboarding fields
      final goal = clientD['goal'] as String? ?? '—';
      final gender = clientD['gender'] as String? ?? '—';
      final age = clientD['age']?.toString() ?? '—';
      final height = clientD['heightCm']?.toString() ?? '—';
      final weight = clientD['weightKg']?.toString() ?? '—';
      final conditions = (clientD['medicalConditions'] as List?)?.join(', ') ?? '—';
      final diet = (clientD['dietaryRestrictions'] as List?)?.join(', ') ?? '—';

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Personal Information'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('— Editable Fields —',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _userEmail,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Email (cannot be changed)',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: cityCtrl,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    prefixIcon: Icon(Icons.location_city),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: countryCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Country',
                    prefixIcon: Icon(Icons.flag),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('— Health Profile (from Onboarding) —',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                _infoRow(Icons.flag_outlined, 'Goal', goal),
                _infoRow(Icons.wc,            'Gender', gender),
                _infoRow(Icons.cake,          'Age', age),
                _infoRow(Icons.height,        'Height', height.isNotEmpty && height != '—' ? '$height cm' : '—'),
                _infoRow(Icons.monitor_weight,'Weight', weight.isNotEmpty && weight != '—' ? '$weight kg' : '—'),
                _infoRow(Icons.medical_services, 'Medical Conditions', conditions),
                _infoRow(Icons.restaurant,    'Dietary Restrictions', diet),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await FirebaseService.instance.users.doc(uid).update({
                    if (nameCtrl.text.trim().isNotEmpty) 'name': nameCtrl.text.trim(),
                    if (phoneCtrl.text.trim().isNotEmpty) 'phone': phoneCtrl.text.trim(),
                    'city': cityCtrl.text.trim(),
                    'country': countryCtrl.text.trim(),
                  });
                  await _loadUserData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated ✓')),
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
    }).catchError((e) {
      if (mounted) Navigator.pop(context);
    });
  }

  /// Small read-only detail row used in Personal Info dialog.
  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  void _changePassword() {
    // Use sendPasswordResetEmail — safer than updatePassword which requires
    // recent authentication and often fails with "requires-recent-login".
    final email = _userEmail.isNotEmpty
        ? _userEmail
        : FirebaseService.instance.currentUser?.email ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A password reset link will be sent to your registered email address.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              email,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirebaseService.instance
                    .sendPasswordReset(email);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Password reset email sent! Check your inbox.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e')),
                  );
                }
              }
            },
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  void _manageSubscription() {
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
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Subscription Management',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Current Plan: $_currentPlan',
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.pause_circle_outline),
                label: const Text('Request Pause'),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _sendSubscriptionRequest('pause');
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF61b239),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Request Resume'),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _sendSubscriptionRequest('resume');
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.upgrade),
                label: const Text('View / Upgrade Plans'),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/subscription-plans');
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _sendSubscriptionRequest(String type) async {
    final uid = FirebaseService.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseService.instance.db.collection('subscriptionRequests').add({
        'clientId': uid,
        'clientName': _userName,
        'clientEmail': _userEmail,
        'type': type, // 'pause' or 'resume'
        'currentPlan': _currentPlan,
        'requestedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Request to ${type == 'pause' ? 'pause' : 'resume'} subscription sent to your dietician ✓'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send request: $e')),
        );
      }
    }
  }

  void _managePrivacy() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
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
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Privacy Controls',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text(
                'Control how your data is used. Changes are saved immediately.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              _privacyToggle(
                setSheet: setSheet,
                title: 'Share anonymized data',
                subtitle: 'Help us improve diet recommendations for all users',
                value: _shareAnonymizedData,
                prefKey: 'shareAnonymizedData',
                onChanged: (v) => setState(() => _shareAnonymizedData = v),
              ),
              const Divider(),
              _privacyToggle(
                setSheet: setSheet,
                title: 'Marketing communications',
                subtitle: 'Receive health tips, offers, and app updates via email',
                value: _marketingComms,
                prefKey: 'marketingComms',
                onChanged: (v) => setState(() => _marketingComms = v),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your personal health data is never sold to third parties. '  
                'It is only shared with your assigned dietician.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _privacyToggle({
    required StateSetter setSheet,
    required String title,
    required String subtitle,
    required bool value,
    required String prefKey,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: (v) {
          setSheet(() {});
          onChanged(v);
          final uid = FirebaseService.instance.currentUser?.uid;
          if (uid != null) {
            FirebaseService.instance.users.doc(uid).set({
              'preferences': {prefKey: v},
            }, SetOptions(merge: true)).catchError((e) {
              debugPrint('Failed to save privacy pref: $e');
            });
          }
        },
        activeColor: AppTheme.lightTheme.primaryColor,
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
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (ctx, sc) => Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: sc,
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
              const Text('Help & FAQ',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _faqItem('How do I get my diet plan?',
                  'Once you subscribe to a plan, your dietician will create a personalized diet plan and upload it to the app. You can view it under "My Diet Plan" on the home screen.'),
              _faqItem('How do I update my diet plan?',
                  'Submit your Weekly Check-in with your progress, current weight, and any concerns. Your dietician reviews it and updates your plan accordingly.'),
              _faqItem('How do I log my meals?',
                  'Tap the "+ Quick Log" button on the home screen and select "Meal". Enter the food name, calories, and meal type (breakfast, lunch, dinner, etc.).'),
              _faqItem('How do I track my weight?',
                  'Tap "Quick Log" → "Weight" to record your current weight. Your progress chart is visible in the "My Progress" section.'),
              _faqItem('How do I change my password?',
                  'Go to Profile → Change Password. A password reset link will be sent to your registered email address.'),
              _faqItem('How do I make a payment or subscribe?',
                  'Go to the Quick Access tile "Subscription" on the Home screen. Choose a plan and complete payment via Razorpay.'),
              _faqItem('Can I pause my subscription?',
                  'Yes — go to Profile → Subscription Management → Request Pause. Your dietician will be notified and pause your plan accordingly.'),
              _faqItem('My name or details are incorrect — how to fix?',
                  'Go to Profile → Personal Information and update your name, mobile number, city, or country. Onboarding health details are read-only; contact support to change them.'),
              _faqItem('Why am I being signed out randomly?',
                  'This has been fixed in the latest version. If it persists, try signing out once manually and signing back in. Your data is safe in the cloud.'),
              _faqItem('How do I contact my dietician?',
                  'Use the "Contact Support" option in the Profile section. You can call or WhatsApp us at +91 8871448064 and we will connect you with your dietician.'),
              const SizedBox(height: 24),
            ],
          ),
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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Contact Support',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text(
              'We are here to help you. Reach us via call or WhatsApp:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            const Text(
              '+91 8871448064',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.call),
                label: const Text('Call Us'),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final tel = Uri.parse('tel:+918871448064');
                  if (await canLaunchUrl(tel)) {
                    await launchUrl(tel);
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open dialer. Call +91 8871448064')),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.chat),
                label: const Text('WhatsApp Us'),
                onPressed: () async {
                  Navigator.pop(ctx);
                  const url =
                      'https://wa.me/918871448064?text=Hi%2C%20I%20need%20help%20with%20the%20Dietician%20Babu%20app';
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Could not open WhatsApp. Message +91 8871448064')),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
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
