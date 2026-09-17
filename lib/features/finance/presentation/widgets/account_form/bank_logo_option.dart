import 'package:flutter/material.dart';
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
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
              : null,
        ),
        child: logo == BankLogo.none
            ? Center(
                child: Text(
                  label ?? '?',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.bold : null,
                  ),
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(8),
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
