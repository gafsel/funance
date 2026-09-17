import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/widgets/app_chip.dart';
import 'package:funances/core/utils/enum_messages.dart';
import 'package:funances/features/home/presentation/model/overview_view_model.dart';
import 'package:funances/features/home/presentation/provider.dart';

class SummaryTypeSelection extends ConsumerWidget {
  const SummaryTypeSelection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final viewType = ref.watch(HomeViewProviders.viewType);

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: SummaryViewType.values.map((type) {
        return AppChip(
          label: l10n.fromSummaryViewType(type),
          selected: viewType == type,
          onSelected: (selected) {
            if (selected) {
              ref.read(HomeViewProviders.viewType.notifier).state = type;
            }
          },
        );
      }).toList(),
    );
  }
}
