import 'package:confetti/confetti.dart';
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
import 'package:funances/features/goal/presentation/widgets/goal_detail/goal_progress_chart.dart';
import 'package:funances/features/goal/presentation/widgets/goal_detail/milestone_badges.dart';
import 'package:funances/features/home/presentation/widgets/category_icon.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Detalhe de uma meta.
///
/// Recebe a meta JÁ CARREGADA: quem busca pelo id é a rota, via [EntityRoute]
/// (`/goals/:id`), que também responde por carregando, erro e "não existe
/// mais". Antes esta tela fazia a própria leitura e, no erro, mostrava a
/// exceção crua — `[cloud_firestore/unavailable] Failed to get document...` —
/// que é texto de Crashlytics, não de usuário.
class GoalDetailScreen extends ConsumerStatefulWidget {
  final GoalModel goal;

  const GoalDetailScreen({super.key, required this.goal});

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
      categoryId: goal.mapOrNull(reduceExpense: (g) => g.category.id),
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
    final goal = widget.goal;
    final allGoalsAsync = ref.watch(GoalViewProvider.goalsStream);
    final l10n = context.l10n;
    final theme = Theme.of(context);

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
      data: (account) => account?.color.asColor() ?? AppColors.deepTurquoise,
      loading: () => AppColors.deepTurquoise,
      error: (_, _) => AppColors.deepTurquoise,
    );

    // Milestones só fazem sentido para metas de acúmulo (guardar/quitar):
    // nas metas de redução, percent = gasto/limite — 100% é estourar o
    // orçamento, não uma conquista.
    final celebratesMilestones =
        goal.mapOrNull(saveMoney: (_) => true, payDebt: (_) => true) ?? false;

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
                  subtitle: goal.targetAmount.asCurrency(
                    locale: context.locale,
                  ),
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
                      label: DateFormat.yMMMd(
                        context.locale,
                      ).format(goal.deadline),
                    ),
                    DetailHeaderChip(
                      icon: progress.getStatusIcon(),
                      label: progress.getStatusText(l10n),
                      backgroundColor: progress.getStatusColor(context),
                    ),
                    // Carimbo do servidor: só existe depois que a meta
                    // alcançou o alvo pela primeira vez.
                    if (goal.isClosed)
                      DetailHeaderChip(
                        icon: goal.outcomeIcon,
                        label:
                            goal.outcomeLabel(
                              l10n,
                              (date) =>
                                  DateFormat.yMMMd(context.locale).format(date),
                            ) ??
                            '',
                        backgroundColor: goal.outcome == null
                            ? AppColors.antiqueGold
                            : (goal.isCompleted
                                  ? AppColors.limeGreen
                                  : AppColors.error),
                      ),
                  ],
                  actions: [
                    DetailHeaderAction(
                      icon: Icons.edit_outlined,
                      label: l10n.editButton,
                      onPressed: () =>
                          context.push('/goals/form?id=${goal.id}'),
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
                          MilestoneBadges(
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
                                color: AppColors.pureWhite.withValues(
                                  alpha: 0.9,
                                ),
                              ),
                            ),
                            Text(
                              progress.percent.asPercent(
                                locale: context.locale,
                              ),
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
                                color: AppColors.pureWhite.withValues(
                                  alpha: 0.1,
                                ),
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
                        GoalProgressChart(
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
                ref.read(GoalDomainProvider.service).deleteGoal(widget.goal.id),
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
