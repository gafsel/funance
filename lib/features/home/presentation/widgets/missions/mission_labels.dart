import 'package:flutter/material.dart';
import 'package:funances/features/home/domain/models/weekly_mission_model.dart';
import 'package:funances/l10n/app_localizations.dart';

/// O vocabulário das missões do servidor.
///
/// O servidor grava `name` já em português, porque foi ele quem gerou a
/// missão — e, quando há IA no caminho, o texto é temperado por ela. Isso
/// funciona para quem usa o app em português e deixa quem usa em inglês com
/// uma frase no idioma errado.
///
/// O contrato novo resolve isso mandando junto a **chave** (`nameKey`) e os
/// **valores** (`params`) que preenchem a frase. Quando o app conhece a
/// chave, ele monta o nome no idioma do usuário; quando não conhece — uma
/// missão de um catálogo mais novo que o app instalado —, cai no `name` que
/// veio pronto. Nenhuma das duas pontas espera pela outra para subir.
///
/// As dez frases abaixo são as do catálogo
/// (`functions/src/features/goal/domain/models/mission_catalog.ts`); mudar uma
/// aqui sem mudar lá faz o mesmo cofre ler duas coisas diferentes conforme o
/// idioma.
String missionName(AppLocalizations l10n, WeeklyMissionModel mission) {
  final resolved = _fromKey(l10n, mission);
  if (resolved != null) return resolved;
  return mission.name;
}

String? _fromKey(AppLocalizations l10n, WeeklyMissionModel mission) {
  final target = mission.targetLabel;
  final category =
      mission.params['category'] ?? _fallbackCategory(l10n, mission);

  return switch (mission.nameKey) {
    'missionPersonalConsistencyPlanLimits' =>
      l10n.missionPersonalConsistencyPlanLimits(target),
    'missionPersonalDisciplineTopCategory' =>
      l10n.missionPersonalDisciplineTopCategory(category, target),
    'missionPersonalOrganizationReconcileItems' =>
      l10n.missionPersonalOrganizationReconcileItems(target),
    'missionBusinessConsistencyCostCenters' =>
      l10n.missionBusinessConsistencyCostCenters(target),
    'missionBusinessConsistencyIncomeForecast' =>
      l10n.missionBusinessConsistencyIncomeForecast(target),
    'missionBusinessDisciplineTopCostCenter' =>
      l10n.missionBusinessDisciplineTopCostCenter(category, target),
    'missionBusinessDisciplineMargin' => l10n.missionBusinessDisciplineMargin,
    'missionBusinessOrganizationReconcileStatements' =>
      l10n.missionBusinessOrganizationReconcileStatements(target),
    'missionBusinessOrganizationCategorizeAuto' =>
      l10n.missionBusinessOrganizationCategorizeAuto(target),
    'missionBusinessOrganizationInvoiceOnTime' =>
      l10n.missionBusinessOrganizationInvoiceOnTime(target),
    _ => null,
  };
}

/// Quando o servidor não mandou a categoria, a frase fala dela pelo papel —
/// "a categoria de maior gasto", "o centro de custo de maior peso" — e não
/// por um buraco.
String _fallbackCategory(AppLocalizations l10n, WeeklyMissionModel mission) =>
    mission.workspaceType == WorkspaceAudience.business
    ? l10n.missionFallbackCategoryBusiness
    : l10n.missionFallbackCategoryPersonal;

/// Rotas que uma missão pode acionar.
///
/// Mesma lista de `MISSION_ACTION_PATHS` no backend. É a allowlist do
/// coaching **mais** `/reconciliation`, e as duas continuam separadas de
/// propósito: uma build antiga do app não desenha um botão de conciliação num
/// slide de coaching, e o catálogo de missões depende de que ela exista.
///
/// Um `actionPath` fora deste conjunto simplesmente não vira botão.
const Set<String> missionActionPaths = {
  '/planning',
  '/planning-50-30-20',
  '/reconciliation',
  '/workspace/categories',
  '/workspace/accounts',
  '/category-details',
  '/transactions/form',
};

/// `true` quando [path] pode virar botão.
///
/// Compara só o caminho: o catálogo manda `/transactions/form?status=pending`,
/// e a query faz parte do destino, não da permissão.
bool missionActionPathIsAllowed(String? path) {
  if (path == null || path.isEmpty) return false;
  final normalized = Uri.tryParse(path)?.path ?? path;
  return missionActionPaths.contains(normalized);
}

/// O rótulo do botão, pelo destino.
///
/// `null` quando a rota não está na allowlist — quem chama usa isso para
/// decidir se há botão.
({String label, IconData icon})? missionActionLabel(
  AppLocalizations l10n,
  String? path,
) {
  if (!missionActionPathIsAllowed(path)) return null;
  final normalized = Uri.tryParse(path!)?.path ?? path;

  return switch (normalized) {
    '/planning' => (label: l10n.missionCtaPlanning, icon: Icons.tune_rounded),
    '/planning-50-30-20' => (
      label: l10n.missionCtaPlanning503020,
      icon: Icons.pie_chart_outline_rounded,
    ),
    '/reconciliation' => (
      label: l10n.reconciliationMissionCta,
      icon: Icons.fact_check_outlined,
    ),
    '/workspace/categories' => (
      label: l10n.missionCtaCategories,
      icon: Icons.groups_2_outlined,
    ),
    '/workspace/accounts' => (
      label: l10n.missionCtaAccounts,
      icon: Icons.account_balance_wallet_outlined,
    ),
    '/category-details' => (
      label: l10n.missionCtaCategoryDetails,
      icon: Icons.insights_outlined,
    ),
    '/transactions/form' => (
      label: l10n.missionCtaTransactionForm,
      icon: Icons.add_circle_outline,
    ),
    _ => null,
  };
}
