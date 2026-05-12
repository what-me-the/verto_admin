import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';

class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<_NavItem> _navItems = [
    _NavItem(
      title: 'Overview',
      icon: Icons.dashboard_outlined,
      route: '/dashboard',
    ),
    _NavItem(
      title: 'Analytics',
      icon: Icons.analytics_outlined,
      route: '/analytics',
    ),
    _NavItem(
      title: 'Users',
      icon: Icons.people_outline,
      route: '/users', // Future
    ),
    _NavItem(
      title: 'Translations',
      icon: Icons.translate,
      route: '/translations', // Future
    ),
    _NavItem(
      title: 'Settings',
      icon: Icons.settings_outlined,
      route: '/settings', // Future
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSelectedIndex();
  }

  void _updateSelectedIndex() {
    final location = GoRouterState.of(context).uri.toString();
    for (int i = 0; i < _navItems.length; i++) {
      if (location.startsWith(_navItems[i].route)) {
        setState(() {
          _selectedIndex = i;
        });
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.lightIvory,
      appBar: AppBar(
        title: Text(_navItems[_selectedIndex].title),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            _buildDrawerHeader(authViewModel),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _navItems.length,
                itemBuilder: (context, index) {
                  final item = _navItems[index];
                  final isSelected = _selectedIndex == index;
                  return ListTile(
                    leading: Icon(
                      item.icon,
                      color: isSelected
                          ? AppColors.earthyCoral
                          : AppColors.slateGray,
                    ),
                    title: Text(
                      item.title,
                      style: isSelected
                          ? AppTypography.bodyMedium.copyWith(
                              color: AppColors.earthyCoral,
                              fontWeight: FontWeight.w600,
                            )
                          : AppTypography.bodyMedium,
                    ),
                    selected: isSelected,
                    selectedTileColor: AppColors.earthyCoral.withOpacity(0.1),
                    onTap: () {
                      context.go(item.route);
                      // Close drawer on mobile/tablet
                      if (!isDesktop) {
                        Navigator.pop(context);
                      }
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                  );
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: Text(
                'Sign Out',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
              onTap: () async {
                await authViewModel.signOut();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      body: widget.child,
    );
  }

  Widget _buildDrawerHeader(AuthViewModel authViewModel) {
    final user = authViewModel.currentUser;
    return UserAccountsDrawerHeader(
      decoration: const BoxDecoration(color: AppColors.earthyCoral),
      accountName: Text(
        user?.userMetadata?['full_name'] ?? 'Admin User',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      accountEmail: Text(user?.email ?? ''),
      currentAccountPicture: const CircleAvatar(
        backgroundColor: Colors.white,
        backgroundImage: AssetImage('assets/images/logo.png'),
      ),
    );
  }
}

class _NavItem {
  final String title;
  final IconData icon;
  final String route;

  _NavItem({required this.title, required this.icon, required this.route});
}
