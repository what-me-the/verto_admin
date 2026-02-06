import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../data/moderation_model.dart';

class ModerationStatsWidget extends StatelessWidget {
  final ModerationStats stats;

  const ModerationStatsWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = width > 1100 ? 4 : (width > 600 ? 2 : 1);
        // Increased aspect ratio for shorter height
        double childAspectRatio = width > 1100
            ? 2.8
            : (width > 600 ? 3.2 : 3.5);

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: childAspectRatio,
          children: [
            _buildStatCard(
              context,
              'Pending',
              stats.totalPending.toString(),
              Icons.hourglass_empty,
              Colors.orangeAccent,
            ),
            _buildStatCard(
              context,
              'Approved',
              stats.approved.toString(),
              Icons.check_circle_outline,
              AppColors.softMint,
            ),
            _buildStatCard(
              context,
              'Rejected',
              stats.rejected.toString(),
              Icons.cancel_outlined,
              AppColors.error,
            ),
            _buildStatCard(
              context,
              'Skipped',
              stats.skipped.toString(),
              Icons.skip_next,
              Colors.grey,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.slateGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkCharcoal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
