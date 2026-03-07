import 'package:flutter/material.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/landing_screen/landing_screen.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/signup_screen/signup_screen.dart';
import '../presentation/health_profile_onboarding/health_profile_onboarding.dart';
import '../presentation/progress_tracking/progress_tracking.dart';
import '../presentation/dashboard_home/dashboard_home.dart';
import '../presentation/settings_profile/settings_profile.dart';
import '../presentation/admin_dashboard_overview/admin_dashboard_overview.dart';
import '../presentation/client_management_system/client_management_system.dart';
import '../presentation/weekly_checkin/weekly_checkin.dart';
import '../presentation/diet_plan_viewer/diet_plan_viewer.dart';
import '../presentation/subscription_plans/subscription_plans.dart';
import '../presentation/admin_diet_plan_creator/admin_diet_plan_creator.dart';
import '../presentation/diet_plans_management/diet_plans_management.dart';
import '../presentation/sales_analytics/sales_analytics.dart';
import '../presentation/subscriptions_management/subscriptions_management.dart';
import '../presentation/admin_settings/admin_settings.dart';

class AppRoutes {
  static const String initial = '/';
  static const String splash = '/splash-screen';
  static const String landing = '/landing';
  static const String login = '/login-screen';
  static const String signup = '/signup';
  static const String healthProfileOnboarding = '/health-profile-onboarding';
  static const String progressTracking = '/progress-tracking';
  static const String dashboardHome = '/dashboard-home';
  static const String settingsProfile = '/settings-profile';
  static const String adminDashboardOverview = '/admin-dashboard-overview';
  static const String clientManagementSystem = '/client-management-system';
  static const String weeklyCheckin = '/weekly-checkin';
  static const String dietPlanViewer = '/diet-plan-viewer';
  static const String subscriptionPlans = '/subscription-plans';
  static const String adminDietPlanCreator = '/admin-diet-plan-creator';
  static const String dietPlansManagement = '/diet-plans-management';
  static const String salesAnalytics = '/sales-analytics';
  static const String subscriptionsManagement = '/subscriptions-management';
  static const String adminSettings = '/admin-settings';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    splash: (context) => const SplashScreen(),
    landing: (context) => const LandingScreen(),
    login: (context) => const LoginScreen(),
    signup: (context) => const SignupScreen(),
    healthProfileOnboarding: (context) => const HealthProfileOnboarding(),
    progressTracking: (context) => const ProgressTracking(),
    dashboardHome: (context) => const DashboardHome(),
    settingsProfile: (context) => const SettingsProfile(),
    adminDashboardOverview: (context) => const AdminDashboardOverview(),
    clientManagementSystem: (context) => const ClientManagementSystem(),
    weeklyCheckin: (context) => const WeeklyCheckIn(),
    dietPlanViewer: (context) => const DietPlanViewer(),
    subscriptionPlans: (context) => const SubscriptionPlans(),
    adminDietPlanCreator: (context) => const AdminDietPlanCreator(),
    dietPlansManagement: (context) => const DietPlansManagement(),
    salesAnalytics: (context) => const SalesAnalytics(),
    subscriptionsManagement: (context) => const SubscriptionsManagement(),
    adminSettings: (context) => const AdminSettings(),
  };
}
