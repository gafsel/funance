import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';

/// Um destino da barra inferior.
///
/// O `Tooltip` e o `Semantics` não são enfeite: o rótulo tem 10px e some em
/// fonte grande, e sem `selected: true` o leitor de tela não diz qual aba
/// está aberta.

class HomeBottomBarItem extends StatelessWidget {
  const HomeBottomBarItem({
    super.key,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? AppColors.successGold
        : AppColors.pureWhite.withValues(alpha: 0.8);
    return Expanded(
      child: Tooltip(
        message: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Semantics(
            label: label,
            selected: isSelected,
            button: true,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isSelected ? selectedIcon : icon, color: color),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.bold : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
