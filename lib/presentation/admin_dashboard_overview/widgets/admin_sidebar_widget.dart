import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_export.dart';
import '../../../services/firebase_service.dart';

class AdminSidebarWidget extends StatefulWidget {
  const AdminSidebarWidget({super.key});

  @override
  State<AdminSidebarWidget> createState() => _AdminSidebarWidgetState();
}

class _AdminSidebarWidgetState extends State<AdminSidebarWidget> {
  String _selectedItem = 'Dashboard';

  final List<Map<String, dynamic>> _menuItems = [
    {'title': 'Dashboard', 'icon': Icons.dashboard, 'route': '/admin-dashboard-overview'},
    {'title': 'Client Management', 'icon': Icons.people, 'route': '/client-management-system'},
    {'title': 'Diet Plans', 'icon': Icons.restaurant_menu, 'route': '/diet-plans-management'},
    {'title': 'Sales Analytics', 'icon': Icons.analytics, 'route': '/sales-analytics'},
    {'title': 'Subscriptions', 'icon': Icons.card_membership, 'route': '/subscriptions-management'},
    {'title': 'Settings', 'icon': Icons.settings, 'route': '/admin-settings'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1E3A8A),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo Header
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.local_dining,
                    color: Color(0xFF1E3A8A),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Dietician Babu\nAdmin',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(color: Colors.white24, height: 1),
          
          // Menu Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                final isSelected = _selectedItem == item['title'];
                
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _selectMenuItem(item),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected 
                              ? Border.all(color: Colors.white.withOpacity(0.2))
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item['icon'],
                              color: isSelected ? Colors.white : Colors.white70,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item['title'],
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: isSelected ? Colors.white : Colors.white70,
                                ),
                              ),
                            ),
                            if (item['title'] == 'Client Management')
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '3',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // User Profile Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Admin User',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Administrator',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showLogoutDialog(),
                  icon: const Icon(
                    Icons.logout,
                    color: Colors.white70,
                    size: 18,
                  ),
                  tooltip: 'Logout',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _selectMenuItem(Map<String, dynamic> item) {
    setState(() => _selectedItem = item['title']);

    // Close drawer if open
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    final route = item['route'] as String?;
    if (route == null) return;

    switch (route) {
      case '/admin-dashboard-overview':
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.adminDashboardOverview, (r) => false);
        break;
      case '/client-management-system':
        Navigator.pushNamed(context, AppRoutes.clientManagementSystem);
        break;
      case '/diet-plans-management':
        Navigator.pushNamed(context, AppRoutes.dietPlansManagement);
        break;
      case '/sales-analytics':
        Navigator.pushNamed(context, AppRoutes.salesAnalytics);
        break;
      case '/subscriptions-management':
        Navigator.pushNamed(context, AppRoutes.subscriptionsManagement);
        break;
      case '/admin-settings':
        Navigator.pushNamed(context, AppRoutes.adminSettings);
        break;
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
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
                  AppRoutes.login,
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}