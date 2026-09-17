import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';

/// Selos de 25%, 50%, 75% e 100% do progresso da meta.
///
/// Só aparecem em metas de acúmulo — em meta de redução, 100% é estourar o
/// orçamento, e comemorar isso seria premiar o erro. Quem decide se exibe é a
/// tela; este arquivo só sabe desenhar o selo aceso e o apagado.
class MilestoneBadges extends StatelessWidget {
  final double currentPercent;
  final Color statusColor;

  const MilestoneBadges({
    super.key,
    required this.currentPercent,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final milestones = [25, 50, 75, 100];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: milestones.map((m) {
        final reached = (currentPercent * 100) >= m;
        return _Badge(label: '$m%', reached: reached, statusColor: statusColor);
      }).toList(),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final bool reached;
  final Color statusColor;

  const _Badge({
    required this.label,
    required this.reached,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: reached
            ? LinearGradient(
                colors: [AppColors.limeGreen, statusColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: reached ? null : AppColors.pureWhite.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: reached
              ? Colors.transparent
              : AppColors.pureWhite.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (reached) const Icon(Icons.star, size: 12, color: Colors.white),
          if (reached) const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: reached
                  ? Colors.white
                  : AppColors.pureWhite.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: reached ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
