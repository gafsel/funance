import 'package:flutter/material.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/presentation/widgets/account_selection/account_labels.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

/// As três linhas que NÃO são uma conta de banco agrupada: uma conta avulsa
/// (sem logo de instituição), "limpar a seleção" e "criar uma conta".
///
/// Elas compartilham a moldura dos cartões de banco de propósito — são opções
/// da mesma lista, e uma borda diferente as faria parecer outra coisa.
class StandaloneAccountCard extends StatelessWidget {
  const StandaloneAccountCard({
    super.key,
    required this.account,
    required this.onAccountSelected,
    required this.isSmall,
  });

  final AccountModel account;
  final ValueChanged<AccountModel> onAccountSelected;
  final bool isSmall;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final paddingVal = isSmall ? 10.0 : 16.0;
    final logoSize = isSmall ? 32.0 : 40.0;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => onAccountSelected(account),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(paddingVal),
          child: Row(
            children: [
              Container(
                width: logoSize,
                height: logoSize,
                decoration: BoxDecoration(
                  color: account.color.asColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(isSmall ? 8 : 10),
                ),
                child: Icon(
                  account.icon.asIcon(),
                  color: account.color.asColor(),
                  size: isSmall ? 18 : 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style:
                          (isSmall
                                  ? theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    )
                                  : theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ))
                              ?.copyWith(color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      accountTypeName(account.type, l10n),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.5,
                ),
                size: isSmall ? 16 : 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClearAccountOption extends StatelessWidget {
  const ClearAccountOption({
    super.key,
    required this.onCleared,
    required this.isSmall,
  });

  final VoidCallback onCleared;
  final bool isSmall;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final paddingVal = isSmall ? 10.0 : 16.0;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: paddingVal),
        leading: CircleAvatar(
          backgroundColor: Colors.transparent,
          radius: isSmall ? 16 : 20,
          child: Icon(
            Icons.clear_all,
            color: Colors.grey,
            size: isSmall ? 20 : 24,
          ),
        ),
        title: Text(
          l10n.clear,
          style: isSmall
              ? theme.textTheme.bodyMedium
              : theme.textTheme.titleSmall,
        ),
        onTap: onCleared,
      ),
    );
  }
}

class AddAccountOption extends StatelessWidget {
  const AddAccountOption({super.key, required this.isSmall});

  final bool isSmall;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final paddingVal = isSmall ? 10.0 : 16.0;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: paddingVal),
        leading: CircleAvatar(
          backgroundColor: Colors.transparent,
          radius: isSmall ? 16 : 20,
          child: Icon(Icons.add, color: Colors.grey, size: isSmall ? 20 : 24),
        ),
        title: Text(
          l10n.accountCreateTitle,
          style: isSmall
              ? theme.textTheme.bodyMedium
              : theme.textTheme.titleSmall,
        ),
        onTap: () {
          context.push('/accounts/form');
        },
      ),
    );
  }
}
