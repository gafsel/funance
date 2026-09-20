import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/enum_messages.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/screens/account_selection_screen.dart';
import 'package:funances/features/finance/presentation/widgets/account_logo.dart';
import 'package:funances/core/utils/error_messages.dart';
import 'package:funances/core/presentation/retry.dart';

class AccountFormField extends ConsumerWidget {
  const AccountFormField({
    super.key,
    this.initialValue,
    this.onChanged,
    this.validator,
    this.decoration,
    this.autoOpen = false,
    this.showAddOption = true,
    this.style,
    this.excludeAccountId,
    this.allowedTypes,
  });

  final String? initialValue;
  final InputDecoration? decoration;
  final ValueChanged<String?>? onChanged;
  final FormFieldValidator<String?>? validator;
  final bool autoOpen;
  final bool showAddOption;
  final TextStyle? style;
  final String? excludeAccountId;

  /// Restringe a seleção a certos tipos de conta (ver
  /// [AccountSelectionScreen.allowedTypes]). `null` = todas.
  final Set<AccountType>? allowedTypes;

  bool get enabled => onChanged != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = context.palette;

    return FormField<String?>(
      initialValue: initialValue,
      validator: validator,
      builder: (state) {
        if (enabled && autoOpen && state.value == null) {
          final isModalOpen = ModalRoute.of(context)?.isCurrent == false;
          if (!isModalOpen) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              final l10n = context.l10n;
              final account = await showModalBottomSheet<AccountModel?>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (context) => AccountSelectionScreen(
                  title: decoration?.labelText ?? l10n.transactionAccountLabel,
                  showClearOption: true,
                  excludeAccountId: excludeAccountId,
                  allowedTypes: allowedTypes,
                  onAccountSelected: (acc) => Navigator.pop(context, acc),
                ),
              );

              if (account != null) {
                state.didChange(account.id);
                onChanged?.call(account.id);
              }
            });
          }
        }

        final accountId = state.value;
        final accountAsync = accountId != null
            ? ref.watch(AccountViewProviders.byId(accountId))
            : const AsyncValue<AccountModel?>.data(null);

        return InkWell(
          onTap: !enabled
              ? null
              : () async {
                  final account = await showModalBottomSheet<AccountModel?>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (context) => AccountSelectionScreen(
                      title:
                          decoration?.labelText ?? l10n.transactionAccountLabel,
                      showClearOption: true,
                      showAddOption: showAddOption,
                      excludeAccountId: excludeAccountId,
                      allowedTypes: allowedTypes,
                      onAccountSelected: (acc) => Navigator.pop(context, acc),
                    ),
                  );

                  state.didChange(account?.id);
                  onChanged?.call(account?.id);
                },
          child: InputDecorator(
            decoration: (decoration ?? const InputDecoration()).copyWith(
              errorText: state.errorText,
              suffixIcon: enabled ? const Icon(Icons.chevron_right) : null,
            ),
            child: accountAsync.when(
              data: (account) {
                if (account == null) {
                  return Container();
                }
                return Row(
                  children: [
                    AccountLogo(account: account, size: 24, showMembers: true),
                    const SizedBox(width: AppSpacing.sm),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.name,
                          style:
                              style ??
                              theme.textTheme.bodyMedium?.copyWith(
                                color: enabled ? null : palette.ink3,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.fromAccountType(account.type),
                          style:
                              style?.copyWith(
                                color:
                                    style?.color?.withValues(alpha: .75) ??
                                    palette.ink3,
                              ) ??
                              theme.textTheme.labelSmall?.copyWith(
                                color: enabled ? palette.ink2 : palette.ink3,
                              ),
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              // Um ícone de erro não diz o que houve nem o que fazer. A
              // linha cabe numa conta só: texto curto e um toque para tentar
              // de novo, que é o que resolve o caso comum (sem rede).
              error: (error, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off, size: 18, color: palette.dangerText),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      errorMessageFor(context, error),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 18),
                    tooltip: l10n.retry,
                    // `byId` deriva de `all`: invalidar o derivado deixaria
                    // o erro cacheado da lista de contas de pé.
                    onPressed: () => Retry.accounts(ref),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
