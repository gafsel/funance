import 'package:confetti/confetti.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/core/widgets/loading_modal.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/widgets/detail_header.dart';
import 'package:funances/features/finance/presentation/widgets/account_logo.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_list_view.dart';
import 'package:funances/features/goal/domain/models/goal_model.dart';
import 'package:funances/features/goal/presentation/provider.dart';
import 'package:funances/features/goal/presentation/model/goal_progress_ui.dart';
import 'package:funances/features/home/presentation/widgets/category_icon.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class GoalDetailScreen extends ConsumerStatefulWidget {
  final String goalId;

  const GoalDetailScreen({super.key, required this.goalId});

  @override
  ConsumerState<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends ConsumerState<GoalDetailScreen> {
  TransactionQuery? _query;
  late ConfettiController _confettiController;
  int _lastCheckedPct = -1;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _initQuery(GoalModel goal) {
    if (_query != null) return;

    _query = TransactionQuery(
      accountId: goal.mapOrNull(
        saveMoney: (g) => g.accountId,
        reduceCreditCard: (g) => g.accountId,
        payDebt: (g) => g.accountId,
      ),
      categoryId: goal.mapOrNull(
        reduceExpense: (g) => g.category.id,
      ),
      startDate: goal.startDate,
      endDate: goal.deadline,
    );
  }

  Future<void> _checkMilestonesAndCleanup(
    GoalModel goal,
    double progressPercent,
    List<GoalModel> allGoals,
  ) async {
    final newMilestone = await ref
        .read(GoalViewProvider.milestone.notifier)
        .checkMilestoneAndCelebrate(
          goal: goal,
          progressPercent: progressPercent,
          allGoals: allGoals,
        );

    if (newMilestone != null && mounted) {
      _confettiController.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final goalAsync = ref.watch(GoalViewProvider.goalById(widget.goalId));
    final allGoalsAsync = ref.watch(GoalViewProvider.goalsStream);
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return goalAsync.when(
      data: (goal) {
        if (goal == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.goalDetailsTitle)),
            body: Center(child: Text(l10n.errorUnknown)),
          );
        }

        _initQuery(goal);

        final accountId = goal.mapOrNull(
          saveMoney: (g) => g.accountId,
          reduceCreditCard: (g) => g.accountId,
          payDebt: (g) => g.accountId,
        );

        final accountAsync = accountId != null
            ? ref.watch(AccountViewProviders.byId(accountId))
            : const AsyncValue<AccountModel?>.data(null);

        final accountLogo = accountAsync.when(
          data: (account) =>
              account != null ? AccountLogo(account: account, size: 40) : null,
          loading: () => null,
          error: (_, _) => null,
        );

        final accountColor = accountAsync.when(
          data: (account) =>
              account?.color.asColor() ?? AppColors.deepTurquoise,
          loading: () => AppColors.deepTurquoise,
          error: (_, _) => AppColors.deepTurquoise,
        );

        // Milestones só fazem sentido para metas de acúmulo (guardar/quitar):
        // nas metas de redução, percent = gasto/limite — 100% é estourar o
        // orçamento, não uma conquista.
        final celebratesMilestones =
            goal.mapOrNull(
              saveMoney: (_) => true,
              payDebt: (_) => true,
            ) ??
            false;

        final screenProgress = goal.calculateProgress();
        final pct = (screenProgress.percent * 100).floor();
        if (celebratesMilestones && pct != _lastCheckedPct) {
          _lastCheckedPct = pct;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final allGoals = allGoalsAsync.valueOrNull ?? [];
            _checkMilestonesAndCleanup(goal, screenProgress.percent, allGoals);
          });
        }

        return Scaffold(
          body: Stack(
            children: [
              NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  final progress = goal.calculateProgress();

                  return [
                    SliverDetailHeader(
                      title: goal.name,
                      subtitle:
                          goal.targetAmount.asCurrency(locale: context.locale),
                      backgroundColor: goal.map(
                        payDebt: (_) => accountColor,
                        saveMoney: (_) => accountColor,
                        reduceCreditCard: (_) => accountColor,
                        reduceExpense: (re) => re.category.color.asColor(),
                      ),
                      logo: goal.map(
                        payDebt: (_) => accountLogo,
                        saveMoney: (_) => accountLogo,
                        reduceCreditCard: (_) => accountLogo,
                        reduceExpense: (re) =>
                            CategoryIcon.forCategory(re.category),
                      ),
                      expandedHeight: 460,
                      chips: [
                        DetailHeaderChip(
                          icon: Icons.calendar_today,
                          label: DateFormat.yMMMd(context.locale)
                              .format(goal.deadline),
                        ),
                        DetailHeaderChip(
                          icon: progress.getStatusIcon(),
                          label: progress.getStatusText(l10n),
                          backgroundColor: progress.getStatusColor(context),
                        ),
                        // Carimbo do servidor: só existe depois que a meta
                        // alcançou o alvo pela primeira vez.
                        if (goal.completedAt != null)
                          DetailHeaderChip(
                            icon: goal.isAccumulation
                                ? Icons.emoji_events
                                : Icons.report_gmailerrorred,
                            label: goal.completionLabel(
                              l10n,
                              (date) => DateFormat.yMMMd(
                                context.locale,
                              ).format(date),
                            )!,
                            backgroundColor: goal.isAccumulation
                                ? AppColors.limeGreen
                                : AppColors.error,
                          ),
                      ],
                      actions: [
                        DetailHeaderAction(
                          icon: Icons.edit_outlined,
                          label: l10n.editButton,
                          onPressed: () =>
                              context.push('/goals/form', extra: goal),
                        ),
                        DetailHeaderAction(
                          icon: Icons.delete_outline,
                          label: l10n.deleteButton,
                          onPressed: () => _showDeleteConfirmation(context),
                        ),
                      ],
                      bottomContent: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- Milestone badges ---
                            if (celebratesMilestones) ...[
                              _MilestoneBadges(
                                currentPercent: progress.percent,
                                statusColor: progress.getStatusColor(context),
                              ),
                              const SizedBox(height: 16),
                            ],
                            // --- Barra de progresso ---
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${goal.amountLabel(l10n)}: '
                                  '${goal.currentAmount.asCurrency(locale: context.locale)}',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: AppColors.pureWhite
                                        .withValues(alpha: 0.9),
                                  ),
                                ),
                                Text(
                                  progress.percent
                                      .asPercent(locale: context.locale),
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.brightCyan,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Stack(
                              children: [
                                Container(
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.pureWhite.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: progress.predictionPercent,
                                  child: Container(
                                    height: 12,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.limeGreen,
                                          progress
                                              .getStatusColor(context)
                                              .withValues(alpha: .5),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: progress.percent,
                                  child: Container(
                                    height: 12,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.limeGreen,
                                          progress.getStatusColor(context),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // --- Gráfico ideal vs. real ---
                            _GoalProgressChart(
                              goal: goal,
                              progress: progress,
                              statusColor: progress.getStatusColor(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ];
                },
                body: TransactionListView(
                  provider: FinanceViewProviders.goalTransactions(_query!),
                  accountId: goal.mapOrNull(
                    saveMoney: (g) => g.accountId,
                    reduceCreditCard: (g) => g.accountId,
                    payDebt: (g) => g.accountId,
                  ),
                ),
              ),
              // Confetti overlay
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  numberOfParticles: 40,
                  gravity: 0.2,
                  colors: const [
                    AppColors.limeGreen,
                    AppColors.brightCyan,
                    AppColors.successGold,
                    AppColors.vibrantTeal,
                  ],
                ),
              ),
            ],
          ),
        );
      },
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.goalDetailsTitle)),
        body: Center(child: Text(e.toString())),
      ),
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.goalDetailsTitle)),
        body: const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.goalDeleteConfirmTitle),
        content: Text(l10n.goalDeleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await showLoadingModal(
                context,
                ref.read(GoalDomainProvider.service).deleteGoal(widget.goalId),
              );
              if (context.mounted) context.pop();
            },
            child: Text(
              l10n.deleteButton,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Milestone Badges
// ---------------------------------------------------------------------------
class _MilestoneBadges extends StatelessWidget {
  final double currentPercent;
  final Color statusColor;

  const _MilestoneBadges({
    required this.currentPercent,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final milestones = [25, 50, 75, 100];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: milestones.map((m) {
        final reached = (currentPercent * 100) >= m;
        return _Badge(label: '$m%', reached: reached, statusColor: statusColor);
      }).toList(),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final bool reached;
  final Color statusColor;

  const _Badge({
    required this.label,
    required this.reached,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: reached
            ? LinearGradient(
                colors: [AppColors.limeGreen, statusColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: reached ? null : AppColors.pureWhite.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: reached
              ? Colors.transparent
              : AppColors.pureWhite.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (reached)
            const Icon(Icons.star, size: 12, color: Colors.white),
          if (reached) const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: reached
                  ? Colors.white
                  : AppColors.pureWhite.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: reached ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gráfico de Progresso (Ideal vs. Real)
// ---------------------------------------------------------------------------
class _GoalProgressChart extends StatelessWidget {
  final GoalModel goal;
  final dynamic progress; // GoalProgressViewModel
  final Color statusColor;

  const _GoalProgressChart({
    required this.goal,
    required this.progress,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final start = goal.startDate;
    final end = goal.deadline;
    final totalDays = end.difference(start).inDays.toDouble();
    if (totalDays <= 0) return const SizedBox.shrink();

    final target = goal.targetAmount;
    final current = goal.currentAmount;
    final today = DateTime.now();
    final elapsedDays = today.isAfter(end)
        ? totalDays
        : today.isBefore(start)
            ? 0.0
            : today.difference(start).inDays.toDouble();

    // Linha ideal: de 0 → target linearmente
    final idealSpots = [
      FlSpot(0, 0),
      FlSpot(totalDays, target),
    ];

    // Linha real: de 0 no start → currentAmount no dia atual
    final realSpots = [
      FlSpot(0, 0),
      FlSpot(elapsedDays.clamp(0, totalDays), current.clamp(0, target)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.goalProgressChartTitle,
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.pureWhite.withValues(alpha: 0.9),
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            _LegendDot(
              color: AppColors.pureWhite.withValues(alpha: 0.5),
              label: l10n.goalChartIdealLine,
            ),
            const SizedBox(width: 12),
            _LegendDot(color: AppColors.limeGreen, label: l10n.goalChartRealLine),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) {
                        return Text(
                          l10n.goalChartStartLabel,
                          style: TextStyle(
                            color: AppColors.pureWhite.withValues(alpha: 0.5),
                            fontSize: 10,
                          ),
                        );
                      }
                      if (value == totalDays) {
                        return Text(
                          l10n.goalChartEndLabel,
                          style: TextStyle(
                            color: AppColors.pureWhite.withValues(alpha: 0.5),
                            fontSize: 10,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              minX: 0,
              maxX: totalDays,
              minY: 0,
              maxY: target * 1.05,
              lineBarsData: [
                // Linha ideal (tracejada)
                LineChartBarData(
                  spots: idealSpots,
                  isCurved: false,
                  color: AppColors.pureWhite.withValues(alpha: 0.4),
                  barWidth: 1.5,
                  dotData: FlDotData(show: false),
                  dashArray: [6, 4],
                ),
                // Linha real (sólida, colorida)
                LineChartBarData(
                  spots: realSpots,
                  isCurved: true,
                  color: AppColors.limeGreen,
                  barWidth: 2.5,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.limeGreen.withValues(alpha: 0.3),
                        AppColors.limeGreen.withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColors.pureWhite.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
