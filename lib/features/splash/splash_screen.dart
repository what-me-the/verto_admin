import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/viewmodels/auth_viewmodel.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _controller.forward();

    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Wait for animation and initialization (min 2 seconds)
    await Future.wait([
      Future.delayed(const Duration(seconds: 3)),
      // You might want to wait for AuthViewModel initialization here if it wasn't done in main
      // context.read<AuthViewModel>().initialize(),
    ]);

    if (!mounted) return;

    final authViewModel = context.read<AuthViewModel>();

    // Check auth status and navigate
    if (authViewModel.status == AuthStatus.authenticated) {
      context.go('/dashboard');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Or your app's background color
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Image.asset(
              'assets/images/logo.png',
              width: 250,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.admin_panel_settings_rounded,
                size: 100,
                color: Colors.deepOrange,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
