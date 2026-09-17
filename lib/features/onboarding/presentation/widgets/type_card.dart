import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';

class TypeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const TypeCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.teal.withValues(alpha: 0.2),
            child: Icon(icon, color: AppColors.teal),
          ),
          AppSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                AppSpacing.gapXxs,
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.ink2,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: palette.ink),
        ],
      ),
    );
  }
}
