import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sizer/sizer.dart';

import '../core/app_export.dart';
import '../widgets/custom_error_widget.dart';
import 'services/firebase_service.dart';
import 'presentation/login_screen/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await FirebaseService.initialize();
    debugPrint('✅ Firebase initialized');
  } catch (e) {
    debugPrint('❌ Failed to initialize Firebase: $e');
  }

  bool _hasShownError = false;

  // 🚨 CRITICAL: Custom error handling
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!_hasShownError) {
      _hasShownError = true;
      Future.delayed(const Duration(seconds: 5), () {
        _hasShownError = false;
      });
      return CustomErrorWidget(errorDetails: details);
    }
    return const SizedBox.shrink();
  };

  // 🚨 CRITICAL: Device orientation lock
  Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
  ]).then((value) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(builder: (context, orientation, screenType) {
      return MaterialApp(
        title: 'Dietician Babu',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.0),
            ),
            child: AuthGuard(child: child!),
          );
        },
        debugShowCheckedModeBanner: false,
        routes: AppRoutes.routes,
        initialRoute: AppRoutes.initial,
      );
    });
  }
}

/// 🛡️ ADMIN GUARD: Prevents non-admins from accessing the Web Dashboard
class AuthGuard extends StatelessWidget {
  final Widget child;
  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Only apply the guard on Web
    if (!kIsWeb) return child;

    return StreamBuilder(
      stream: FirebaseService.instance.auth.authStateChanges(),
      builder: (context, snapshot) {
        // If still loading auth state, show a loading spinner
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = snapshot.data;
        
        // If not logged in, force them to the Login Screen
        if (user == null) {
          return const LoginScreen();
        }

        // If logged in BUT not the admin email, show an "Access Denied" error
        if (user.email != 'dieticianbabu@gmail.com') {
          return const Scaffold(
            body: Center(
              child: Text(
                'Access Denied: You do not have administrator privileges.',
                style: TextStyle(color: Colors.red, fontSize: 18),
              ),
            ),
          );
        }

        // Otherwise, they are allowed in!
        return child;
      },
    );
  }
}
