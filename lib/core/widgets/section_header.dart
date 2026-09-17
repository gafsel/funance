import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';

/// Cabeçalho de seção.
///
/// Havia QUATRO implementações no app, com três nomes diferentes
/// (`_buildSectionHeader`, `_SectionHeader`, `_buildSectionTitle`) — e duas
/// delas eram byte a byte idênticas, uma como método e outra como classe, em
/// telas vizinhas de configurações. As duas classes `_SectionHeader` tinham
/// APIs incompatíveis entre si.
///
/// Os três construtores abaixo reproduzem exatamente as três aparências que
/// existem hoje. Eles são parâmetros, não estilos novos: a unificação visual
/// (um cabeçalho só para o app inteiro) é da passada de design, e depende de
/// os quatro usos já estarem em um lugar só — que é o que este arquivo faz.
class SectionHeader extends StatelessWidget {
  /// Rótulo de seção em listas de configuração: caixa alta, pequeno, na cor
  /// primária. É o padrão de `workspace_settings_screen` e
  /// `workspace_members_screen`.
  const SectionHeader.label(this.title, {super.key})
    : _variant = _SectionHeaderVariant.label,
      subtitle = null,
      icon = null,
      color = null,
      trailing = null;

  /// Cabeçalho com ícone em cápsula e um contador à direita. É o padrão da
  /// vitrine de emblemas.
  const SectionHeader.withIcon({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    this.trailing,
  }) : _variant = _SectionHeaderVariant.withIcon,
       subtitle = null;

  /// Título de folha de ações: ícone e título dourados, com subtítulo
  /// embaixo.
  const SectionHeader.sheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  }) : _variant = _SectionHeaderVariant.sheet,
       color = null,
       trailing = null;

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
  final Widget? trailing;
  final _SectionHeaderVariant _variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return switch (_variant) {
      _SectionHeaderVariant.label => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          title.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      _SectionHeaderVariant.withIcon => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color!.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
      _SectionHeaderVariant.sheet => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.antiqueGold, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.antiqueGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.pureWhite.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    };
  }
}

enum _SectionHeaderVariant { label, withIcon, sheet }

/// Contador "desbloqueados / total" que acompanha [SectionHeader.withIcon].
class SectionHeaderCounter extends StatelessWidget {
  const SectionHeaderCounter({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}
