import 'package:flutter/material.dart';
import 'package:funances/core/form/loading_button.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_spacing.dart';

/// Linha "rótulo + valor" do detalhe de transação.
///
/// Saiu do sheet porque é a única peça dele que aparece em contextos
/// diferentes — categoria, conta, status — e cada um passa um `customValue`
/// próprio. Mantê-la privada dentro do sheet obrigava qualquer novo campo a
/// nascer lá dentro, engordando um arquivo que já era grande demais.
class DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final Widget? customValue;
  final IconData icon;
  final Color? iconColor;
  final LoadingCallback? onTap;

  const DetailItem({
    super.key,
    required this.label,
    required this.value,
    this.customValue,
    required this.icon,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return LoadingButton.text(
      onPressed: onTap,
      child: Row(
        spacing: AppSpacing.xs,
        children: [
          Container(
            padding: AppSpacing.allXs,
            decoration: BoxDecoration(
              color: (iconColor ?? theme.colorScheme.primary).withValues(
                alpha: 0.1,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: iconColor ?? theme.colorScheme.primary,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: palette.ink2,
                  ),
                ),
                if (customValue != null)
                  customValue!
                else
                  Text(value, style: theme.textTheme.titleSmall),
              ],
            ),
          ),
          if (onTap != null) Icon(Icons.chevron_right, color: palette.ink2),
        ],
      ),
    );
  }
}
