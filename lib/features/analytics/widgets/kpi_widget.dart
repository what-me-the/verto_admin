import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class KPIWidget extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final String? subtitle;

  const KPIWidget({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.iconColor,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.slateGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (icon != null)
                  Icon(
                    icon,
                    color: iconColor ?? AppColors.earthyCoral,
                    size: 24,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.darkCharcoal,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.slateGray),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
