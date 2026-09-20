import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_breakpoints.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/goal/domain/models/goal_model.dart';
import 'package:funances/features/goal/presentation/model/goal_progress_ui.dart';
import 'package:funances/features/goal/presentation/provider.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:funances/core/widgets/app_card.dart';
import 'package:funances/core/widgets/app_chip.dart';
import 'package:funances/core/widgets/app_progress_bar.dart';
import 'package:funances/core/widgets/error_view.dart';
import 'package:funances/core/presentation/retry.dart';
import 'package:funances/core/widgets/empty_state.dart';

/// A seção de metas.
///
/// Ela era um bloco da Home até a primeira aba virar a cena do jogo; hoje
/// mora em `/goals`, que abre pela grade de estratégia do botão de lançar.
/// Continua sendo um widget solto, e não parte de uma tela, porque é assim
/// que ela se monta sozinha num teste — sem puxar o Firebase de mais nada.
class GoalsSection extends ConsumerWidget {
  const GoalsSection({
    super.key,
    this.highlightOnly = false,
    this.showTitle = true,
  });

  /// `false` na tela `/goals`, onde a `AppBar` já diz "Metas".
  ///
  /// A seção desenhava o próprio título, e a tela desenhava outro igual logo
  /// acima: "Metas" duas vezes, uma abaixo da outra, com dois botões de
  /// adicionar. Quem titula é quem contém.
  final bool showTitle;

  /// Mostra UMA meta — a mais próxima do fim — em vez da lista inteira.
  ///
  /// A Home listava todas as metas ativas E todas as encerradas, cada uma num
  /// cartão com barra, valores e prazo. Meta é um compromisso de meses: a
  /// lista inteira não muda de um dia para o outro, e mesmo assim era o bloco
  /// mais alto da tela. Aqui fica a que está mais perto de fechar — a única
  /// em que um gesto de hoje ainda faz diferença — e um atalho para as
  /// outras.
  final bool highlightOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final goalsAsync = ref.watch(GoalViewProvider.goalsStream);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  // Título é SUBSTANTIVO. Aqui havia a frase de convite do
                  // onboarding — "Trace suas primeiras metas" — como título
                  // de uma tela de quem já tem quatro.
                  l10n.goalsTitle,
                  style: theme.textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(Icons.add_circle, color: context.palette.tealText),
                tooltip: l10n.journeyAddGoalTooltip,
                onPressed: () => _showAddGoalDialog(context),
              ),
            ],
          ),
          AppSpacing.gapMd,
        ],
        goalsAsync.when(
          data: (goals) {
            if (goals.isEmpty) {
              return _buildEmptyGoals(context, l10n, theme);
            }

            // Metas encerradas saem da lista das que estão correndo:
            // uma meta que estourou o limite lado a lado com as ativas
            // sugere que ainda dá tempo de fazer alguma coisa por ela.
            // O mesmo vale para a meta cujo prazo venceu e que ainda
            // espera a apuração do servidor — ela também não corre mais.
            final running = [
              for (final goal in goals)
                if (!goal.isClosed) goal,
            ];
            final closed = [
              for (final goal in goals)
                if (goal.isClosed) goal,
            ];

            if (highlightOnly) {
              return _buildHighlight(
                context,
                l10n,
                theme,
                running: running,
                total: goals.length,
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (running.isNotEmpty) _buildGoalGrid(context, running),
                if (closed.isNotEmpty) ...[
                  if (running.isNotEmpty) AppSpacing.gapLg,
                  Text(
                    l10n.journeyClosedGoalsTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: context.palette.ink2,
                    ),
                  ),
                  AppSpacing.gapSm,
                  _buildGoalGrid(context, closed),
                ],
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) =>
              ErrorView.forError(context, e, onRetry: () => Retry.goals(ref)),
        ),
      ],
    );
  }

  /// A meta em destaque: a de prazo mais curto entre as que ainda correm.
  ///
  /// Ordenar por prazo e não por progresso é de propósito. A meta com 90% já
  /// está resolvida; a que vence em duas semanas é a que ainda depende de uma
  /// decisão desta semana.
  Widget _buildHighlight(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme, {
    required List<GoalModel> running,
    required int total,
  }) {
    // Só metas ENCERRADAS é um estado real e comum — quem cumpriu tudo, quem
    // perdeu o prazo de todas. Dizer "você não tem metas" ali é falso, e
    // escondia a única porta para `/goals`: sem uma segunda meta CORRENTE o
    // atalho não aparecia, e as encerradas ficavam inalcançáveis.
    if (running.isEmpty) {
      if (total == 0) return _buildEmptyGoals(context, l10n, theme);

      return Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.journeyNoRunningGoals,
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.palette.ink2,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/goals'),
              child: Text(l10n.journeySeeClosedGoals(total)),
            ),
          ],
        ),
      );
    }

    final ordered = [...running]
      ..sort((a, b) => a.deadline.compareTo(b.deadline));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildGoalLine(context, ordered.first),
        // O contador é do que a tela `/goals` LISTA — correntes e encerradas
        // —, não do que corre. Com uma meta corrente e quatro encerradas o
        // atalho sumia, e "Ver as N metas" prometia um número que não era o
        // que a tela mostrava.
        if (total > 1) ...[
          AppSpacing.gapXs,
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.push('/goals'),
              child: Text(l10n.journeySeeAllGoals(total)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyGoals(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return EmptyState.centered(
      icon: Icons.flag_outlined,
      title: l10n.goalEmptyMessage,
      message: l10n.goalEmptyExample,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      action: ElevatedButton.icon(
        onPressed: () => _showAddGoalDialog(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.addGoalButton),
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context, [GoalModel? goal]) {
    context.push(goal == null ? '/goals/form' : '/goals/form?id=${goal.id}');
  }

  /// Grade responsiva de cards (a mesma quebra para as ativas e as encerradas).
  Widget _buildGoalGrid(BuildContext context, List<GoalModel> goals) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Quatro cortes literais (600/900/1200) para o mesmo dado que o
        // design system já resolve: um cartão de meta por coluna do layout.
        final crossAxisCount = constraints.layout.columns;

        if (crossAxisCount > 1) {
          const spacing = AppSpacing.md;
          final width =
              (constraints.maxWidth - (spacing * (crossAxisCount - 1))) /
              crossAxisCount;
          return Align(
            alignment: Alignment.topLeft,
            child: Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: goals.map((goal) {
                return SizedBox(
                  width: width.clamp(0.0, 400.0),
                  child: _buildGoalCard(context, goal),
                );
              }).toList(),
            ),
          );
        }

        return Column(
          children: goals
              .map(
                (goal) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _buildGoalCard(context, goal),
                ),
              )
              .toList(),
        );
      },
    );
  }

  /// A meta em destaque na Home, em UMA linha.
  ///
  /// O cartão tem ícone em cápsula, nome, alvo, prazo, barra, dois valores e
  /// um selo de desfecho: 192px. É o desenho certo numa LISTA de metas, onde
  /// a pergunta é comparativa — e é caro numa Home cujo teto inteiro é 1088.
  ///
  /// Meta é o compromisso mais longo que o app guarda; na Home ela é a linha
  /// que diz que existe e quanto falta, no mesmo formato da Bússola, do
  /// coaching e das missões. O cartão continua sendo o desenho de `/goals`.
  Widget _buildGoalLine(BuildContext context, GoalModel goal) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final progress = goal.calculateProgress();

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: AppRadius.brMd,
        onTap: () => context.push('/goals/${goal.id}'),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.brMd,
            border: Border.all(color: palette.line),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Icon(
                goal.type == GoalType.saveMoney
                    ? Icons.savings
                    : goal.type == GoalType.payDebt
                    ? Icons.handshake
                    : Icons.trending_down,
                size: 18,
                color: palette.ink2,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  goal.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.ink,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              SizedBox(
                width: 64,
                child: AppProgressBar(
                  value: progress.percent,
                  size: AppProgressSize.thin,
                  semanticLabel: goal.name,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                progress.percent.asPercent(locale: context.locale),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: palette.ink2,
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: palette.ink2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, GoalModel goal) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = context.palette;
    final progress = goal.calculateProgress();
    final locale = context.locale;
    final statusColor = progress.getStatusColor(context);

    return AppCard(
      onTap: () => context.push('/goals/${goal.id}'),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: AppSpacing.allXs,
                decoration: BoxDecoration(
                  color: palette.ink.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  goal.type == GoalType.saveMoney
                      ? Icons.savings
                      : goal.type == GoalType.payDebt
                      ? Icons.handshake
                      : Icons.trending_down,
                  color: palette.ink,
                ),
              ),
              AppSpacing.gapSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.name, style: theme.textTheme.titleMedium),
                    Text(
                      l10n.goalTargetTarget(
                        goal.targetAmount.asCurrency(locale: locale),
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                    if (goal.monthlyRequirement > 0)
                      Text(
                        l10n.goalMonthlyRequirementValue(
                          goal.monthlyRequirement.asCurrency(locale: locale),
                        ),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: palette.ink,
                        ),
                      ),
                  ],
                ),
              ),
              StatusPill(
                label: progress.getStatusText(l10n),
                color: statusColor,
                dense: true,
              ),
            ],
          ),
          AppSpacing.gapMd,
          // Duas camadas do MESMO componente: atrás a projeção, na frente
          // o realizado. A da frente não desenha trilho para não apagar a
          // de trás.
          Stack(
            children: [
              AppProgressBar(
                value: progress.predictionPercent,
                size: AppProgressSize.thick,
                color: statusColor.withValues(alpha: .5),
              ),
              Positioned.fill(
                child: AppProgressBar(
                  value: progress.percent,
                  size: AppProgressSize.thick,
                  color: statusColor,
                  trackColor: AppColors.transparent,
                  semanticLabel: goal.name,
                ),
              ),
            ],
          ),
          AppSpacing.gapXs,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // O texto muda com o tipo: nas metas de redução,
              // `currentAmount` é gasto contra um teto, não conquista.
              Expanded(
                child: Text(
                  goal.progressSummary(
                    l10n,
                    (value) => value.asCurrency(locale: locale),
                  ),
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AppSpacing.gapXs,
              Text(
                goal.deadline.formated(l10n.formatSimpleDate),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          if (goal.isClosed) ...[
            AppSpacing.gapXxs,
            Row(
              children: [
                Icon(goal.outcomeIcon, size: 14, color: goal.outcomeColor),
                AppSpacing.gapXxs,
                Expanded(
                  child: Text(
                    goal.outcomeLabel(
                          l10n,
                          (date) => date.formated(l10n.formatSimpleDate),
                        ) ??
                        '',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: goal.outcomeColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
