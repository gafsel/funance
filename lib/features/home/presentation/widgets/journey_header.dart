import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/time/clock.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/core/widgets/app_card.dart';
import 'package:funances/core/widgets/money_text.dart';
import 'package:funances/features/home/domain/models/monthly_available_model.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:funances/core/presentation/retry.dart';
import 'package:funances/core/utils/date_extension.dart';

/// O cabeçalho da Jornada: um número que responde "quanto posso gastar até o
/// fim do mês".
///
/// F3.1: a Jornada abria em missões e gráficos e não respondia a única
/// pergunta que o usuário faz todo dia. O número é
/// `renda prevista − despesas realizadas − despesas pendentes até o fim do
/// mês`; tocar nele leva à Visão Geral do mês, onde a conta está aberta
/// categoria por categoria.
class JourneyHeader extends ConsumerWidget {
  const JourneyHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(JourneyViewProviders.monthlyAvailable);

    return async.when(
      loading: () => const _HeaderShell(child: _HeaderLoading()),
      error: (error, stack) => _HeaderShell(
        child: _HeaderError(
          // O "quanto sobra" vem do resumo do mês, que vem das categorias:
          // invalidar só o último da fila relia o erro cacheado do pai.
          onRetry: () =>
              Retry.monthlyAvailable(ref, ref.read(todayProvider).monthKey),
        ),
      ),
      data: (available) {
        if (!available.hasIncomeExpectation) {
          return const _HeaderShell(child: _HeaderNoIncome());
        }

        return _HeaderShell(
          onTap: () {
            // Volta o período para o mês corrente antes de trocar de aba: o
            // número fala do mês em que o usuário está, e abrir a Visão Geral
            // num mês antigo que ele visitou faria a conta não bater.
            ref
                .read(HomeViewProviders.period.notifier)
                .choose(ref.read(todayProvider));
            ref.read(HomeViewProviders.selectedTab.notifier).state = 1;
          },
          child: _HeaderAmount(available: available),
        );
      },
    );
  }
}

class _HeaderShell extends StatelessWidget {
  const _HeaderShell({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: AppCard.game(
        onTap: onTap,
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}

class _HeaderLoading extends StatelessWidget {
  const _HeaderLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.journeyAvailableTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        AppSpacing.gapMd,
        const SizedBox(
          height: 28,
          width: 28,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation(AppColors.gold),
          ),
        ),
        AppSpacing.gapXs,
      ],
    );
  }
}

class _HeaderError extends StatelessWidget {
  const _HeaderError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Row(
      children: [
        const Icon(Icons.cloud_off_outlined, color: AppColors.inkInverse),
        AppSpacing.gapSm,
        Expanded(child: Text(l10n.journeyAvailableError)),
        TextButton(
          onPressed: onRetry,
          style: TextButton.styleFrom(foregroundColor: AppColors.gold),
          child: Text(l10n.retry),
        ),
      ],
    );
  }
}

/// Sem expectativa de receita não há disponível: o número seria só o negativo
/// das despesas, o que é pior do que não mostrar número nenhum.
class _HeaderNoIncome extends StatelessWidget {
  const _HeaderNoIncome();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.journeyAvailableTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        AppSpacing.gapXs,
        Text(
          l10n.journeyAvailableNoIncome,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.inkInverse2),
        ),
        AppSpacing.gapSm,
        FilledButton.tonalIcon(
          key: const ValueKey('journey-set-income'),
          onPressed: () => context.push('/planning?type=income'),
          icon: const Icon(Icons.trending_up_rounded),
          label: Text(l10n.journeyAvailableNoIncomeAction),
        ),
      ],
    );
  }
}

class _HeaderAmount extends StatelessWidget {
  const _HeaderAmount({required this.available});

  final MonthlyAvailable available;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.locale;
    final theme = Theme.of(context);
    final value = available.available;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.journeyAvailableTitle,
                style: theme.textTheme.titleMedium,
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.inkInverse,
              size: 20,
            ),
          ],
        ),
        AppSpacing.gapXxs,
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: MoneyText(
            value,
            style: theme.textTheme.displaySmall?.copyWith(
              color: value < 0 ? AppColors.warning : AppColors.gold,
            ),
          ),
        ),
        AppSpacing.gapXxs,
        Text(
          l10n.journeyAvailableSpent(
            available.realizedExpenses.asCurrency(locale: locale),
            available.plannedExpenses.asCurrency(locale: locale),
          ),
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.inkInverse2,
          ),
        ),
        if (available.pendingExpenses > 0) ...[
          AppSpacing.gapXxs,
          Text(
            l10n.journeyAvailablePending(
              available.pendingExpenses.asCurrency(locale: locale),
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.inkInverse.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }
}
