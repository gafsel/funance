import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/enum_messages.dart';
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

  bool get enabled => onChanged != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

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
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.name,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: enabled ? null : Colors.black38,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.fromAccountType(account.type),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: enabled
                                    ? Theme.of(context).hintColor
                                    : Colors.black38,
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
              error: (_, __) => const Icon(Icons.error),
            ),
          ),
        );
      },
    );
  }
}
