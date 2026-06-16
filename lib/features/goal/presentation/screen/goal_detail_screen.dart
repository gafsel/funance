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
import 'package:funances/features/goal/presentation/providers/goal_providers.dart';
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

        final accountId = goal.mapOrNull(
          saveMoney: (g) => g.accountId,
          reduceCreditCard: (g) => g.accountId,
          payDebt: (g) => g.accountId,
        );

        final accountAsync = accountId != null
            ? ref.watch(AccountViewProviders.byId(accountId))
            : const AsyncValue<AccountModel?>.data(null);

        final accountLogo = accountAsync.when(
          data: (account) => account != null ? AccountLogo(account: account, size: 40) : null,
          loading: () => null,
          error: (_, __) => null,
        );

        final accountColor = accountAsync.when(
          data: (account) => account?.color.asColor() ?? AppColors.deepTurquoise,
          loading: () => AppColors.deepTurquoise,
          error: (_, __) => AppColors.deepTurquoise,
        );

        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              final progress = ref.watch(goalProgressProvider(goal));
              return [
                SliverDetailHeader(
                  title: goal.name,
                  subtitle: goal.targetAmount.asCurrency(locale: context.locale),
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
                    reduceExpense: (re) => CategoryIcon.forCategory(re.category),
                  ),
                  expandedHeight: 360,
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
                  ],
                  actions: [
                    DetailHeaderAction(
                      icon: Icons.edit_outlined,
                      label: l10n.editButton,
                      onPressed: () => context.push('/goals/form', extra: goal),
                    ),
                    DetailHeaderAction(
                      icon: Icons.delete_outline,
                      label: l10n.deleteButton,
                      onPressed: () => _showDeleteConfirmation(context),
                    ),
                  ],
                  bottomContent: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.goalCurrentAmountLabel,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: AppColors.pureWhite.withValues(alpha: 0.9),
                              ),
                            ),
                            Text(
                              progress.percent.asPercent(locale: context.locale),
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
                                color: AppColors.pureWhite.withValues(alpha: 0.1),
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
              l10n.deleteButton,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
