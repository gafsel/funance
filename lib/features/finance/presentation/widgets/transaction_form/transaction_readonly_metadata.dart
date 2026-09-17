import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/form/responsive_form.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/widgets/account_logo.dart';

/// Categoria e contas de um lançamento que já não se edita.
///
/// A linha da conta de origem e a da conta de destino eram o MESMO `Consumer`
/// escrito duas vezes, com 40 linhas cada, diferindo só no rótulo e no id —
/// agora é [_AccountMetadataRow] duas vezes.
List<Widget> transactionReadOnlyMetadata(
  BuildContext context,
  TransactionFormState state,
) {
  final theme = Theme.of(context);
  final l10n = context.l10n;

  return [
    if (state.category != null)
      FullWidthItem(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Text(
                "${l10n.transactionCategoriesSection}: ",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(width: 8),
              Chip(
                avatar: CircleAvatar(
                  backgroundColor: state.category!.color.asColor().withValues(
                    alpha: 0.2,
                  ),
                  child: Icon(
                    state.category!.icon.asIcon(),
                    size: 12,
                    color: state.category!.color.asColor(),
                  ),
                ),
                label: Text(state.category!.name),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),

    if (state.accountIdSource != null)
      FullWidthItem(
        _AccountMetadataRow(
          accountId: state.accountIdSource!,
          label: state.type == OrderType.transfer
              ? "${l10n.transactionFromAccountLabel}: "
              : "${l10n.transactionAccountLabel}: ",
        ),
      ),

    if (state.type == OrderType.transfer && state.accountIdTarget != null)
      FullWidthItem(
        _AccountMetadataRow(
          accountId: state.accountIdTarget!,
          label: "${l10n.transactionToAccountLabel}: ",
        ),
      ),
  ];
}

class _AccountMetadataRow extends ConsumerWidget {
  const _AccountMetadataRow({required this.accountId, required this.label});

  final String accountId;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accountAsync = ref.watch(AccountViewProviders.byId(accountId));

    return accountAsync.when(
      data: (account) {
        if (account == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(width: 8),
              AccountLogo(account: account, size: 20),
              const SizedBox(width: 8),
              Text(
                account.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
