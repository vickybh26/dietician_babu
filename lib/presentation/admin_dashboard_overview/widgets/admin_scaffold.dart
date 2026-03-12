import 'package:flutter/material.dart';
import 'admin_sidebar_widget.dart';

/// Wraps admin screens with a persistent sidebar on wide screens (tablet/desktop)
/// and a hamburger-menu drawer on narrow screens (phone).
class AdminScaffold extends StatelessWidget {
  final Widget body;
  final String title;

  const AdminScaffold({super.key, required this.body, required this.title});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 720;

    if (isWide) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Row(
          children: [
            const AdminSidebarWidget(),
            Expanded(child: body),
          ],
        ),
      );
    }

    // Phone layout — hamburger drawer
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      drawer: const Drawer(child: AdminSidebarWidget()),
      body: body,
    );
  }
}
