import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';

/// O que a tela mostra quando não há o que mostrar.
///
/// O app tinha treze vazios escritos à mão, com ícones de 40, 64 e nenhum,
/// quatro cores de ícone diferentes, raios de 16, 24 e sem cápsula, e duas
/// telas onde a MESMA frase aparecia com paddings diferentes. Quatro deles
/// eram um `Center(child: Text(...))` pelado.
///
/// Os três construtores abaixo reproduzem exatamente as três formas que
/// existem hoje. Como no [SectionHeader], são parâmetros e não estilos novos:
/// escolher UMA aparência é da passada de design, e ela precisa dos treze
/// usos num lugar só antes de poder escolher.
class EmptyState extends StatelessWidget {
  /// Vazio dentro de uma cápsula, no meio de uma tela que tem outras seções:
  /// missões da semana, desafio do time.
  const EmptyState.card({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.padding = const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
    this.borderRadius = 24,
    this.borderAlpha = 0.1,
  }) : _variant = _EmptyStateVariant.card,
       iconSize = 40,
       iconColor = AppColors.deepTurquoise,
       titleStyle = null,
       mainAxisSize = MainAxisSize.max,
       messageStyle = null;

  /// Vazio que ocupa a área inteira, com um convite para preenchê-la: metas,
  /// contas do onboarding.
  const EmptyState.centered({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.iconSize = 64,
    this.iconColor,
    this.padding = EdgeInsets.zero,
    this.titleStyle,
    this.mainAxisSize = MainAxisSize.max,
  }) : _variant = _EmptyStateVariant.centered,
       borderRadius = 0,
       borderAlpha = 0,
       messageStyle = null;

  /// Só a frase, centralizada. É o vazio das listas paginadas.
  const EmptyState.message(
    String message, {
    super.key,
    this.padding = EdgeInsets.zero,
    TextStyle? style,
  }) : _variant = _EmptyStateVariant.message,
       title = message,
       message = null,
       icon = null,
       action = null,
       iconSize = 0,
       iconColor = null,
       borderRadius = 0,
       borderAlpha = 0,
       titleStyle = null,
       mainAxisSize = MainAxisSize.max,
       messageStyle = style;

  final IconData? icon;
  final String title;
  final String? message;
  final Widget? action;
  final double iconSize;
  final Color? iconColor;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double borderAlpha;

  /// Só em [EmptyState.centered]: o onboarding escreve em branco, sobre o
  /// gradiente escuro.
  final TextStyle? titleStyle;

  /// Só em [EmptyState.centered]: `min` centraliza o bloco na vertical, `max`
  /// o encosta no topo da área disponível.
  final MainAxisSize mainAxisSize;
  final TextStyle? messageStyle;
  final _EmptyStateVariant _variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return switch (_variant) {
      _EmptyStateVariant.message => Center(
        child: padding == EdgeInsets.zero
            ? Text(title, style: messageStyle)
            : Padding(
                padding: padding,
                child: Text(title, style: messageStyle),
              ),
      ),
      _EmptyStateVariant.card => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: AppColors.deepTurquoise.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: AppColors.deepTurquoise.withValues(alpha: borderAlpha),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: iconSize, color: iconColor),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 12), action!],
          ],
        ),
      ),
      _EmptyStateVariant.centered => Center(
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: mainAxisSize,
            children: [
              Icon(icon, size: iconSize, color: iconColor),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: titleStyle ?? theme.textTheme.titleMedium,
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              if (action != null) ...[const SizedBox(height: 24), action!],
            ],
          ),
        ),
      ),
    };
  }
}

enum _EmptyStateVariant { card, centered, message }
