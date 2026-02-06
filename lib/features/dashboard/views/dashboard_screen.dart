import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../auth/widgets/primary_button.dart';

/// Enhanced Dashboard Screen for Auth Verification
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch AuthViewModel for changes
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.currentUser;
    final session = authViewModel.currentSession;

    return Scaffold(
      backgroundColor: AppColors.lightIvory,
      appBar: AppBar(
        title: Text('Admin Verification', style: AppTypography.h3),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh logic if needed, effectively just re-reads state
            },
            tooltip: 'Refresh State',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. User Identity Card
            _buildInfoCard(
              title: 'User Identity',
              icon: Icons.badge_outlined,
              children: [
                _buildInfoRow('Email', user?.email ?? 'Unknown'),
                _buildInfoRow('User ID', user?.id ?? 'Unknown'),
                _buildInfoRow('Last Sign In', user?.lastSignInAt ?? 'Unknown'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.softMint.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.softMint),
                  ),
                  child: Text(
                    'Role: ADMIN', // In a real app, fetch from claims/metadata
                    style: AppTypography.caption.copyWith(
                      color: AppColors.darkCharcoal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 2. Session Security Card
            _buildInfoCard(
              title: 'Session Security',
              icon: Icons.security,
              children: [
                _buildInfoRow('Status', 'Active'),
                _buildInfoRow(
                  'Expires At',
                  session?.expiresAt != null
                      ? DateTime.fromMillisecondsSinceEpoch(
                          session!.expiresAt! * 1000,
                        ).toString()
                      : 'Unknown',
                ),
                _buildInfoRow('Token Type', session?.tokenType ?? 'Bearer'),
              ],
            ),
            const SizedBox(height: 48),

            // 3. Actions
            Text('Actions', style: AppTypography.h3.copyWith(fontSize: 20)),
            const SizedBox(height: 16),

            PrimaryButton(
              text: 'View Analytics',
              icon: Icons.analytics_outlined,
              onPressed: () => context.go('/analytics'),
            ),
            const SizedBox(height: 16),

            PrimaryButton(
              text: 'Secure Sign Out',
              icon: Icons.logout_rounded,
              isLoading: authViewModel.isLoading,
              onPressed: () => _showLogoutConfirmation(context, authViewModel),
            ),

            if (authViewModel.errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  authViewModel.errorMessage!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.earthyCoral),
                const SizedBox(width: 12),
                Text(title, style: AppTypography.h3.copyWith(fontSize: 18)),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.slateGray,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, AuthViewModel viewModel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to securely end your session?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              await viewModel.signOut();
              // Router will handle navigation based on auth state
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
