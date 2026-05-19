import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/login_form.dart';

/// Admin Login Screen with responsive layout
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Reset Password', style: AppTypography.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                hintText: 'Email address',
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: AppColors.slateGray,
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.slateGray,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.isNotEmpty) {
                final authViewModel = context.read<AuthViewModel>();
                final success = await authViewModel.sendPasswordResetEmail(
                  emailController.text.trim(),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  _showResultSnackbar(
                    success
                        ? 'Password reset email sent. Check your inbox.'
                        : 'Failed to send reset email. Please try again.',
                    success,
                  );
                }
              }
            },
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  void _showResultSnackbar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: AppColors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightIvory,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive breakpoints
            final isDesktop = constraints.maxWidth > 900;
            final isTablet =
                constraints.maxWidth > 600 && constraints.maxWidth <= 900;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: isDesktop ? 450 : (isTablet ? 400 : 380),
                      ),
                      padding: EdgeInsets.all(isDesktop ? 48 : 32),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo/Brand
                          _buildHeader(),
                          const SizedBox(height: 40),

                          // Login Form
                          LoginForm(
                            onForgotPassword: _showForgotPasswordDialog,
                            onLoginSuccess: () {
                              // Navigation will be handled by router
                            },
                          ),

                          const SizedBox(height: 24),

                          // Footer
                          _buildFooter(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo placeholder - can be replaced with actual logo
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.admin_panel_settings_rounded,
                  size: 60,
                  color: Colors.deepOrange,
                ),
              ),
        ),
        const SizedBox(height: 24),
        Text(
          'Verto Admin',
          style: AppTypography.h2.copyWith(color: AppColors.darkCharcoal),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to access the admin panel',
          style: AppTypography.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Divider(color: AppColors.paleGray.withOpacity(0.5)),
        const SizedBox(height: 16),
        Text(
          '© 2026 Verto Translation Platform',
          style: AppTypography.caption.copyWith(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
