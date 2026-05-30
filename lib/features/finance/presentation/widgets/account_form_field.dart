import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/screens/account_selection_screen.dart';

class AccountFormField extends ConsumerWidget {
  const AccountFormField({
    super.key,
    this.initialValue,
    this.onChanged,
    this.validator,
    this.decoration,
    this.autoOpen = false,
  });

  final String? initialValue;
  final InputDecoration? decoration;
  final ValueChanged<String?>? onChanged;
  final FormFieldValidator<String?>? validator;
  final bool autoOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (autoOpen && initialValue == null) {
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
              onAccountSelected: (acc) => Navigator.pop(context, acc),
            ),
          );

          if (account != null) {
            onChanged?.call(account.id);
          }
        });
      }
    }
    final l10n = context.l10n;

    String getAccountTypeName(AccountType type) {
      switch (type) {
        case AccountType.checking:
          return l10n.accountTypeChecking;
        case AccountType.investment:
          return l10n.accountTypeInvestment;
        case AccountType.creditCard:
          return l10n.accountTypeCreditCard;
        case AccountType.debt:
          return l10n.accountTypeDebt;
      }
    }

    return FormField<String?>(
      key: ValueKey(initialValue),
      initialValue: initialValue,
      validator: validator,
      builder: (state) {
        final accountId = state.value;
        final accountAsync = accountId != null
            ? ref.watch(AccountViewProviders.byId(accountId))
            : const AsyncValue<AccountModel?>.data(null);

        return InkWell(
          onTap: () async {
            final account = await showModalBottomSheet<AccountModel?>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (context) => AccountSelectionScreen(
                title: decoration?.labelText ?? l10n.transactionAccountLabel,
                showClearOption: true,
                onAccountSelected: (acc) => Navigator.pop(context, acc),
              ),
            );

            state.didChange(account?.id);
            onChanged?.call(account?.id);
          },
          child: InputDecorator(
            decoration: (decoration ?? const InputDecoration()).copyWith(
              errorText: state.errorText,
              suffixIcon: const Icon(Icons.chevron_right),
            ),
            child: accountAsync.when(
              data: (account) {
                if (account == null) {
                  return Container();
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getAccountTypeName(account.type),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).hintColor,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: ShapeDecoration(
                            shape: const CircleBorder(),
                            color: account.color.asColor().withValues(alpha: 0.2),
                          ),
                          child: Icon(
                            account.icon.asIcon(),
                            size: 16,
                            color: account.color.asColor(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          account.name,
                          style: Theme.of(context).textTheme.bodyMedium,
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
              error: (_, __) => const Icon(Icons.error),
            ),
          ),
        );
      },
    );
  }
}
