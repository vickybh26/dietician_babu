import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
import '../presentation/client_profile/client_profile_screen.dart';
import '../presentation/appointments/appointments_screen.dart';
import '../presentation/food_catalogue/food_catalogue_screen.dart';
import '../presentation/member_analytics/member_analytics_screen.dart';
import '../presentation/restore_requests/restore_requests_screen.dart';

class AppRoutes {
  // Common Routes
  static const String initial = '/';
  static const String splash = '/splash-screen';
  static const String login = '/login-screen';

  // Client App Routes
  static const String landing = '/landing';
  static const String signup = '/signup';
  static const String healthProfileOnboarding = '/health-profile-onboarding';
  static const String progressTracking = '/progress-tracking';
  static const String dashboardHome = '/dashboard-home';
  static const String settingsProfile = '/settings-profile';
  static const String weeklyCheckin = '/weekly-checkin';
  static const String dietPlanViewer = '/diet-plan-viewer';
  static const String subscriptionPlans = '/subscription-plans';
  static const String appointments = '/appointments';

  // Admin Web Routes
  static const String adminDashboardOverview = '/admin-dashboard-overview';
  static const String clientManagementSystem = '/client-management-system';
  static const String clientProfile = '/client-profile';             // Phase 1
  static const String adminDietPlanCreator = '/admin-diet-plan-creator';
  static const String dietPlansManagement = '/diet-plans-management';
  static const String salesAnalytics = '/sales-analytics';
  static const String subscriptionsManagement = '/subscriptions-management';
  static const String adminSettings = '/admin-settings';
  static const String foodCatalogue = '/food-catalogue';
  static const String memberAnalytics = '/member-analytics';
  static const String restoreRequests = '/restore-requests';

  static Map<String, WidgetBuilder> get routes {
    // Basic routes available to both
    final commonRoutes = {
      splash: (context) => const SplashScreen(),
      login: (context) => const LoginScreen(),
    };

    if (kIsWeb) {
      // WEB ONLY: Only return Admin routes (and login)
      return {
        ...commonRoutes,
        initial: (context) => const AdminDashboardOverview(), // Web starts at Admin Dashboard
        adminDashboardOverview: (context) => const AdminDashboardOverview(),
        clientManagementSystem: (context) => const ClientManagementSystem(),
        clientProfile: (context) {
          final uid = ModalRoute.of(context)!.settings.arguments as String;
          return ClientProfileScreen(clientId: uid);
        },
        adminDietPlanCreator: (context) => const AdminDietPlanCreator(),
        dietPlansManagement: (context) => const DietPlansManagement(),
        salesAnalytics: (context) => const SalesAnalytics(),
        subscriptionsManagement: (context) => const SubscriptionsManagement(),
        adminSettings: (context) => const AdminSettings(),
        foodCatalogue: (context) => const FoodCatalogueScreen(),
        memberAnalytics: (context) => const MemberAnalyticsScreen(),
        restoreRequests: (context) => const RestoreRequestsScreen(),
      };
    } else {
      // MOBILE ONLY: Only return Client routes
      return {
        ...commonRoutes,
        initial: (context) => const SplashScreen(), // Mobile starts at Splash
        landing: (context) => const LandingScreen(),
        signup: (context) => const SignupScreen(),
        healthProfileOnboarding: (context) => const HealthProfileOnboarding(),
        progressTracking: (context) => const ProgressTracking(),
        dashboardHome: (context) => const DashboardHome(),
        settingsProfile: (context) => const SettingsProfile(),
        weeklyCheckin: (context) => const WeeklyCheckIn(),
        dietPlanViewer: (context) => const DietPlanViewer(),
        subscriptionPlans: (context) => const SubscriptionPlans(),
        appointments: (context) => const AppointmentsScreen(),
      };
    }
  }
}
