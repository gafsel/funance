import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'app_chip.dart';

/// Cabeçalho de seção.
///
/// Havia QUATRO implementações no app, com três nomes diferentes
/// (`_buildSectionHeader`, `_SectionHeader`, `_buildSectionTitle`) — e duas
/// delas eram byte a byte idênticas, uma como método e outra como classe, em
/// telas vizinhas de configurações. As duas classes `_SectionHeader` tinham
/// APIs incompatíveis entre si.
///
/// A passada de design unificou a aparência: **um cabeçalho, com ou sem ícone,
/// com ou sem contador**, sempre com o mesmo tamanho, o mesmo respiro e a
/// mesma tinta. O que restou de variação é só a ênfase:
///
/// * [SectionHeader.label] — rótulo miúdo em caixa alta, para separar blocos
///   dentro de uma mesma lista (configurações, membros).
/// * [SectionHeader.withIcon] — título de seção com ícone em cápsula, para
///   quando a seção é um assunto (categorias de emblema, grupos de conta).
/// * [SectionHeader.sheet] — título de folha de ações, com subtítulo.
class SectionHeader extends StatelessWidget {
  const SectionHeader.label(this.title, {super.key})
    : _variant = _SectionHeaderVariant.label,
      subtitle = null,
      icon = null,
      color = null,
      trailing = null;

  const SectionHeader.withIcon({
    super.key,
    required this.title,
    required this.icon,
    this.color,
    this.trailing,
  }) : _variant = _SectionHeaderVariant.withIcon,
       subtitle = null;

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

  /// Cor do assunto da seção (a de uma categoria de emblema, por exemplo).
  /// `null` usa a tinta secundária do tema.
  final Color? color;

  final Widget? trailing;
  final _SectionHeaderVariant _variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    // O TÍTULO é marcado como cabeçalho para o leitor de tela. Sem isto, os
    // gestos de "próximo cabeçalho" — que é como se percorre uma tela longa
    // sem enxergar — não encontravam nada: o app inteiro tinha zero nós de
    // cabeçalho, e configurações, emblemas e grupos de conta se liam como uma
    // lista contínua de texto. Só o texto entra no nó: o contador e o ícone
    // continuam com a semântica deles.
    return switch (_variant) {
      _SectionHeaderVariant.label => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.xs,
        ),
        child: Semantics(
          header: true,
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(color: palette.ink2),
          ),
        ),
      ),
      _SectionHeaderVariant.withIcon => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.xs,
        ),
        child: Row(
          children: [
            Container(
              padding: AppSpacing.allXxs,
              decoration: BoxDecoration(
                color: (color ?? palette.ink2).withValues(alpha: 0.12),
                borderRadius: AppRadius.brSm,
              ),
              child: Icon(icon, color: color ?? palette.ink2, size: 18),
            ),
            AppSpacing.gapXs,
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: palette.ink,
                  ),
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
              Icon(icon, color: palette.ink2, size: 22),
              AppSpacing.gapXs,
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: palette.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapXxs,
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(color: palette.ink2),
          ),
        ],
      ),
    };
  }
}

enum _SectionHeaderVariant { label, withIcon, sheet }

/// Contador "desbloqueados / total" que acompanha [SectionHeader.withIcon].
///
/// É uma [StatusPill] — antes era a quinta pílula feita à mão do app.
class SectionHeaderCounter extends StatelessWidget {
  const SectionHeaderCounter({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) =>
      StatusPill(label: label, color: color, dense: true);
}
