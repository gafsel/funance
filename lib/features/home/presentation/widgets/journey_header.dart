import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/time/clock.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/home/domain/models/monthly_available_model.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:go_router/go_router.dart';

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
          onRetry: () => ref.invalidate(JourneyViewProviders.monthlyAvailable),
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
      padding: const EdgeInsets.only(bottom: 24),
      child: Material(
        color: AppColors.deepTurquoise,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ),
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
          style: const TextStyle(
            color: AppColors.pureWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const SizedBox(
          height: 28,
          width: 28,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation(AppColors.successGold),
          ),
        ),
        const SizedBox(height: 8),
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
        const Icon(Icons.cloud_off_outlined, color: AppColors.pureWhite),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            l10n.journeyAvailableError,
            style: const TextStyle(color: AppColors.pureWhite),
          ),
        ),
        TextButton(
          onPressed: onRetry,
          child: Text(
            l10n.retry,
            style: const TextStyle(color: AppColors.successGold),
          ),
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
          style: const TextStyle(
            color: AppColors.pureWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.journeyAvailableNoIncome,
          style: TextStyle(
            color: AppColors.pureWhite.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 12),
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
                style: const TextStyle(
                  color: AppColors.pureWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.pureWhite,
              size: 20,
            ),
          ],
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value.asCurrency(locale: locale),
            style: theme.textTheme.displaySmall?.copyWith(
              color: value < 0 ? AppColors.coralOrange : AppColors.successGold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.journeyAvailableSpent(
            available.realizedExpenses.asCurrency(locale: locale),
            available.plannedExpenses.asCurrency(locale: locale),
          ),
          style: TextStyle(
            color: AppColors.pureWhite.withValues(alpha: 0.85),
            fontSize: 13,
          ),
        ),
        if (available.pendingExpenses > 0) ...[
          const SizedBox(height: 2),
          Text(
            l10n.journeyAvailablePending(
              available.pendingExpenses.asCurrency(locale: locale),
            ),
            style: TextStyle(
              color: AppColors.pureWhite.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }
}
