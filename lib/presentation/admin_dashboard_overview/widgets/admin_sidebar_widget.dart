import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_export.dart';
import '../../../services/firebase_service.dart';

/// Admin navigation sidebar with grouped sections and a modern filled-pill
/// selection indicator. All navigation logic is preserved from the original.
class AdminSidebarWidget extends StatefulWidget {
  const AdminSidebarWidget({super.key});

  @override
  State<AdminSidebarWidget> createState() => _AdminSidebarWidgetState();
}

class _AdminSidebarWidgetState extends State<AdminSidebarWidget> {
  String _selectedItem = 'Dashboard';

  // Structured sections — add/remove items here to update the sidebar.
  static final _sections = [
    _Section('OVERVIEW', [
      _Item('Dashboard', Icons.dashboard_outlined, '/admin-dashboard-overview'),
    ]),
    _Section('CLIENTS', [
      _Item('Client Management', Icons.people_outlined, '/client-management-system'),
      _Item('Subscriptions', Icons.card_membership_outlined, '/subscriptions-management'),
    ]),
    _Section('CONTENT', [
      _Item('Diet Plans', Icons.restaurant_menu_outlined, '/diet-plans-management'),
    ]),
    _Section('BUSINESS', [
      _Item('Sales Analytics', Icons.bar_chart_outlined, '/sales-analytics'),
      _Item('Settings', Icons.settings_outlined, '/admin-settings'),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E3A8A), Color(0xFF1A3276)],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(3, 0)),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              children: _buildSectionedMenu(),
            ),
          ),
          _buildUserFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.local_dining, color: Color(0xFF1E3A8A), size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Dietician Babu',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              Text(
                'Admin Panel',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white60,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSectionedMenu() {
    final widgets = <Widget>[];
    for (final section in _sections) {
      // Section label
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(left: 12, top: 16, bottom: 4),
          child: Text(
            section.label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white38,
              letterSpacing: 1.2,
            ),
          ),
        ),
      );
      // Items in this section
      for (final item in section.items) {
        widgets.add(_buildMenuItem(item));
      }
    }
    return widgets;
  }

  Widget _buildMenuItem(_Item item) {
    final isSelected = _selectedItem == item.title;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _selectMenuItem(item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: isSelected ? Colors.white : Colors.white60,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserFooter() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF2563EB),
            child: Text(
              'A',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Admin',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Administrator',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white54),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _showLogoutDialog,
            icon: const Icon(Icons.logout_rounded, color: Colors.white54, size: 18),
            tooltip: 'Logout',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void _selectMenuItem(_Item item) {
    setState(() => _selectedItem = item.title);

    final scaffold = Scaffold.maybeOf(context);
    if (scaffold != null && scaffold.isDrawerOpen) {
      scaffold.closeDrawer();
    }

    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      switch (item.route) {
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
    });
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
                    context, AppRoutes.login, (route) => false);
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

// ── Data classes ──────────────────────────────────────────────────────────────

class _Section {
  final String label;
  final List<_Item> items;
  const _Section(this.label, this.items);
}

class _Item {
  final String title;
  final IconData icon;
  final String route;
  const _Item(this.title, this.icon, this.route);
}
