import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/firebase_service.dart';
import '../../routes/app_routes.dart';
import '../admin_dashboard_overview/widgets/admin_scaffold.dart';

class AdminSettings extends StatefulWidget {
  const AdminSettings({super.key});

  @override
  State<AdminSettings> createState() => _AdminSettingsState();
}

class _AdminSettingsState extends State<AdminSettings> {
  final _fs = FirebaseService.instance;
  String _adminName = '';
  String _adminEmail = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminInfo();
  }

  Future<void> _loadAdminInfo() async {
    final uid = _fs.currentUser?.uid;
    if (uid == null) return;
    final profile = await _fs.getUserProfile(uid);
    setState(() {
      _adminEmail = _fs.currentUser?.email ?? '';
      _adminName = profile?['displayName'] ?? profile?['name'] ?? 'Admin';
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _fs.signOut();
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
    }
  }

  Future<void> _changePassword() async {
    final email = _fs.currentUser?.email;
    if (email == null) return;
    await _fs.sendPasswordReset(email);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent to $email')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Settings',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Settings', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                  const SizedBox(height: 24),

                  // Admin Profile Card
                  _sectionCard(
                    title: 'Admin Profile',
                    children: [
                      _infoRow(Icons.person, 'Name', _adminName),
                      const Divider(),
                      _infoRow(Icons.email, 'Email', _adminEmail),
                      const Divider(),
                      _infoRow(Icons.admin_panel_settings, 'Role', 'Administrator'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Account Actions
                  _sectionCard(
                    title: 'Account',
                    children: [
                      ListTile(
                        leading: const Icon(Icons.lock_reset, color: Color(0xFF1976D2)),
                        title: Text('Change Password', style: GoogleFonts.inter()),
                        subtitle: Text('Send a password reset email', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _changePassword,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // App Info
                  _sectionCard(
                    title: 'App Info',
                    children: [
                      _infoRow(Icons.app_registration, 'App Name', 'Dietician Babu'),
                      const Divider(),
                      _infoRow(Icons.business, 'Business', 'Dietician Babu, Indore'),
                      const Divider(),
                      _infoRow(Icons.code, 'Version', '1.1.0'),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[500])),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14)),
          const Spacer(),
          Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14)),
        ],
      ),
    );
  }
}
