import 'package:flutter/material.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/health_profile_onboarding/health_profile_onboarding.dart';
import '../presentation/progress_tracking/progress_tracking.dart';
import '../presentation/dashboard_home/dashboard_home.dart';
import '../presentation/settings_profile/settings_profile.dart';
import '../presentation/admin_dashboard_overview/admin_dashboard_overview.dart';
import '../presentation/client_management_system/client_management_system.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String splash = '/splash-screen';
  static const String login = '/login-screen';
  static const String healthProfileOnboarding = '/health-profile-onboarding';
  static const String progressTracking = '/progress-tracking';
  static const String dashboardHome = '/dashboard-home';
  static const String settingsProfile = '/settings-profile';
  static const String adminDashboardOverview = '/admin-dashboard-overview';
  static const String clientManagementSystem = '/client-management-system';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    healthProfileOnboarding: (context) => const HealthProfileOnboarding(),
    progressTracking: (context) => const ProgressTracking(),
    dashboardHome: (context) => const DashboardHome(),
    settingsProfile: (context) => const SettingsProfile(),
    adminDashboardOverview: (context) => const AdminDashboardOverview(),
    clientManagementSystem: (context) => const ClientManagementSystem(),
    // TODO: Add your other routes here
  };
}