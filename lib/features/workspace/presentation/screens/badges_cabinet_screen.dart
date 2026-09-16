import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────

enum BadgeTier { advanced, simple }

enum SimpleBadgeGroup {
  firstSteps,
  consistency,
  savings,
  goals,
  team,
}

class BadgeItem {
  final String id;
  final IconData icon;
  final String xpReward;
  final Color themeColor;
  final BadgeTier tier;

  const BadgeItem({
    required this.id,
    required this.icon,
    required this.xpReward,
    required this.themeColor,
    required this.tier,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Advanced badges (20) — rich visuals, gold borders when unlocked
// ─────────────────────────────────────────────────────────────────────────────

const List<BadgeItem> advancedBadges = [
  BadgeItem(id: 'first_step', icon: Icons.rocket_launch, xpReward: '+100 XP', themeColor: Colors.deepPurple, tier: BadgeTier.advanced),
  BadgeItem(id: 'first_account', icon: Icons.account_balance, xpReward: '+150 XP', themeColor: Colors.blue, tier: BadgeTier.advanced),
  BadgeItem(id: 'first_transaction', icon: Icons.add_circle, xpReward: '+150 XP', themeColor: Colors.green, tier: BadgeTier.advanced),
  BadgeItem(id: 'planner', icon: Icons.assignment, xpReward: '+200 XP', themeColor: Colors.orange, tier: BadgeTier.advanced),
  BadgeItem(id: 'reconcile_junior', icon: Icons.point_of_sale, xpReward: '+300 XP', themeColor: Colors.teal, tier: BadgeTier.advanced),
  BadgeItem(id: 'cash_detective', icon: Icons.fact_check, xpReward: '+500 XP', themeColor: Colors.indigo, tier: BadgeTier.advanced),
  BadgeItem(id: 'reconcile_master', icon: Icons.workspace_premium, xpReward: '+1000 XP', themeColor: Colors.amber, tier: BadgeTier.advanced),
  BadgeItem(id: 'zero_friction', icon: Icons.bolt, xpReward: '+800 XP', themeColor: Colors.yellow, tier: BadgeTier.advanced),
  BadgeItem(id: 'savings_seed', icon: Icons.savings, xpReward: '+500 XP', themeColor: Colors.pink, tier: BadgeTier.advanced),
  BadgeItem(id: 'goal_bronze', icon: Icons.military_tech, xpReward: '+1000 XP', themeColor: Colors.brown, tier: BadgeTier.advanced),
  BadgeItem(id: 'goal_silver', icon: Icons.stars, xpReward: '+2000 XP', themeColor: Colors.purple, tier: BadgeTier.advanced),
  BadgeItem(id: 'under_control', icon: Icons.check_circle, xpReward: '+1500 XP', themeColor: Colors.cyan, tier: BadgeTier.advanced),
  BadgeItem(id: 'golden_rule', icon: Icons.pie_chart, xpReward: '+1200 XP', themeColor: Colors.lightGreen, tier: BadgeTier.advanced),
  BadgeItem(id: 'future_focus', icon: Icons.trending_up, xpReward: '+1000 XP', themeColor: Colors.blueAccent, tier: BadgeTier.advanced),
  BadgeItem(id: 'cost_cutter', icon: Icons.content_cut, xpReward: '+800 XP', themeColor: Colors.deepOrange, tier: BadgeTier.advanced),
  BadgeItem(id: 'united_front', icon: Icons.groups, xpReward: '+600 XP', themeColor: Colors.purple, tier: BadgeTier.advanced),
  BadgeItem(id: 'iron_consistency', icon: Icons.calendar_month, xpReward: '+2500 XP', themeColor: Colors.redAccent, tier: BadgeTier.advanced),
];

// ─────────────────────────────────────────────────────────────────────────────
// Simple badges (50) — compact sticker-like visuals
// ─────────────────────────────────────────────────────────────────────────────

const List<BadgeItem> simpleBadges = [
  // Primeiros Passos
  BadgeItem(id: 'first_category', icon: Icons.label, xpReward: '+25 XP', themeColor: Color(0xFF7C4DFF), tier: BadgeTier.simple),
  BadgeItem(id: 'first_planning', icon: Icons.event_note, xpReward: '+50 XP', themeColor: Color(0xFF00BCD4), tier: BadgeTier.simple),
  BadgeItem(id: 'first_goal', icon: Icons.flag, xpReward: '+50 XP', themeColor: Color(0xFF4CAF50), tier: BadgeTier.simple),
  BadgeItem(id: 'first_invite', icon: Icons.person_add, xpReward: '+75 XP', themeColor: Color(0xFF2196F3), tier: BadgeTier.simple),
  BadgeItem(id: 'profile_complete', icon: Icons.verified, xpReward: '+25 XP', themeColor: Color(0xFF009688), tier: BadgeTier.simple),
  BadgeItem(id: 'first_income', icon: Icons.south_east, xpReward: '+50 XP', themeColor: Color(0xFF43A047), tier: BadgeTier.simple),
  BadgeItem(id: 'first_expense', icon: Icons.north_west, xpReward: '+50 XP', themeColor: Color(0xFFE53935), tier: BadgeTier.simple),
  BadgeItem(id: 'first_transfer', icon: Icons.swap_horiz, xpReward: '+50 XP', themeColor: Color(0xFF1976D2), tier: BadgeTier.simple),
  BadgeItem(id: 'workspace_named', icon: Icons.edit, xpReward: '+25 XP', themeColor: Color(0xFF5E35B1), tier: BadgeTier.simple),
  BadgeItem(id: 'first_month', icon: Icons.calendar_today, xpReward: '+75 XP', themeColor: Color(0xFF00897B), tier: BadgeTier.simple),
  // Registro Consistente
  BadgeItem(id: 'five_transactions', icon: Icons.flash_on, xpReward: '+50 XP', themeColor: Color(0xFFFDD835), tier: BadgeTier.simple),
  BadgeItem(id: 'twenty_transactions', icon: Icons.trending_up, xpReward: '+75 XP', themeColor: Color(0xFF66BB6A), tier: BadgeTier.simple),
  BadgeItem(id: 'fifty_transactions', icon: Icons.workspace_premium, xpReward: '+100 XP', themeColor: Color(0xFFAB47BC), tier: BadgeTier.simple),
  BadgeItem(id: 'hundred_transactions', icon: Icons.emoji_events, xpReward: '+150 XP', themeColor: Color(0xFFFFB300), tier: BadgeTier.simple),
  BadgeItem(id: 'week_complete', icon: Icons.date_range, xpReward: '+100 XP', themeColor: Color(0xFF0288D1), tier: BadgeTier.simple),
  BadgeItem(id: 'two_accounts', icon: Icons.account_balance_wallet, xpReward: '+50 XP', themeColor: Color(0xFF00ACC1), tier: BadgeTier.simple),
  BadgeItem(id: 'three_accounts', icon: Icons.dashboard, xpReward: '+75 XP', themeColor: Color(0xFF7986CB), tier: BadgeTier.simple),
  BadgeItem(id: 'five_accounts', icon: Icons.business_center, xpReward: '+100 XP', themeColor: Color(0xFF26A69A), tier: BadgeTier.simple),
  BadgeItem(id: 'five_categories', icon: Icons.category, xpReward: '+50 XP', themeColor: Color(0xFFEC407A), tier: BadgeTier.simple),
  BadgeItem(id: 'ten_categories', icon: Icons.workspaces, xpReward: '+75 XP', themeColor: Color(0xFF8D6E63), tier: BadgeTier.simple),
  // Gastos e Economias
  BadgeItem(id: 'round_number', icon: Icons.radio_button_checked, xpReward: '+25 XP', themeColor: Color(0xFF78909C), tier: BadgeTier.simple),
  BadgeItem(id: 'big_transaction', icon: Icons.payments, xpReward: '+75 XP', themeColor: Color(0xFFF57C00), tier: BadgeTier.simple),
  BadgeItem(id: 'small_transactions_ten', icon: Icons.grain, xpReward: '+75 XP', themeColor: Color(0xFF9CCC65), tier: BadgeTier.simple),
  BadgeItem(id: 'income_registered', icon: Icons.receipt_long, xpReward: '+50 XP', themeColor: Color(0xFF29B6F6), tier: BadgeTier.simple),
  BadgeItem(id: 'expense_under_income', icon: Icons.balance, xpReward: '+100 XP', themeColor: Color(0xFF26C6DA), tier: BadgeTier.simple),
  BadgeItem(id: 'three_categories_month', icon: Icons.donut_small, xpReward: '+75 XP', themeColor: Color(0xFFE91E63), tier: BadgeTier.simple),
  BadgeItem(id: 'five_categories_month', icon: Icons.donut_large, xpReward: '+100 XP', themeColor: Color(0xFF9C27B0), tier: BadgeTier.simple),
  BadgeItem(id: 'savings_10pct', icon: Icons.percent, xpReward: '+100 XP', themeColor: Color(0xFF43A047), tier: BadgeTier.simple),
  BadgeItem(id: 'savings_start', icon: Icons.monetization_on, xpReward: '+75 XP', themeColor: Color(0xFFFFCA28), tier: BadgeTier.simple),
  BadgeItem(id: 'no_credit_debt', icon: Icons.credit_score, xpReward: '+75 XP', themeColor: Color(0xFF00897B), tier: BadgeTier.simple),
  // Metas
  BadgeItem(id: 'goal_halfway', icon: Icons.looks_two, xpReward: '+50 XP', themeColor: Color(0xFF5C6BC0), tier: BadgeTier.simple),
  BadgeItem(id: 'goal_75pct', icon: Icons.looks_3, xpReward: '+75 XP', themeColor: Color(0xFF8E24AA), tier: BadgeTier.simple),
  BadgeItem(id: 'goal_under_deadline', icon: Icons.timer, xpReward: '+100 XP', themeColor: Color(0xFFE64A19), tier: BadgeTier.simple),
  BadgeItem(id: 'two_active_goals', icon: Icons.offline_bolt, xpReward: '+50 XP', themeColor: Color(0xFFF9A825), tier: BadgeTier.simple),
  BadgeItem(id: 'five_active_goals', icon: Icons.dynamic_feed, xpReward: '+100 XP', themeColor: Color(0xFF0097A7), tier: BadgeTier.simple),
  BadgeItem(id: 'long_term_goal', icon: Icons.public, xpReward: '+75 XP', themeColor: Color(0xFF1E88E5), tier: BadgeTier.simple),
  BadgeItem(id: 'short_term_goal', icon: Icons.bolt, xpReward: '+75 XP', themeColor: Color(0xFFFF7043), tier: BadgeTier.simple),
  BadgeItem(id: 'goal_deposit', icon: Icons.add_card, xpReward: '+50 XP', themeColor: Color(0xFF00BFA5), tier: BadgeTier.simple),
  BadgeItem(id: 'goal_debt_paid', icon: Icons.free_cancellation, xpReward: '+150 XP', themeColor: Color(0xFF388E3C), tier: BadgeTier.simple),
  BadgeItem(id: 'goal_linked_account', icon: Icons.link, xpReward: '+50 XP', themeColor: Color(0xFF6D4C41), tier: BadgeTier.simple),
  // Equipe e Consistência
  BadgeItem(id: 'second_member', icon: Icons.group_add, xpReward: '+50 XP', themeColor: Color(0xFF039BE5), tier: BadgeTier.simple),
  BadgeItem(id: 'reconcile_second', icon: Icons.refresh, xpReward: '+75 XP', themeColor: Color(0xFF00796B), tier: BadgeTier.simple),
  BadgeItem(id: 'reconcile_five', icon: Icons.sync_alt, xpReward: '+100 XP', themeColor: Color(0xFF0288D1), tier: BadgeTier.simple),
  BadgeItem(id: 'mission_first', icon: Icons.task_alt, xpReward: '+75 XP', themeColor: Color(0xFF558B2F), tier: BadgeTier.simple),
  BadgeItem(id: 'mission_three', icon: Icons.sports_score, xpReward: '+100 XP', themeColor: Color(0xFFD81B60), tier: BadgeTier.simple),
  BadgeItem(id: 'planning_month', icon: Icons.event_available, xpReward: '+75 XP', themeColor: Color(0xFF7B1FA2), tier: BadgeTier.simple),
  BadgeItem(id: 'two_months_active', icon: Icons.repeat, xpReward: '+100 XP', themeColor: Color(0xFF00695C), tier: BadgeTier.simple),
  BadgeItem(id: 'workspace_one_year', icon: Icons.cake, xpReward: '+150 XP', themeColor: Color(0xFFE040FB), tier: BadgeTier.simple),
  BadgeItem(id: 'invite_accepted', icon: Icons.waving_hand, xpReward: '+50 XP', themeColor: Color(0xFFF4511E), tier: BadgeTier.simple),
  BadgeItem(id: 'all_missions_week', icon: Icons.star, xpReward: '+100 XP', themeColor: Color(0xFFFFD600), tier: BadgeTier.simple),
];

const List<BadgeItem> allBadges = [...advancedBadges, ...simpleBadges];

// ─────────────────────────────────────────────────────────────────────────────
// L10n helpers
// ─────────────────────────────────────────────────────────────────────────────

String getBadgeName(BuildContext context, String id) {
  final l10n = AppLocalizations.of(context)!;
  switch (id) {
    // Advanced
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
    case 'under_control': return l10n.badge_under_control_name;
    case 'golden_rule': return l10n.badge_golden_rule_name;
    case 'future_focus': return l10n.badge_future_focus_name;
    case 'cost_cutter': return l10n.badge_cost_cutter_name;
    case 'united_front': return l10n.badge_united_front_name;
    case 'iron_consistency': return l10n.badge_iron_consistency_name;
    // Simple — Primeiros Passos
    case 'first_category': return l10n.badge_first_category_name;
    case 'first_planning': return l10n.badge_first_planning_name;
    case 'first_goal': return l10n.badge_first_goal_name;
    case 'first_invite': return l10n.badge_first_invite_name;
    case 'profile_complete': return l10n.badge_profile_complete_name;
    case 'first_income': return l10n.badge_first_income_name;
    case 'first_expense': return l10n.badge_first_expense_name;
    case 'first_transfer': return l10n.badge_first_transfer_name;
    case 'workspace_named': return l10n.badge_workspace_named_name;
    case 'first_month': return l10n.badge_first_month_name;
    // Simple — Registro Consistente
    case 'five_transactions': return l10n.badge_five_transactions_name;
    case 'twenty_transactions': return l10n.badge_twenty_transactions_name;
    case 'fifty_transactions': return l10n.badge_fifty_transactions_name;
    case 'hundred_transactions': return l10n.badge_hundred_transactions_name;
    case 'week_complete': return l10n.badge_week_complete_name;
    case 'two_accounts': return l10n.badge_two_accounts_name;
    case 'three_accounts': return l10n.badge_three_accounts_name;
    case 'five_accounts': return l10n.badge_five_accounts_name;
    case 'five_categories': return l10n.badge_five_categories_name;
    case 'ten_categories': return l10n.badge_ten_categories_name;
    // Simple — Gastos e Economias
    case 'round_number': return l10n.badge_round_number_name;
    case 'big_transaction': return l10n.badge_big_transaction_name;
    case 'small_transactions_ten': return l10n.badge_small_transactions_ten_name;
    case 'income_registered': return l10n.badge_income_registered_name;
    case 'expense_under_income': return l10n.badge_expense_under_income_name;
    case 'three_categories_month': return l10n.badge_three_categories_month_name;
    case 'five_categories_month': return l10n.badge_five_categories_month_name;
    case 'savings_10pct': return l10n.badge_savings_10pct_name;
    case 'savings_start': return l10n.badge_savings_start_name;
    case 'no_credit_debt': return l10n.badge_no_credit_debt_name;
    // Simple — Metas
    case 'goal_halfway': return l10n.badge_goal_halfway_name;
    case 'goal_75pct': return l10n.badge_goal_75pct_name;
    case 'goal_under_deadline': return l10n.badge_goal_under_deadline_name;
    case 'two_active_goals': return l10n.badge_two_active_goals_name;
    case 'five_active_goals': return l10n.badge_five_active_goals_name;
    case 'long_term_goal': return l10n.badge_long_term_goal_name;
    case 'short_term_goal': return l10n.badge_short_term_goal_name;
    case 'goal_deposit': return l10n.badge_goal_deposit_name;
    case 'goal_debt_paid': return l10n.badge_goal_debt_paid_name;
    case 'goal_linked_account': return l10n.badge_goal_linked_account_name;
    // Simple — Equipe
    case 'second_member': return l10n.badge_second_member_name;
    case 'reconcile_second': return l10n.badge_reconcile_second_name;
    case 'reconcile_five': return l10n.badge_reconcile_five_name;
    case 'mission_first': return l10n.badge_mission_first_name;
    case 'mission_three': return l10n.badge_mission_three_name;
    case 'planning_month': return l10n.badge_planning_month_name;
    case 'two_months_active': return l10n.badge_two_months_active_name;
    case 'workspace_one_year': return l10n.badge_workspace_one_year_name;
    case 'invite_accepted': return l10n.badge_invite_accepted_name;
    case 'all_missions_week': return l10n.badge_all_missions_week_name;
    default: return id;
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
    case 'under_control': return l10n.badge_under_control_desc;
    case 'golden_rule': return l10n.badge_golden_rule_desc;
    case 'future_focus': return l10n.badge_future_focus_desc;
    case 'cost_cutter': return l10n.badge_cost_cutter_desc;
    case 'united_front': return l10n.badge_united_front_desc;
    case 'iron_consistency': return l10n.badge_iron_consistency_desc;
    case 'first_category': return l10n.badge_first_category_desc;
    case 'first_planning': return l10n.badge_first_planning_desc;
    case 'first_goal': return l10n.badge_first_goal_desc;
    case 'first_invite': return l10n.badge_first_invite_desc;
    case 'profile_complete': return l10n.badge_profile_complete_desc;
    case 'first_income': return l10n.badge_first_income_desc;
    case 'first_expense': return l10n.badge_first_expense_desc;
    case 'first_transfer': return l10n.badge_first_transfer_desc;
    case 'workspace_named': return l10n.badge_workspace_named_desc;
    case 'first_month': return l10n.badge_first_month_desc;
    case 'five_transactions': return l10n.badge_five_transactions_desc;
    case 'twenty_transactions': return l10n.badge_twenty_transactions_desc;
    case 'fifty_transactions': return l10n.badge_fifty_transactions_desc;
    case 'hundred_transactions': return l10n.badge_hundred_transactions_desc;
    case 'week_complete': return l10n.badge_week_complete_desc;
    case 'two_accounts': return l10n.badge_two_accounts_desc;
    case 'three_accounts': return l10n.badge_three_accounts_desc;
    case 'five_accounts': return l10n.badge_five_accounts_desc;
    case 'five_categories': return l10n.badge_five_categories_desc;
    case 'ten_categories': return l10n.badge_ten_categories_desc;
    case 'round_number': return l10n.badge_round_number_desc;
    case 'big_transaction': return l10n.badge_big_transaction_desc;
    case 'small_transactions_ten': return l10n.badge_small_transactions_ten_desc;
    case 'income_registered': return l10n.badge_income_registered_desc;
    case 'expense_under_income': return l10n.badge_expense_under_income_desc;
    case 'three_categories_month': return l10n.badge_three_categories_month_desc;
    case 'five_categories_month': return l10n.badge_five_categories_month_desc;
    case 'savings_10pct': return l10n.badge_savings_10pct_desc;
    case 'savings_start': return l10n.badge_savings_start_desc;
    case 'no_credit_debt': return l10n.badge_no_credit_debt_desc;
    case 'goal_halfway': return l10n.badge_goal_halfway_desc;
    case 'goal_75pct': return l10n.badge_goal_75pct_desc;
    case 'goal_under_deadline': return l10n.badge_goal_under_deadline_desc;
    case 'two_active_goals': return l10n.badge_two_active_goals_desc;
    case 'five_active_goals': return l10n.badge_five_active_goals_desc;
    case 'long_term_goal': return l10n.badge_long_term_goal_desc;
    case 'short_term_goal': return l10n.badge_short_term_goal_desc;
    case 'goal_deposit': return l10n.badge_goal_deposit_desc;
    case 'goal_debt_paid': return l10n.badge_goal_debt_paid_desc;
    case 'goal_linked_account': return l10n.badge_goal_linked_account_desc;
    case 'second_member': return l10n.badge_second_member_desc;
    case 'reconcile_second': return l10n.badge_reconcile_second_desc;
    case 'reconcile_five': return l10n.badge_reconcile_five_desc;
    case 'mission_first': return l10n.badge_mission_first_desc;
    case 'mission_three': return l10n.badge_mission_three_desc;
    case 'planning_month': return l10n.badge_planning_month_desc;
    case 'two_months_active': return l10n.badge_two_months_active_desc;
    case 'workspace_one_year': return l10n.badge_workspace_one_year_desc;
    case 'invite_accepted': return l10n.badge_invite_accepted_desc;
    case 'all_missions_week': return l10n.badge_all_missions_week_desc;
    default: return '';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class BadgesCabinetScreen extends ConsumerWidget {
  const BadgesCabinetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final workspaceState = ref.watch(WorkspaceViewProviders.workspace);
    final workspace = workspaceState.currentWorkspace;

    if (workspace == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final level = workspace.level;
    final xp = workspace.xp;
    final xpAcumuladoPrev = (300 * (pow(2, level - 1) - 1)).toInt();
    final xpAtual = xp - xpAcumuladoPrev;
    final xpDegrau = (300 * pow(2, level - 1)).toInt();
    final progressFraction = xpDegrau > 0 ? (xpAtual / xpDegrau).clamp(0.0, 1.0) : 0.0;

    final unlockedBadges = workspace.unlockedBadges;
    final unlockedAdvanced = advancedBadges.where((b) => unlockedBadges.containsKey(b.id)).length;
    final unlockedSimple = simpleBadges.where((b) => unlockedBadges.containsKey(b.id)).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.teamAchievementsTitle),
        elevation: 0,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header Card ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                  padding: const EdgeInsets.all(24),
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
                                style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.levelLabel(level),
                                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.military_tech, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  '${unlockedBadges.length} / ${allBadges.length}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            l10n.totalXpLabel(xp.toString()),
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progressFraction,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 12,
                        ),
                      ),
                      if (workspace.weeklyStreaks > 0) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.local_fire_department, color: Colors.orangeAccent),
                            const SizedBox(width: 8),
                            Text(
                              workspace.weeklyStreaks == 1
                                  ? l10n.weeklyStreaksLabelSingular
                                  : l10n.weeklyStreaksLabelPlural(workspace.weeklyStreaks),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Advanced Badges Section ───────────────────────────────────────
          SliverToBoxAdapter(
            child: _SectionHeader(
              icon: Icons.workspace_premium,
              label: l10n.advancedBadgesLabel,
              unlocked: unlockedAdvanced,
              total: advancedBadges.length,
              color: Colors.amber.shade700,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 130,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final badge = advancedBadges[index];
                  final unlockDateStr = unlockedBadges[badge.id];
                  final isUnlocked = unlockDateStr != null;
                  return _AdvancedBadgeCard(
                    badge: badge,
                    isUnlocked: isUnlocked,
                    badgeName: getBadgeName(context, badge.id),
                    onTap: () => _showBadgeDetail(
                      context,
                      badge,
                      unlockDateStr,
                      getBadgeName(context, badge.id),
                      getBadgeDescription(context, badge.id),
                    ),
                  );
                },
                childCount: advancedBadges.length,
              ),
            ),
          ),

          // ── Simple Badges Section ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SectionHeader(
              icon: Icons.star,
              label: l10n.simpleBadgesLabel,
              unlocked: unlockedSimple,
              total: simpleBadges.length,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 68,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final badge = simpleBadges[index];
                  final unlockDateStr = unlockedBadges[badge.id];
                  final isUnlocked = unlockDateStr != null;
                  return _SimpleBadgeChip(
                    badge: badge,
                    isUnlocked: isUnlocked,
                    onTap: () => _showBadgeDetail(
                      context,
                      badge,
                      unlockDateStr,
                      getBadgeName(context, badge.id),
                      getBadgeDescription(context, badge.id),
                    ),
                  );
                },
                childCount: simpleBadges.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
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
      try { unlockDate = DateTime.parse(unlockDateStr); } catch (_) {}
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            BadgeShapeWidget(
              size: 96,
              tier: badge.tier,
              group: badge.tier == BadgeTier.simple ? getSimpleBadgeGroup(badge.id) : null,
              isUnlocked: true,
              xpRewardValue: getXpRewardValue(badge.xpReward),
              child: MetallicIcon3D(
                icon: badge.icon,
                size: 40,
                isUnlocked: true,
                tier: badge.tier,
                xpRewardValue: getXpRewardValue(badge.xpReward),
                themeColor: badge.themeColor,
              ),
            ),
            const SizedBox(height: 16),
            if (badge.tier == BadgeTier.simple)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: badge.themeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badge.themeColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  l10n.simpleBadgesLabel,
                  style: TextStyle(fontSize: 10, color: badge.themeColor, fontWeight: FontWeight.w600),
                ),
              ),
            Text(badgeName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                  fontWeight: FontWeight.bold, fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(badgeDesc,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(children: [
                  Text(l10n.badgeRewardLabel, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(badge.xpReward, style: TextStyle(
                    color: badge.themeColor, fontWeight: FontWeight.bold, fontSize: 18)),
                ]),
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
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final int unlocked;
  final int total;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.unlocked,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Text(
              '$unlocked / $total',
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvancedBadgeCard extends StatelessWidget {
  final BadgeItem badge;
  final bool isUnlocked;
  final String badgeName;
  final VoidCallback onTap;

  const _AdvancedBadgeCard({
    required this.badge,
    required this.isUnlocked,
    required this.badgeName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BadgeShapeWidget(
            size: 72,
            tier: BadgeTier.advanced,
            isUnlocked: isUnlocked,
            xpRewardValue: getXpRewardValue(badge.xpReward),
            child: MetallicIcon3D(
              icon: badge.icon,
              size: 30,
              isUnlocked: isUnlocked,
              tier: BadgeTier.advanced,
              xpRewardValue: getXpRewardValue(badge.xpReward),
              themeColor: badge.themeColor,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              badgeName,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isUnlocked
                    ? Theme.of(context).textTheme.bodyLarge?.color
                    : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleBadgeChip extends StatelessWidget {
  final BadgeItem badge;
  final bool isUnlocked;
  final VoidCallback onTap;

  const _SimpleBadgeChip({
    required this.badge,
    required this.isUnlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final group = getSimpleBadgeGroup(badge.id);
    final xpVal = getXpRewardValue(badge.xpReward);

    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: getBadgeName(context, badge.id),
        child: BadgeShapeWidget(
          size: 48,
          tier: BadgeTier.simple,
          group: group,
          isUnlocked: isUnlocked,
          xpRewardValue: xpVal,
          child: MetallicIcon3D(
            icon: badge.icon,
            size: 20,
            isUnlocked: isUnlocked,
            tier: BadgeTier.simple,
            xpRewardValue: xpVal,
            themeColor: badge.themeColor,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3D Metallic Emblem Icon
// ─────────────────────────────────────────────────────────────────────────────

Color _toGrayscale(Color color) {
  final double luminance = 0.299 * color.r + 0.587 * color.g + 0.114 * color.b;
  return Color.fromARGB(
    (color.a * 255).round().clamp(0, 255),
    (luminance * 255).round().clamp(0, 255),
    (luminance * 255).round().clamp(0, 255),
    (luminance * 255).round().clamp(0, 255),
  );
}

Gradient _makeGrayscale(Gradient gradient) {
  if (gradient is RadialGradient) {
    return RadialGradient(
      center: gradient.center,
      radius: gradient.radius,
      colors: gradient.colors.map(_toGrayscale).toList(),
      stops: gradient.stops,
    );
  } else if (gradient is LinearGradient) {
    return LinearGradient(
      begin: gradient.begin,
      end: gradient.end,
      colors: gradient.colors.map(_toGrayscale).toList(),
      stops: gradient.stops,
    );
  }
  return gradient;
}

Gradient _getMetallicGradientForColor(Color baseColor) {
  final hsl = HSLColor.fromColor(baseColor);
  final lightColor = hsl.withLightness((hsl.lightness + 0.35).clamp(0.0, 1.0)).toColor();
  final midColor = baseColor;
  final shadowColor = hsl.withLightness((hsl.lightness - 0.20).clamp(0.0, 1.0)).toColor();

  return LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      lightColor,
      midColor,
      shadowColor,
    ],
  );
}

class MetallicIcon3D extends StatelessWidget {
  final IconData icon;
  final double size;
  final bool isUnlocked;
  final BadgeTier tier;
  final int xpRewardValue;
  final Color themeColor;

  const MetallicIcon3D({
    super.key,
    required this.icon,
    required this.size,
    required this.isUnlocked,
    required this.tier,
    required this.xpRewardValue,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final double plateSize = size * 1.35;

    // Unlocked base colors and gradients
    Gradient activePlateGradient;
    Gradient activeIconGradient;
    Color activePlateBorderColor;

    if (tier == BadgeTier.advanced) {
      // Advanced: Platinum/Silver coin inside Gold Shield
      activePlateGradient = const RadialGradient(
        center: Alignment(-0.25, -0.25),
        radius: 0.85,
        colors: [
          Color(0xFFFFFFFF), // Specular shine
          Color(0xFFF1F5F9), // Platinum silver
          Color(0xFF94A3B8), // Slate silver
          Color(0xFF475569), // Steel shadow
        ],
        stops: [0.0, 0.25, 0.75, 1.0],
      );
      activePlateBorderColor = const Color(0xFFFFD54F); // Gold border to frame the coin
      activeIconGradient = _getMetallicGradientForColor(themeColor);
    } else if (xpRewardValue >= 75) {
      // Simple Silver Badge: Gold coin inside Silver Shape
      activePlateGradient = const RadialGradient(
        center: Alignment(-0.25, -0.25),
        radius: 0.85,
        colors: [
          Color(0xFFFFFDF0), // gold highlight
          Color(0xFFFBBF24), // gold body
          Color(0xFFCA8A04), // medium gold
          Color(0xFF713F12), // dark gold shadow
        ],
        stops: [0.0, 0.2, 0.7, 1.0],
      );
      activePlateBorderColor = const Color(0xFFCBD5E1); // Silver border
      activeIconGradient = _getMetallicGradientForColor(themeColor);
    } else {
      // Simple Bronze Badge: Silver/Steel coin inside Bronze Shape
      activePlateGradient = const RadialGradient(
        center: Alignment(-0.25, -0.25),
        radius: 0.85,
        colors: [
          Color(0xFFFFFFFF), // specular white
          Color(0xFFECEFF1), // silver
          Color(0xFF90A4AE), // medium steel
          Color(0xFF37474F), // dark steel shadow
        ],
        stops: [0.0, 0.2, 0.7, 1.0],
      );
      activePlateBorderColor = const Color(0xFFC2410C); // Bronze/Copper border
      activeIconGradient = _getMetallicGradientForColor(themeColor);
    }

    Gradient plateGradient;
    Gradient iconGradient;
    Color plateBorderColor;

    if (isUnlocked) {
      plateGradient = activePlateGradient;
      iconGradient = activeIconGradient;
      plateBorderColor = activePlateBorderColor;
    } else {
      // Locked: Grayscale version of the coin & high-contrast icon
      plateGradient = _makeGrayscale(activePlateGradient);
      // Use a dark slate gradient to stand out against the light/medium grayscale plate
      iconGradient = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF475569), // Slate 600
          Color(0xFF0F172A), // Slate 900 (very dark charcoal)
        ],
      );
      plateBorderColor = _toGrayscale(activePlateBorderColor);
    }

    return Container(
      width: plateSize,
      height: plateSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: plateGradient,
        border: Border.all(
          color: plateBorderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isUnlocked ? 0.35 : 0.20),
            offset: const Offset(1, 1.5),
            blurRadius: 1.5,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: isUnlocked ? 0.45 : 0.20),
            offset: const Offset(-0.75, -0.75),
            blurRadius: 0.5,
          ),
        ],
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // White highlights under the icon to create a debossed/engraved edge visibility when locked
            if (!isUnlocked)
              Transform.translate(
                offset: const Offset(-0.8, -0.8),
                child: Icon(
                  icon,
                  size: size,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            // Stamped drop shadow for the icon glyph
            Transform.translate(
              offset: const Offset(1.2, 1.2),
              child: Icon(
                icon,
                size: size,
                color: Colors.black.withValues(alpha: isUnlocked ? 0.45 : 0.50),
              ),
            ),
            // Metal icon stamp
            ShaderMask(
              shaderCallback: (bounds) => iconGradient.createShader(bounds),
              blendMode: BlendMode.srcIn,
              child: Icon(
                icon,
                size: size,
                color: Colors.white,
              ),
            ),
            // Specular glass glare reflection on top of the stamp (always visible)
            Opacity(
              opacity: isUnlocked ? 0.12 : 0.06,
              child: ClipPath(
                clipper: _CrescentClipper(),
                child: Container(
                  width: size,
                  height: size,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CrescentClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.addOval(Rect.fromLTWH(-size.width * 0.15, -size.height * 0.15, size.width * 1.3, size.height * 0.7));
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Badge Shapes & Painters
// ─────────────────────────────────────────────────────────────────────────────

class BadgeShapeWidget extends StatelessWidget {
  final double size;
  final BadgeTier tier;
  final SimpleBadgeGroup? group;
  final bool isUnlocked;
  final int xpRewardValue;
  final Widget child;

  const BadgeShapeWidget({
    super.key,
    required this.size,
    required this.tier,
    this.group,
    required this.isUnlocked,
    required this.xpRewardValue,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final offsetY = getOffsetY(tier, group, size);

    return CustomPaint(
      size: Size(size, size),
      painter: _BadgeShapePainter(
        tier: tier,
        group: group,
        isUnlocked: isUnlocked,
        xpRewardValue: xpRewardValue,
        theme: Theme.of(context),
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Transform.translate(
            offset: Offset(0, offsetY),
            child: SizedBox(
              width: size * 0.55,
              height: size * 0.55,
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgeShapePainter extends CustomPainter {
  final BadgeTier tier;
  final SimpleBadgeGroup? group;
  final bool isUnlocked;
  final int xpRewardValue;
  final ThemeData theme;

  const _BadgeShapePainter({
    required this.tier,
    this.group,
    required this.isUnlocked,
    required this.xpRewardValue,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = tier == BadgeTier.advanced ? 3.5 : 2.5;
    final margin = strokeWidth / 2;
    final path = getShapePath(size, tier, group, margin);
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    // 1. Drop Shadow (3D Depth)
    final shadowPath = getShapePath(size, tier, group, margin);
    canvas.save();
    canvas.translate(0, tier == BadgeTier.advanced ? 4.0 : 2.5);
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isUnlocked ? 0.35 : 0.25)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, tier == BadgeTier.advanced ? 6 : 4);
    canvas.drawPath(shadowPath, shadowPaint);
    canvas.restore();

    // 2. Glowaura (Glow Aura for Unlocked)
    if (isUnlocked) {
      final glowPaint = Paint()
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 10);

      if (tier == BadgeTier.advanced) {
        glowPaint.color = const Color(0xFFFFA000).withValues(alpha: 0.5);
      } else if (xpRewardValue >= 75) {
        glowPaint.color = const Color(0xFFB0BEC5).withValues(alpha: 0.3);
      } else {
        glowPaint.color = const Color(0xFFD84315).withValues(alpha: 0.3);
      }
      canvas.drawPath(path, glowPaint);
    }

    // 3. Main Fill Gradient
    final paint = Paint()..style = PaintingStyle.fill;

    // Active/Unlocked Gradients
    Gradient activeGradient;
    if (tier == BadgeTier.advanced) {
      activeGradient = const RadialGradient(
        center: Alignment(-0.25, -0.25),
        radius: 0.9,
        colors: [
          Color(0xFFFFFDE7), // Specular light highlight
          Color(0xFFFFD54F), // Gold body
          Color(0xFFFF8F00), // Deep Amber
          Color(0xFFD97706), // Golden shade shadow
        ],
        stops: [0.0, 0.45, 0.85, 1.0],
      );
    } else if (xpRewardValue >= 75) {
      // Silver
      activeGradient = const RadialGradient(
        center: Alignment(-0.25, -0.25),
        radius: 0.85,
        colors: [
          Color(0xFFFFFFFF), // specular white
          Color(0xFFECEFF1), // light silver
          Color(0xFF90A4AE), // medium steel silver
          Color(0xFF475569), // dark shadow grey
        ],
        stops: [0.0, 0.35, 0.8, 1.0],
      );
    } else {
      // Bronze
      activeGradient = const RadialGradient(
        center: Alignment(-0.25, -0.25),
        radius: 0.85,
        colors: [
          Color(0xFFFFEDD5), // copper flare highlight
          Color(0xFFEA580C), // rich copper body
          Color(0xFF9A3412), // medium bronze
          Color(0xFF451A03), // shadow bronze/brown
        ],
        stops: [0.0, 0.3, 0.8, 1.0],
      );
    }

    if (isUnlocked) {
      paint.shader = activeGradient.createShader(Rect.fromLTWH(0, 0, w, h));
    } else {
      // Locked: Grayscale version of the shape gradient
      paint.shader = _makeGrayscale(activeGradient).createShader(Rect.fromLTWH(0, 0, w, h));
    }

    canvas.drawPath(path, paint);

    // 4. Background Starburst Rays (Painted for both, but faded when locked)
    canvas.save();
    canvas.clipPath(path);

    final raysPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: isUnlocked ? 0.22 : 0.06),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..strokeWidth = tier == BadgeTier.advanced ? 2.0 : 1.2
      ..style = PaintingStyle.stroke;

    final r = w * 0.8;
    const rayCount = 8;
    for (int i = 0; i < rayCount; i++) {
      final angle = i * pi / (rayCount / 2);
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + r * cos(angle), cy + r * sin(angle)),
        raysPaint,
      );
    }
    canvas.restore();

    // 5. Inner Framing Ring (Concentric Track)
    canvas.save();
    canvas.clipPath(path);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final Color activeRingColor = tier == BadgeTier.advanced
        ? const Color(0xFFFFE082)
        : Colors.white;
    final double ringAlpha = tier == BadgeTier.advanced ? 0.35 : 0.18;

    ringPaint.color = isUnlocked
        ? activeRingColor.withValues(alpha: ringAlpha)
        : _toGrayscale(activeRingColor).withValues(alpha: ringAlpha * 0.5);

    if (tier == BadgeTier.advanced) {
      canvas.drawCircle(Offset(cx, cy), w * 0.28, ringPaint);
    } else {
      canvas.drawCircle(Offset(cx, cy), w * 0.25, ringPaint);
    }

    canvas.restore();

    // 6. Beveled Outer Border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    Gradient activeBorderGradient;
    if (tier == BadgeTier.advanced) {
      activeBorderGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFF9C4), // White gold glow reflection
          Color(0xFFFFD54F), // Golden frame
          Color(0xFFFF8F00), // Amber border
          Color(0xFFE65100), // Dark gold shadow
        ],
      );
    } else if (xpRewardValue >= 75) {
      // Silver
      activeBorderGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFFFFF), // pure reflection
          Color(0xFFCFD8DC), // grey steel
          Color(0xFF78909C), // silver edge
          Color(0xFF37474F), // shadow grey
        ],
      );
    } else {
      // Bronze
      activeBorderGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFE0B2), // bronze flare
          Color(0xFFD84315), // copper border
          Color(0xFF5D4037), // brown edge
          Color(0xFF2D1510), // shadow bronze
        ],
      );
    }

    if (isUnlocked) {
      borderPaint.shader = activeBorderGradient.createShader(Rect.fromLTWH(0, 0, w, h));
    } else {
      // Grayscale border
      borderPaint.shader = _makeGrayscale(activeBorderGradient).createShader(Rect.fromLTWH(0, 0, w, h));
    }
    canvas.drawPath(path, borderPaint);

    // 7. Glossy Dome Highlight (Always active to give it a glassy look even when locked!)
    canvas.save();
    canvas.clipPath(path);

    final reflectionPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: isUnlocked ? 0.35 : 0.18),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.45));

    canvas.drawOval(
      Rect.fromLTWH(-w * 0.1, -h * 0.15, w * 1.2, h * 0.55),
      reflectionPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

double getOffsetY(BadgeTier tier, SimpleBadgeGroup? group, double size) {
  if (tier == BadgeTier.advanced) {
    // Shield narrows down at the bottom; offset icon slightly up for optical centering
    return -size * 0.095;
  }
  if (group == SimpleBadgeGroup.savings) {
    // Diamond narrows down at bottom, let's offset it slightly up
    return -size * 0.04;
  }
  if (group == SimpleBadgeGroup.goals) {
    // Hexagon has top/bottom points, let's offset slightly up
    return -size * 0.02;
  }
  // Other shapes (circle, octagon, star) might need a tiny upward offset to counteract the shadow drop
  return -size * 0.015;
}

Path getShapePath(Size size, BadgeTier tier, SimpleBadgeGroup? group, double margin) {
  final path = Path();
  final w = size.width;
  final h = size.height;

  if (tier == BadgeTier.advanced) {
    final left = margin;
    final top = margin;
    final right = w - margin;
    final bottom = h - margin;
    final width = right - left;
    final height = bottom - top;

    // Shield path with margin inset
    path.moveTo(left + width * 0.5, top);
    path.quadraticBezierTo(left + width * 0.8, top + height * 0.05, right, top + height * 0.15);
    path.quadraticBezierTo(left + width * 0.95, top + height * 0.6, left + width * 0.5, bottom);
    path.quadraticBezierTo(left + width * 0.05, top + height * 0.6, left, top + height * 0.15);
    path.quadraticBezierTo(left + width * 0.2, top + height * 0.05, left + width * 0.5, top);
    path.close();
    return path;
  }

  switch (group) {
    case SimpleBadgeGroup.firstSteps:
      // Circle
      path.addOval(Rect.fromLTWH(margin, margin, w - 2 * margin, h - 2 * margin));
      break;
    case SimpleBadgeGroup.consistency:
      // Octagon
      final left = margin;
      final top = margin;
      final right = w - margin;
      final bottom = h - margin;
      final width = right - left;
      final offset = width * 0.28;

      path.moveTo(left + offset, top);
      path.lineTo(right - offset, top);
      path.lineTo(right, top + offset);
      path.lineTo(right, bottom - offset);
      path.lineTo(right - offset, bottom);
      path.lineTo(left + offset, bottom);
      path.lineTo(left, bottom - offset);
      path.lineTo(left, top + offset);
      path.close();
      break;
    case SimpleBadgeGroup.savings:
      // Diamond
      final left = margin;
      final top = margin;
      final right = w - margin;
      final bottom = h - margin;
      final width = right - left;
      final height = bottom - top;

      path.moveTo(left + width * 0.5, top);
      path.lineTo(right, top + height * 0.5);
      path.lineTo(left + width * 0.5, bottom);
      path.lineTo(left, top + height * 0.5);
      path.close();
      break;
    case SimpleBadgeGroup.goals:
      // Hexagon
      final left = margin;
      final top = margin;
      final right = w - margin;
      final bottom = h - margin;
      final width = right - left;
      final height = bottom - top;

      path.moveTo(left + width * 0.5, top);
      path.lineTo(right, top + height * 0.25);
      path.lineTo(right, top + height * 0.75);
      path.lineTo(left + width * 0.5, bottom);
      path.lineTo(left, top + height * 0.75);
      path.lineTo(left, top + height * 0.25);
      path.close();
      break;
    case SimpleBadgeGroup.team:
      // 8-pointed star
      final left = margin;
      final top = margin;
      final right = w - margin;
      final bottom = h - margin;
      final width = right - left;
      final height = bottom - top;
      final cx = left + width / 2;
      final cy = top + height / 2;
      final outerRadius = width / 2;
      final innerRadius = width / 2.8;
      const points = 8;
      const angle = pi / points;
      for (int i = 0; i < 2 * points; i++) {
        final r = i % 2 == 0 ? outerRadius : innerRadius;
        final currAngle = i * angle - pi / 2;
        final x = cx + r * cos(currAngle);
        final y = cy + r * sin(currAngle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      break;
    default:
      path.addOval(Rect.fromLTWH(margin, margin, w - 2 * margin, h - 2 * margin));
  }

  return path;
}

SimpleBadgeGroup getSimpleBadgeGroup(String id) {
  if (const [
    'first_category',
    'first_planning',
    'first_goal',
    'first_invite',
    'profile_complete',
    'first_income',
    'first_expense',
    'first_transfer',
    'workspace_named',
    'first_month'
  ].contains(id)) {
    return SimpleBadgeGroup.firstSteps;
  }
  if (const [
    'five_transactions',
    'twenty_transactions',
    'fifty_transactions',
    'hundred_transactions',
    'week_complete',
    'two_accounts',
    'three_accounts',
    'five_accounts',
    'five_categories',
    'ten_categories'
  ].contains(id)) {
    return SimpleBadgeGroup.consistency;
  }
  if (const [
    'round_number',
    'big_transaction',
    'small_transactions_ten',
    'income_registered',
    'expense_under_income',
    'three_categories_month',
    'five_categories_month',
    'savings_10pct',
    'savings_start',
    'no_credit_debt'
  ].contains(id)) {
    return SimpleBadgeGroup.savings;
  }
  if (const [
    'goal_halfway',
    'goal_75pct',
    'goal_under_deadline',
    'two_active_goals',
    'five_active_goals',
    'long_term_goal',
    'short_term_goal',
    'goal_deposit',
    'goal_debt_paid',
    'goal_linked_account'
  ].contains(id)) {
    return SimpleBadgeGroup.goals;
  }
  return SimpleBadgeGroup.team;
}

int getXpRewardValue(String xpReward) {
  try {
    return int.parse(xpReward.replaceAll(RegExp(r'[^0-9]'), ''));
  } catch (_) {
    return 50;
  }
}
