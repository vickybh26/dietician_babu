import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import 'core/app_export.dart';
import 'widgets/custom_error_widget.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await FirebaseService.initialize();
    debugPrint('✅ Firebase initialized');
  } catch (e) {
    debugPrint('Firebase initialization failed');
    runApp(MaterialApp(home: Scaffold(body: Center(child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Unable to connect. Check the app configuration and try again.'),
        TextButton(onPressed: main, child: const Text('Retry')),
      ],
    )))));
    return;
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
              textScaler: MediaQuery.textScalerOf(context),
            ),
            child: child!,
          );
        },
        debugShowCheckedModeBanner: false,
        routes: AppRoutes.routes,
        initialRoute: AppRoutes.initial,
      );
    });
  }
}
