import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/presentation/retry.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/widgets/app_card.dart';
import 'package:funances/core/widgets/error_view.dart';
import 'package:funances/core/widgets/money_text.dart';
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
    final palette = context.palette;

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
        padding: AppSpacing.allMd,
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

    return AppCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.balance,
            style: theme.textTheme.titleMedium?.copyWith(color: palette.ink),
          ),
          MoneyText(
            amount,
            style: theme.textTheme.titleLarge?.copyWith(
              color: amount >= 0 ? palette.successText : palette.dangerText,
            ),
          ),
        ],
      ),
    );
  }
}
