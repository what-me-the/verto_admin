import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/viewmodels/auth_viewmodel.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/dashboard/views/overview_screen.dart';
import '../../features/dashboard/views/main_layout.dart';
import '../../features/analytics/views/analytics_screen.dart';
import '../../features/moderation/views/moderation_screen.dart';
import '../../features/users/views/users_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../core/widgets/placeholder_screen.dart';

/// App router configuration with authentication guards
class AppRouter {
  final AuthViewModel authViewModel;

  AppRouter(this.authViewModel);

  late final GoRouter router = GoRouter(
    initialLocation: '/splash', // Changed from /login
    debugLogDiagnostics: true,
    refreshListenable: authViewModel, // Listen to auth state changes
    redirect: _handleRedirect,
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const OverviewScreen(), // Use new overview widget
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
            ),
          ),
          GoRoute(
            path: '/analytics',
            name: 'analytics',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const AnalyticsScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
            ),
          ),
          GoRoute(
            path: '/users',
            name: 'users',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const UsersScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
            ),
          ),
          GoRoute(
            path: '/translations',
            name: 'translations',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ModerationScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
            ),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const PlaceholderScreen(
                title: 'Settings',
                icon: Icons.settings_outlined,
              ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
            ),
          ),
          // Add other routes here (Users, translations, etc) later
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.uri}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    ),
  );

  /// Handle route redirections based on authentication state
  String? _handleRedirect(BuildContext context, GoRouterState state) {
    // Check auth status from ViewModel directly
    final isAuthenticated = authViewModel.status == AuthStatus.authenticated;
    final isOnSplash = state.matchedLocation == '/splash';
    final isOnLogin = state.matchedLocation == '/login';

    // Allow splash screen to handle its own logic/navigation
    if (isOnSplash) {
      return null;
    }

    // If not authenticated and not on login page, redirect to login
    if (!isAuthenticated && !isOnLogin) {
      return '/login';
    }

    // If authenticated and on login page, redirect to dashboard
    if (isAuthenticated && isOnLogin) {
      return '/dashboard';
    }

    // No redirect needed
    return null;
  }
}
