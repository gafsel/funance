import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';

/// Quadrado selecionável de banco/bandeira do formulário de conta.
///
/// A opção `BankLogo.none` é o caso especial: em vez da imagem, mostra o texto
/// "Personalizado", porque é ela que libera os campos de ícone e cor da conta.
/// Por isso o widget aceita `label` — nenhuma outra opção usa.
class BankLogoOption extends StatelessWidget {
  final BankLogo logo;
  final bool isSelected;
  final VoidCallback onSelected;
  final String? label;

  const BankLogoOption({
    super.key,
    required this.logo,
    required this.isSelected,
    required this.onSelected,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final accent = theme.colorScheme.primary;

    return InkWell(
      onTap: onSelected,
      borderRadius: AppRadius.brSm,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? accent : palette.line,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: AppRadius.brSm,
          color: isSelected ? accent.withValues(alpha: 0.1) : null,
        ),
        child: logo == BankLogo.none
            ? Center(
                child: Text(label ?? '?', style: theme.textTheme.labelSmall),
              )
            : ClipRRect(
                borderRadius: AppRadius.brSm,
                child: Image.asset(
                  'assets/logos/${logo.name}.png',
                  fit: BoxFit.fitWidth,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.help_outline),
                ),
              ),
      ),
    );
  }
}
