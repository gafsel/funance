import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
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
      spacing: 8,
      runSpacing: 8,
      children: SummaryViewType.values.map((type) {
        final isSelected = viewType == type;
        return ChoiceChip(
          label: Text(l10n.fromSummaryViewType(type)),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              ref.read(HomeViewProviders.viewType.notifier).state = type;
            }
          },
          selectedColor: AppColors.vibrantTeal.withValues(alpha: 0.2),
          labelStyle: TextStyle(
            color: isSelected ? AppColors.deepTurquoise : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }
}
