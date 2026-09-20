import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/presentation/widgets/account_selection/account_labels.dart';
import 'package:funances/l10n/app_localizations.dart';

/// As contas de um banco, agrupadas num cartão.
///
/// O agrupamento por instituição é o que faz a lista caber: quem tem conta
/// corrente, cartão e investimento no mesmo banco via TRÊS cartões iguais,
/// com o mesmo logo, um embaixo do outro.
class InstitutionGroupCard extends StatelessWidget {
  const InstitutionGroupCard({
    super.key,
    required this.bank,
    required this.accounts,
    required this.onAccountSelected,
    required this.isSmall,
  });

  final BankLogo bank;
  final List<AccountModel> accounts;
  final ValueChanged<AccountModel> onAccountSelected;

  /// Painel estreito: o cartão encolhe padding, logo e tipografia em vez de
  /// quebrar a linha do nome do banco.
  final bool isSmall;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.palette;
    final bankName = institutionName(bank, l10n);
    final paddingVal = isSmall ? 10.0 : AppSpacing.md;
    final logoSize = isSmall ? 32.0 : 40.0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(paddingVal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: isSmall ? AppSpacing.xs : AppSpacing.sm,
              runSpacing: isSmall ? 6 : AppSpacing.xs,
              children: [
                ClipRRect(
                  borderRadius: AppRadius.brSm,
                  child: Image.asset(
                    'assets/logos/${bank.name}.png',
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: logoSize,
                      height: logoSize,
                      color: palette.tealText.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.account_balance,
                        color: palette.tealText,
                        size: isSmall ? 20 : 24,
                      ),
                    ),
                  ),
                ),
                Text(
                  bankName,
                  style: isSmall
                      ? theme.textTheme.titleSmall
                      : theme.textTheme.titleMedium,
                ),
              ],
            ),
            SizedBox(height: isSmall ? AppSpacing.xs : AppSpacing.sm),
            const Divider(height: 1),
            SizedBox(height: isSmall ? 6 : AppSpacing.xs),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: accounts.indexed.map((entry) {
                final idx = entry.$1;
                final acc = entry.$2;
                final typeIconSize = isSmall ? 26.0 : 32.0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (idx > 0)
                      Divider(height: isSmall ? AppSpacing.sm : AppSpacing.md),
                    InkWell(
                      onTap: () => onAccountSelected(acc),
                      borderRadius: AppRadius.brMd,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: isSmall ? AppSpacing.xxs : AppSpacing.xs,
                          horizontal: isSmall ? AppSpacing.xxs : AppSpacing.xs,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: typeIconSize,
                              height: typeIconSize,
                              decoration: BoxDecoration(
                                // A cor é da CONTA: dado do usuário.
                                color: acc.color.asColor().withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: AppRadius.brSm,
                              ),
                              child: Icon(
                                accountTypeIcon(acc.type),
                                color: acc.color.asColor(),
                                size: isSmall ? 15 : 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    accountTypeName(acc.type, l10n),
                                    style: theme.textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    acc.name,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: palette.ink2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: palette.ink3,
                              size: isSmall ? 16 : 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
