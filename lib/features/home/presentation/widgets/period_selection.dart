import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/features/home/presentation/provider.dart';

class PeriodSelection extends ConsumerWidget {
  const PeriodSelection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewDate = ref.watch(HomeViewProviders.period);
    final theme = Theme.of(context);
    final locale = context.locale;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            ref
                .read(HomeViewProviders.period.notifier)
                .choose(DateTime(overviewDate.year, overviewDate.month - 1));
          },
        ),
        Text(
          '${overviewDate.formated("MMMM", locale)} ${overviewDate.year}',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            ref
                .read(HomeViewProviders.period.notifier)
                .choose(DateTime(overviewDate.year, overviewDate.month + 1));
          },
        ),
      ],
    );
  }
}
