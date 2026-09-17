import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/presentation/retry.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/core/widgets/error_view.dart';
import 'package:funances/features/home/presentation/model/overview_view_model.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:funances/l10n/app_localizations.dart';

/// O saldo do período, na faixa ao pé da Visão Geral.
///
/// Mora fora do `CategorySummaryView` porque lê outro provider
/// (`summaryBalance`) e é uma afirmação só sua: o total de receitas menos
/// despesas, no modo escolhido.
class BalanceSummaryView extends ConsumerWidget {
  const BalanceSummaryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final asyncState = ref.watch(HomeViewProviders.summaryBalance);
    final period = ref.watch(HomeViewProviders.period);
    final viewType = ref.watch(HomeViewProviders.viewType);
    final locale = context.locale;

    // R$ 0,00 é um número, e um número afirma. Enquanto o mês não chega — ou
    // quando a leitura falha — o saldo não pode afirmar nada.
    if (asyncState.hasError) {
      return ErrorView.forError(
        context,
        asyncState.error,
        onRetry: () => Retry.monthSummary(ref, period.monthKey),
      );
    }

    final state = asyncState.valueOrNull;
    if (state == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final amount = viewType == SummaryViewType.planning
        ? state.totalPlanned
        : state.totalActual;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.deepTurquoise.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.deepTurquoise.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.balance,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.deepTurquoise,
            ),
          ),
          Text(
            amount.asCurrency(locale: locale),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: amount >= 0 ? AppColors.limeGreen : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}
