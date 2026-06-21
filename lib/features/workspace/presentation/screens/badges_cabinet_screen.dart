import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class BadgeItem {
  final String id;
  final IconData icon;
  final String xpReward;
  final Color themeColor;

  const BadgeItem({
    required this.id,
    required this.icon,
    required this.xpReward,
    required this.themeColor,
  });
}

const List<BadgeItem> allBadges = [
  BadgeItem(
    id: 'first_step',
    icon: Icons.rocket_launch,
    xpReward: '+100 XP',
    themeColor: Colors.deepPurple,
  ),
  BadgeItem(
    id: 'first_account',
    icon: Icons.account_balance,
    xpReward: '+150 XP',
    themeColor: Colors.blue,
  ),
  BadgeItem(
    id: 'first_transaction',
    icon: Icons.add_circle,
    xpReward: '+150 XP',
    themeColor: Colors.green,
  ),
  BadgeItem(
    id: 'planner',
    icon: Icons.assignment,
    xpReward: '+200 XP',
    themeColor: Colors.orange,
  ),
  BadgeItem(
    id: 'reconcile_junior',
    icon: Icons.point_of_sale,
    xpReward: '+300 XP',
    themeColor: Colors.teal,
  ),
  BadgeItem(
    id: 'cash_detective',
    icon: Icons.fact_check,
    xpReward: '+500 XP',
    themeColor: Colors.indigo,
  ),
  BadgeItem(
    id: 'reconcile_master',
    icon: Icons.workspace_premium,
    xpReward: '+1000 XP',
    themeColor: Colors.amber,
  ),
  BadgeItem(
    id: 'zero_friction',
    icon: Icons.bolt,
    xpReward: '+800 XP',
    themeColor: Colors.yellow,
  ),
  BadgeItem(
    id: 'savings_seed',
    icon: Icons.savings,
    xpReward: '+500 XP',
    themeColor: Colors.pink,
  ),
  BadgeItem(
    id: 'goal_bronze',
    icon: Icons.military_tech,
    xpReward: '+1000 XP',
    themeColor: Colors.brown,
  ),
  BadgeItem(
    id: 'goal_silver',
    icon: Icons.stars,
    xpReward: '+2000 XP',
    themeColor: Colors.purple,
  ),
  BadgeItem(
    id: 'emergency_shield',
    icon: Icons.shield,
    xpReward: '+800 XP',
    themeColor: Colors.red,
  ),
  BadgeItem(
    id: 'under_control',
    icon: Icons.check_circle,
    xpReward: '+1500 XP',
    themeColor: Colors.cyan,
  ),
  BadgeItem(
    id: 'golden_rule',
    icon: Icons.pie_chart,
    xpReward: '+1200 XP',
    themeColor: Colors.lightGreen,
  ),
  BadgeItem(
    id: 'future_focus',
    icon: Icons.trending_up,
    xpReward: '+1000 XP',
    themeColor: Colors.blueAccent,
  ),
  BadgeItem(
    id: 'cost_cutter',
    icon: Icons.content_cut,
    xpReward: '+800 XP',
    themeColor: Colors.deepOrange,
  ),
  BadgeItem(
    id: 'dynamic_duo',
    icon: Icons.people,
    xpReward: '+400 XP',
    themeColor: Colors.lightBlue,
  ),
  BadgeItem(
    id: 'united_front',
    icon: Icons.groups,
    xpReward: '+600 XP',
    themeColor: Colors.purple,
  ),
  BadgeItem(
    id: 'financial_synapsis',
    icon: Icons.hub,
    xpReward: '+800 XP',
    themeColor: Colors.pink,
  ),
  BadgeItem(
    id: 'iron_consistency',
    icon: Icons.calendar_month,
    xpReward: '+2500 XP',
    themeColor: Colors.redAccent,
  ),
];

String getBadgeName(BuildContext context, String id) {
  final l10n = AppLocalizations.of(context)!;
  switch (id) {
    case 'first_step': return l10n.badge_first_step_name;
    case 'first_account': return l10n.badge_first_account_name;
    case 'first_transaction': return l10n.badge_first_transaction_name;
    case 'planner': return l10n.badge_planner_name;
    case 'reconcile_junior': return l10n.badge_reconcile_junior_name;
    case 'cash_detective': return l10n.badge_cash_detective_name;
    case 'reconcile_master': return l10n.badge_reconcile_master_name;
    case 'zero_friction': return l10n.badge_zero_friction_name;
    case 'savings_seed': return l10n.badge_savings_seed_name;
    case 'goal_bronze': return l10n.badge_goal_bronze_name;
    case 'goal_silver': return l10n.badge_goal_silver_name;
    case 'emergency_shield': return l10n.badge_emergency_shield_name;
    case 'under_control': return l10n.badge_under_control_name;
    case 'golden_rule': return l10n.badge_golden_rule_name;
    case 'future_focus': return l10n.badge_future_focus_name;
    case 'cost_cutter': return l10n.badge_cost_cutter_name;
    case 'dynamic_duo': return l10n.badge_dynamic_duo_name;
    case 'united_front': return l10n.badge_united_front_name;
    case 'financial_synapsis': return l10n.badge_financial_synapsis_name;
    case 'iron_consistency': return l10n.badge_iron_consistency_name;
    default: return '';
  }
}

String getBadgeDescription(BuildContext context, String id) {
  final l10n = AppLocalizations.of(context)!;
  switch (id) {
    case 'first_step': return l10n.badge_first_step_desc;
    case 'first_account': return l10n.badge_first_account_desc;
    case 'first_transaction': return l10n.badge_first_transaction_desc;
    case 'planner': return l10n.badge_planner_desc;
    case 'reconcile_junior': return l10n.badge_reconcile_junior_desc;
    case 'cash_detective': return l10n.badge_cash_detective_desc;
    case 'reconcile_master': return l10n.badge_reconcile_master_desc;
    case 'zero_friction': return l10n.badge_zero_friction_desc;
    case 'savings_seed': return l10n.badge_savings_seed_desc;
    case 'goal_bronze': return l10n.badge_goal_bronze_desc;
    case 'goal_silver': return l10n.badge_goal_silver_desc;
    case 'emergency_shield': return l10n.badge_emergency_shield_desc;
    case 'under_control': return l10n.badge_under_control_desc;
    case 'golden_rule': return l10n.badge_golden_rule_desc;
    case 'future_focus': return l10n.badge_future_focus_desc;
    case 'cost_cutter': return l10n.badge_cost_cutter_desc;
    case 'dynamic_duo': return l10n.badge_dynamic_duo_desc;
    case 'united_front': return l10n.badge_united_front_desc;
    case 'financial_synapsis': return l10n.badge_financial_synapsis_desc;
    case 'iron_consistency': return l10n.badge_iron_consistency_desc;
    default: return '';
  }
}

class BadgesCabinetScreen extends ConsumerWidget {
  const BadgesCabinetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final workspaceState = ref.watch(WorkspaceViewProviders.workspace);
    final workspace = workspaceState.currentWorkspace;

    if (workspace == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final level = workspace.level;
    final xp = workspace.xp;
    
    // Level progress calculations
    final xpAcumuladoPrev = (300 * (pow(2, level - 1) - 1)).toInt();
    final xpAtual = xp - xpAcumuladoPrev;
    final xpDegrau = (300 * pow(2, level - 1)).toInt();
    final progressFraction = xpDegrau > 0 ? (xpAtual / xpDegrau).clamp(0.0, 1.0) : 0.0;
    
    final unlockedBadges = workspace.unlockedBadges;
    final unlockedCount = unlockedBadges.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.teamAchievementsTitle),
        elevation: 0,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header Card with progress
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.workspaceLabel(workspace.name),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.levelLabel(level),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.military_tech,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$unlockedCount / ${allBadges.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$xpAtual / $xpDegrau XP',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            l10n.totalXpLabel(xp.toString()),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progressFraction,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          minHeight: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (workspace.weeklyStreaks > 0)
                        Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department,
                              color: Colors.orangeAccent,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              workspace.weeklyStreaks == 1
                                  ? l10n.weeklyStreaksLabelSingular
                                  : l10n.weeklyStreaksLabelPlural(workspace.weeklyStreaks),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Section Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Text(
                l10n.yourBadgesLabel,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // Badges Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 130,
                mainAxisSpacing: 16.0,
                crossAxisSpacing: 16.0,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final badge = allBadges[index];
                  final unlockDateStr = unlockedBadges[badge.id];
                  final isUnlocked = unlockDateStr != null;
                  
                  final badgeName = getBadgeName(context, badge.id);
                  final badgeDesc = getBadgeDescription(context, badge.id);

                  return GestureDetector(
                    onTap: () => _showBadgeDetail(context, badge, unlockDateStr, badgeName, badgeDesc),
                    child: Card(
                      elevation: isUnlocked ? 2 : 0.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isUnlocked
                              ? badge.themeColor.withValues(alpha: 0.3)
                              : Colors.grey.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: isUnlocked
                              ? badge.themeColor.withValues(alpha: 0.05)
                              : Colors.grey.withValues(alpha: 0.05),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isUnlocked
                                    ? badge.themeColor.withValues(alpha: 0.15)
                                    : Colors.grey.withValues(alpha: 0.15),
                              ),
                              child: Icon(
                                badge.icon,
                                color: isUnlocked
                                    ? badge.themeColor
                                    : Colors.grey.shade500,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              badgeName,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isUnlocked
                                    ? Theme.of(context).textTheme.bodyLarge?.color
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: allBadges.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }

  void _showBadgeDetail(
    BuildContext context,
    BadgeItem badge,
    String? unlockDateStr,
    String badgeName,
    String badgeDesc,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final isUnlocked = unlockDateStr != null;
    DateTime? unlockDate;
    if (unlockDateStr != null) {
      try {
        unlockDate = DateTime.parse(unlockDateStr);
      } catch (_) {}
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bottom sheet handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isUnlocked
                      ? badge.themeColor.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.15),
                ),
                child: Icon(
                  badge.icon,
                  color: isUnlocked ? badge.themeColor : Colors.grey,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                badgeName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isUnlocked ? l10n.badgeUnlockedLabel : l10n.badgeLockedLabel,
                  style: TextStyle(
                    color: isUnlocked ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                badgeDesc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              Divider(color: Colors.grey.shade200),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        l10n.badgeRewardLabel,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        badge.xpReward,
                        style: TextStyle(
                          color: badge.themeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  if (isUnlocked && unlockDate != null)
                    Column(
                      children: [
                        Text(
                          l10n.badgeUnlockedAtLabel,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(unlockDate.toLocal()),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
