import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/list/infinite_list_view.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/core/widgets/loading_modal.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_list_item.dart';
import 'package:funances/features/goal/domain/models/goal_model.dart';
import 'package:funances/features/goal/presentation/provider.dart';
import 'package:funances/l10n/app_localizations.dart';
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

  @override
  Widget build(BuildContext context) {
    final goalAsync = ref.watch(GoalViewProvider.goalById(widget.goalId));
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

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.goalDetailsTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push('/goals/form', extra: goal),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _showDeleteConfirmation(context),
              ),
            ],
          ),
          body: _buildContent(context, goal, l10n, theme),
        );
      },
      error: (e, __) => Scaffold(
        appBar: AppBar(title: Text(l10n.goalDetailsTitle)),
        body: Center(child: Text(e.toString())),
      ),
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.goalDetailsTitle)),
        body: const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    GoalModel goal,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final progress = goal.calculateProgress();
    final locale = context.locale;

    return Column(
      children: [
        // Header de Progresso
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(bottom: BorderSide(color: theme.dividerColor)),
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 120,
                    width: 120,
                    child: CircularProgressIndicator(
                      value: progress.percent,
                      strokeWidth: 10,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      color: _getStatusColor(progress.status),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${(progress.percent * 100).toInt()}%",
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        l10n.goalProgressPercent("").split(" ").first,
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoItem(
                    goal.targetAmount.asCurrency(locale: locale),
                    l10n.goalTargetAmountLabel,
                    theme,
                  ),
                  _buildInfoItem(
                    DateFormat.yMMMd(locale).format(goal.deadline),
                    l10n.goalDeadlineLabel,
                    theme,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Listagem de Transações
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  l10n.goalTransactionsTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_query != null)
                Expanded(
                  child: InfiniteListView.separator(
                    FinanceViewProviders.goalTransactions(_query!),
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, item) => TransactionListItem(
                      installment: item,
                      notifier: ref.read(
                        FinanceViewProviders.goalTransactions(_query!).notifier,
                      ),
                    ),
                    separatorBuilder: (context, before, after) {
                      final bool isSameGroup = before != null &&
                          after != null &&
                          _isSameDay(before.referenceDate, after.referenceDate);

                      final showHeader =
                          after != null && (before == null || !isSameGroup);

                      if (showHeader) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (before != null) const Divider(height: 1),
                            _buildDateHeader(context, after.referenceDate, l10n),
                          ],
                        );
                      }

                      return const Divider(height: 1);
                    },
                    emptyStateBuilder: (context) => Center(
                      child: Text(l10n.noTransactionsInPeriod),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Widget _buildDateHeader(
    BuildContext context,
    DateTime date,
    AppLocalizations l10n,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    String dateText;
    if (checkDate == today) {
      dateText = l10n.today;
    } else if (checkDate == yesterday) {
      dateText = l10n.yesterday;
    } else {
      dateText = DateFormat.yMMMMd(
        Localizations.localeOf(context).toString(),
      ).format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        dateText,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildInfoItem(String value, String label, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(GoalStatus status) {
    switch (status) {
      case GoalStatus.onTrack:
        return AppColors.limeGreen;
      case GoalStatus.atRisk:
        return AppColors.antiqueGold;
      case GoalStatus.behind:
        return AppColors.error;
      case GoalStatus.lost:
        return Colors.grey;
    }
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
            child: Text(l10n.onboardingBack),
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
              l10n.goalDeleteButton,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
