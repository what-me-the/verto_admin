import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
// Note: OverviewScreen is now a child of MainLayout, so it doesn't need its own AppBar/Drawer potentially,
// but for now we keep it simple content.

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.currentUser;
    final session = authViewModel.currentSession;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Welcome, ${user?.userMetadata?['full_name'] ?? 'Admin'}',
            style: AppTypography.h2,
          ),
          const SizedBox(height: 24),

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
                  'Role: ADMIN',
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
        ],
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
}
