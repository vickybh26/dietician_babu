import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../services/firebase_service.dart';
import '../../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late AnimationController _backgroundAnimationController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _backgroundAnimation;

  bool _isInitialized = false;
  String _statusMessage = 'Preparing your wellness journey...';
  bool _showRetryButton = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    // Logo animation controller
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Background animation controller
    _backgroundAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Logo scale animation
    _logoScaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.elasticOut,
    ));

    // Logo opacity animation
    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    // Background gradient animation
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundAnimationController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _backgroundAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _logoAnimationController.forward();
    });
  }

  Future<void> _initializeApp() async {
    try {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Color(0xFF1976D2),
          statusBarIconBrightness: Brightness.light,
        ),
      );

      // Let animations play
      await Future.delayed(const Duration(milliseconds: 1800));

      if (!mounted) return;
      setState(() {
        _isInitialized = true;
        _statusMessage = 'Ready to start your journey!';
      });

      await Future.delayed(const Duration(milliseconds: 500));
      _navigateToNextScreen();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Having trouble connecting...';
        _showRetryButton = true;
      });
      Future.delayed(const Duration(seconds: 5), () {
        if (_showRetryButton && mounted) {
          _retryInitialization();
        }
      });
    }
  }

  Future<void> _navigateToNextScreen() async {
    if (!mounted) return;
    final fs = FirebaseService.instance;

    // ✅ FIX: Await the first auth state event from Firebase instead of reading
    // `currentUser` synchronously. On cold start Firebase may still be
    // resolving the cached token, so `currentUser` can return null even when
    // the user IS logged in, causing a spurious sign-out. `authStateChanges().first`
    // properly waits for Firebase to confirm the auth state.
    final user = await fs.auth.authStateChanges().first;

    if (!mounted) return;

    // Not logged in → Landing screen (public marketing page)
    if (user == null) {
      Navigator.pushReplacementNamed(context, AppRoutes.landing);
      return;
    }

    // Admin → Admin dashboard
    if (fs.isAdmin) {
      Navigator.pushReplacementNamed(context, AppRoutes.adminDashboardOverview);
      return;
    }

    // Regular client — check if onboarding is complete
    try {
      setState(() => _statusMessage = 'Loading your profile...');
      final profile = await fs.getUserProfile(user.uid);
      if (!mounted) return;

      // Auto-create users doc if missing (e.g. user signed up before rules were fixed)
      if (profile == null) {
        await fs.users.doc(user.uid).set({
          'uid': user.uid,
          'name': user.displayName ?? user.email?.split('@').first ?? 'User',
          'email': user.email ?? '',
          'phone': user.phoneNumber ?? '',
          'role': 'client',
          'onboardingComplete': false,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.healthProfileOnboarding);
        return;
      }

      final onboardingDone = profile['onboardingComplete'] == true;
      if (!onboardingDone) {
        Navigator.pushReplacementNamed(context, AppRoutes.healthProfileOnboarding);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.dashboardHome);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.dashboardHome);
    }
  }

  void _retryInitialization() {
    setState(() {
      _showRetryButton = false;
      _statusMessage = 'Retrying connection...';
    });
    _initializeApp();
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _backgroundAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(
                    const Color(0xFF1976D2),
                    const Color(0xFF1976D2),
                    _backgroundAnimation.value,
                  )!,
                  Color.lerp(
                    const Color(0xFF1976D2),
                    const Color(0xFF43A047),
                    _backgroundAnimation.value,
                  )!,
                ],
                stops: const [0.0, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Spacer to push content to center
                  const Spacer(flex: 2),

                  // Logo section
                  AnimatedBuilder(
                    animation: _logoAnimationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoScaleAnimation.value,
                        child: Opacity(
                          opacity: _logoOpacityAnimation.value,
                          child: _buildLogo(),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 6.h),

                  // Loading indicator and status
                  _buildLoadingSection(),

                  // Spacer to balance layout
                  const Spacer(flex: 3),

                  // Retry button (if needed)
                  if (_showRetryButton) _buildRetryButton(),

                  SizedBox(height: 4.h),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 25.w,
      height: 25.w,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'restaurant_menu',
            color: Colors.white,
            size: 8.w,
          ),
          SizedBox(height: 1.h),
          Text(
            'DB',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 4.w,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSection() {
    return Column(
      children: [
        // App name
        Text(
          'Dietician Babu',
          style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 6.w,
          ),
        ),

        SizedBox(height: 1.h),

        // Tagline
        Text(
          'Your Personal Wellness Coach',
          style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 3.5.w,
          ),
        ),

        SizedBox(height: 4.h),

        // Loading indicator
        SizedBox(
          width: 6.w,
          height: 6.w,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ),

        SizedBox(height: 2.h),

        // Status message
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _statusMessage,
            key: ValueKey(_statusMessage),
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 3.w,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildRetryButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _retryInitialization,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: EdgeInsets.symmetric(vertical: 2.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: 'refresh',
                color: Colors.white,
                size: 4.w,
              ),
              SizedBox(width: 2.w),
              Text(
                'Retry Connection',
                style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontSize: 3.5.w,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
