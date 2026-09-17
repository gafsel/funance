import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// O que a tela mostra quando não há o que mostrar.
///
/// O app tinha treze vazios escritos à mão, com ícones de 40, 64 e nenhum,
/// quatro cores de ícone diferentes, raios de 16, 24 e sem cápsula, e duas
/// telas onde a MESMA frase aparecia com paddings diferentes. Quatro deles
/// eram um `Center(child: Text(...))` pelado.
///
/// A passada de design escolheu **uma** aparência, e por isso os parâmetros de
/// estilo que existiam aqui (`iconSize`, `iconColor`, `borderRadius`,
/// `borderAlpha`, `titleStyle`) sumiram: cor e tamanho vêm do tema, e um vazio
/// dentro de um bloco escuro fica claro sozinho porque o bloco já troca o tema
/// (ver `AppTheme.onGame`). O que sobrou é a forma, que é o que de fato muda
/// entre os três casos.
class EmptyState extends StatelessWidget {
  /// Vazio dentro de uma cápsula, no meio de uma tela que tem outras seções:
  /// missões da semana, desafio da Party.
  const EmptyState.card({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.padding = const EdgeInsets.symmetric(
      vertical: AppSpacing.lg,
      horizontal: AppSpacing.md,
    ),
  }) : _variant = _EmptyStateVariant.card,
       compact = false,
       messageStyle = null;

  /// Vazio que ocupa a área inteira, com um convite para preenchê-la: metas,
  /// contas do onboarding.
  const EmptyState.centered({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.padding = AppSpacing.allLg,
    this.compact = false,
  }) : _variant = _EmptyStateVariant.centered,
       messageStyle = null;

  /// Só a frase, centralizada. É o vazio das listas paginadas.
  const EmptyState.message(
    String message, {
    super.key,
    this.padding = AppSpacing.allLg,
    TextStyle? style,
  }) : _variant = _EmptyStateVariant.message,
       title = message,
       message = null,
       icon = null,
       action = null,
       compact = false,
       messageStyle = style;

  final IconData? icon;
  final String title;
  final String? message;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  /// Só em [EmptyState.centered]: `true` encolhe o bloco para o conteúdo, em
  /// vez de ocupar a altura disponível.
  final bool compact;

  final TextStyle? messageStyle;
  final _EmptyStateVariant _variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return switch (_variant) {
      _EmptyStateVariant.message => Center(
        child: Padding(
          padding: padding,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style:
                messageStyle ??
                theme.textTheme.bodyMedium?.copyWith(color: palette.ink2),
          ),
        ),
      ),
      _EmptyStateVariant.card => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: palette.paper2,
          borderRadius: AppRadius.brLg,
          border: Border.all(color: palette.line),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: palette.ink3),
            AppSpacing.gapSm,
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(color: palette.ink),
            ),
            AppSpacing.gapXxs,
            Text(
              message!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: palette.ink2),
            ),
            if (action != null) ...[AppSpacing.gapSm, action!],
          ],
        ),
      ),
      _EmptyStateVariant.centered => Center(
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: palette.ink3),
              AppSpacing.gapMd,
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: palette.ink,
                ),
              ),
              if (message != null) ...[
                AppSpacing.gapXs,
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.ink2,
                  ),
                ),
              ],
              if (action != null) ...[AppSpacing.gapLg, action!],
            ],
          ),
        ),
      ),
    };
  }
}

enum _EmptyStateVariant { card, centered, message }
