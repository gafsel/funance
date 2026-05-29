import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/enum_messages.dart';
import 'package:funances/features/finance/presentation/providers.dart';

class AccountFormField extends ConsumerWidget {
  const AccountFormField({
    super.key,
    this.initialValue,
    required this.onChanged,
    this.validator,
    this.decoration,
  });

  final String? initialValue;
  final InputDecoration? decoration;
  final ValueChanged<String?> onChanged;
  final FormFieldValidator<String?>? validator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final accounts =
        ref
            .read(AccountViewProviders.byTypeMap)
            .whenOrNull(data: (data) => data) ??
        {};

    return DropdownButtonFormField<String?>(
      initialValue: initialValue,
      decoration: decoration,
      items: [
        for (final entry in accounts.entries) ...[
          DropdownMenuItem(
            enabled: false,
            child: Text(l10n.fromAccountType(entry.key)),
          ),

          for (final account in entry.value)
            DropdownMenuItem(value: account.id, child: Text(account.name)),
        ],
      ],
      onChanged: onChanged,
      validator: validator,
    );
  }
}
