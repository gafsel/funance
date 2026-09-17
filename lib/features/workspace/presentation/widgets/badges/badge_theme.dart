import 'package:flutter/material.dart';
import 'package:funances/features/workspace/domain/models/badge_catalog_model.dart';
import 'package:funances/l10n/app_localizations.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Tema dos emblemas
//
// O CATÁLOGO (ids, nomes, XP, descrições, categorias) e a tabela de XP por
// nível vêm do backend, em `config/badges`. Antes eram espelhados à mão neste
// arquivo — 67 entradas com o XP como string e as descrições nos ARB — e o
// nível era recalculado aqui com a inversa de `calculateLevel`. Cada badge novo
// no servidor exigia lembrar de editar este arquivo, e ninguém lembrava.
//
// O que sobra aqui é só aparência: qual `IconData` corresponde ao nome do ícone
// (o Flutter precisa de constantes para o tree-shaking de ícones) e qual cor
// cada seção usa.
// ─────────────────────────────────────────────────────────────────────────────

enum BadgeTier { advanced, simple }

enum SimpleBadgeGroup { firstSteps, consistency, savings, goals, team }

/// Nome do ícone (como o servidor publica) -> `IconData`.
///
/// Não pode ser `IconData(codePoint)` dinâmico: com `--tree-shake-icons` (o
/// padrão em release) um ícone que não aparece como constante no código é
/// removido do font e vira um quadrado vazio.
const Map<String, IconData> _badgeIcons = {
  'rocket_launch': Icons.rocket_launch,
  'account_balance': Icons.account_balance,
  'add_circle': Icons.add_circle,
  'assignment': Icons.assignment,
  'point_of_sale': Icons.point_of_sale,
  'fact_check': Icons.fact_check,
  'workspace_premium': Icons.workspace_premium,
  'bolt': Icons.bolt,
  'savings': Icons.savings,
  'military_tech': Icons.military_tech,
  'stars': Icons.stars,
  'check_circle': Icons.check_circle,
  'pie_chart': Icons.pie_chart,
  'trending_up': Icons.trending_up,
  'content_cut': Icons.content_cut,
  'groups': Icons.groups,
  'calendar_month': Icons.calendar_month,
  'label': Icons.label,
  'event_note': Icons.event_note,
  'flag': Icons.flag,
  'person_add': Icons.person_add,
  'verified': Icons.verified,
  'south_east': Icons.south_east,
  'north_west': Icons.north_west,
  'swap_horiz': Icons.swap_horiz,
  'edit': Icons.edit,
  'calendar_today': Icons.calendar_today,
  'flash_on': Icons.flash_on,
  'emoji_events': Icons.emoji_events,
  'date_range': Icons.date_range,
  'account_balance_wallet': Icons.account_balance_wallet,
  'dashboard': Icons.dashboard,
  'business_center': Icons.business_center,
  'category': Icons.category,
  'workspaces': Icons.workspaces,
  'radio_button_checked': Icons.radio_button_checked,
  'payments': Icons.payments,
  'grain': Icons.grain,
  'receipt_long': Icons.receipt_long,
  'balance': Icons.balance,
  'donut_small': Icons.donut_small,
  'donut_large': Icons.donut_large,
  'percent': Icons.percent,
  'monetization_on': Icons.monetization_on,
  'credit_score': Icons.credit_score,
  'looks_two': Icons.looks_two,
  'looks_3': Icons.looks_3,
  'timer': Icons.timer,
  'offline_bolt': Icons.offline_bolt,
  'dynamic_feed': Icons.dynamic_feed,
  'public': Icons.public,
  'add_card': Icons.add_card,
  'free_cancellation': Icons.free_cancellation,
  'link': Icons.link,
  'group_add': Icons.group_add,
  'refresh': Icons.refresh,
  'sync_alt': Icons.sync_alt,
  'task_alt': Icons.task_alt,
  'sports_score': Icons.sports_score,
  'event_available': Icons.event_available,
  'repeat': Icons.repeat,
  'cake': Icons.cake,
  'waving_hand': Icons.waving_hand,
  'star': Icons.star,
};

/// Ícone do badge; um nome desconhecido (badge novo, app antigo) vira um troféu
/// genérico em vez de sumir da vitrine.
IconData badgeIconFor(String iconName) =>
    _badgeIcons[iconName] ?? Icons.emoji_events;

/// Paleta por seção. A cor de cada badge é escolhida de forma determinística
/// pelo id, para dar variedade sem manter uma lista de 67 cores à mão.
const Map<BadgeCategory, List<Color>> _categoryPalettes = {
  BadgeCategory.advanced: [
    Color(0xFF7E57C2),
    Color(0xFF1E88E5),
    Color(0xFF00897B),
    Color(0xFFF9A825),
    Color(0xFFD81B60),
  ],
  BadgeCategory.firstSteps: [
    Color(0xFF7C4DFF),
    Color(0xFF00BCD4),
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
  ],
  BadgeCategory.consistency: [
    Color(0xFFFDD835),
    Color(0xFF66BB6A),
    Color(0xFFAB47BC),
    Color(0xFF0288D1),
  ],
  BadgeCategory.savings: [
    Color(0xFFF57C00),
    Color(0xFF26C6DA),
    Color(0xFFE91E63),
    Color(0xFF43A047),
  ],
  BadgeCategory.goals: [
    Color(0xFF5C6BC0),
    Color(0xFF8E24AA),
    Color(0xFFE64A19),
    Color(0xFF0097A7),
  ],
  BadgeCategory.team: [
    Color(0xFF039BE5),
    Color(0xFF00796B),
    Color(0xFF558B2F),
    Color(0xFF7B1FA2),
  ],
  BadgeCategory.unknown: [Color(0xFF78909C)],
};

Color badgeColorFor(BadgeCatalogItem badge) {
  final palette =
      _categoryPalettes[badge.category] ??
      _categoryPalettes[BadgeCategory.unknown]!;
  var hash = 0;
  for (final unit in badge.id.codeUnits) {
    hash = (hash + unit) % 997;
  }
  return palette[hash % palette.length];
}

BadgeTier badgeTierFor(BadgeCategory category) =>
    category == BadgeCategory.advanced ? BadgeTier.advanced : BadgeTier.simple;

SimpleBadgeGroup simpleGroupFor(BadgeCategory category) => switch (category) {
  BadgeCategory.firstSteps => SimpleBadgeGroup.firstSteps,
  BadgeCategory.consistency => SimpleBadgeGroup.consistency,
  BadgeCategory.savings => SimpleBadgeGroup.savings,
  BadgeCategory.goals => SimpleBadgeGroup.goals,
  BadgeCategory.team ||
  BadgeCategory.advanced ||
  BadgeCategory.unknown => SimpleBadgeGroup.team,
};

String badgeCategoryLabel(AppLocalizations l10n, BadgeCategory category) =>
    switch (category) {
      BadgeCategory.advanced => l10n.badgeCategoryAdvanced,
      BadgeCategory.firstSteps => l10n.badgeCategoryFirstSteps,
      BadgeCategory.consistency => l10n.badgeCategoryConsistency,
      BadgeCategory.savings => l10n.badgeCategorySavings,
      BadgeCategory.goals => l10n.badgeCategoryGoals,
      BadgeCategory.team || BadgeCategory.unknown => l10n.badgeCategoryTeam,
    };

IconData badgeCategoryIcon(BadgeCategory category) =>
    category == BadgeCategory.advanced ? Icons.workspace_premium : Icons.star;
