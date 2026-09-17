import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';

/// Chip de contagem do resumo do extrato lido ("N lançamentos encontrados").
///
/// Vive separado porque é o pedaço que mais tende a se repetir: cada novo dado
/// que a leitura do documento passar a detectar entra como mais um chip, e o
/// formulário não precisa saber desenhá-lo para isso.
Widget buildAccountFormInfoChip(IconData icon, String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.blue.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.blue[800]),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: AppColors.darkNavy),
        ),
      ],
    ),
  );
}
