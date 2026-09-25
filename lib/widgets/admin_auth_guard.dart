import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../presentation/login_screen/login_screen.dart';
import '../services/firebase_service.dart';

/// Placed inside each web route so login retains a Navigator ancestor.
class AdminAuthGuard extends StatelessWidget {
  final WidgetBuilder builder;
  const AdminAuthGuard({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseService.instance.auth.idTokenChanges(),
      builder: (context, auth) {
        if (auth.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (auth.hasError) return _denied();
        if (auth.data == null) return const LoginScreen();
        return FutureBuilder<IdTokenResult>(
          future: auth.data!.getIdTokenResult(),
          builder: (context, token) {
            if (token.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (token.hasError || token.data?.claims?['admin'] != true) {
              return _denied();
            }
            return builder(context);
          },
        );
      },
    );
  }

  Widget _denied() => Scaffold(body: Center(child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text('Administrator access is required.'),
      TextButton(
        onPressed: () => FirebaseService.instance.signOut(),
        child: const Text('Sign out'),
      ),
    ],
  )));
}
