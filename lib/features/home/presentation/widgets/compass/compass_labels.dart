import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/features/home/domain/models/financial_health_model.dart';
import 'package:funances/l10n/app_localizations.dart';

/// O vocabulário da Bússola: nome, descrição, ícone e cor de cada componente.
///
/// Fica num arquivo só porque card, sheet e histórico precisam exatamente das
/// mesmas traduções — se cada um resolvesse o seu `switch`, a primeira faixa
/// renomeada apareceria com dois nomes diferentes na mesma tela.

/// Nome de cada componente, do vocabulário do produto.
String compassComponentLabel(AppLocalizations l10n, FreedomComponent c) =>
    switch (c) {
      FreedomComponent.folego => l10n.compassFolego,
      FreedomComponent.poupanca => l10n.compassPoupanca,
      FreedomComponent.disciplina => l10n.compassDisciplina,
      FreedomComponent.alivio => l10n.compassAlivio,
    };

String compassComponentDescription(
  AppLocalizations l10n,
  FreedomComponent c,
) => switch (c) {
  FreedomComponent.folego => l10n.compassFolegoDesc,
  FreedomComponent.poupanca => l10n.compassPoupancaDesc,
  FreedomComponent.disciplina => l10n.compassDisciplinaDesc,
  FreedomComponent.alivio => l10n.compassAlivioDesc,
};

String compassTierLabel(AppLocalizations l10n, FreedomTier tier) =>
    switch (tier) {
      FreedomTier.aprendiz => l10n.compassTierAprendiz,
      FreedomTier.guardiao => l10n.compassTierGuardiao,
      FreedomTier.estrategista => l10n.compassTierEstrategista,
      FreedomTier.mestre => l10n.compassTierMestre,
      FreedomTier.livre => l10n.compassTierLivre,
      FreedomTier.unknown => l10n.compassTierUnknown,
    };

IconData compassComponentIcon(FreedomComponent c) => switch (c) {
  FreedomComponent.folego => Icons.air_rounded,
  FreedomComponent.poupanca => Icons.savings_rounded,
  FreedomComponent.disciplina => Icons.rule_rounded,
  FreedomComponent.alivio => Icons.self_improvement_rounded,
};

/// Cor pela faixa do score. Não é decoração: é a leitura rápida de "vai bem"
/// ou "precisa de atenção" sem obrigar ninguém a interpretar o número.
Color compassScoreColor(double score) {
  if (score >= 75) return AppColors.success;
  if (score >= 50) return AppColors.vibrantTeal;
  if (score >= 25) return AppColors.antiqueGold;
  return AppColors.coralOrange;
}
