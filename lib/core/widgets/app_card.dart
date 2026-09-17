import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_elevation.dart';
import '../theme/app_gradients.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// Como este cartão participa da identidade.
enum AppCardVariant {
  /// **Papel.** Superfície de leitura: lista, tabela, formulário, extrato,
  /// detalhe. É plana — a separação vem de uma borda de 1px.
  paper,

  /// **Papel elevado.** Mesmo papel, mas pousado sobre o fundo. Para quando o
  /// cartão é um objeto destacável (uma meta, uma conta) e não um bloco de
  /// conteúdo.
  raised,

  /// **Jogo.** Bloco escuro com gradiente: XP, nível, missão, Bússola,
  /// conquista, coaching. Vale nos dois temas — "onde está escuro, você
  /// joga". O conteúdo recebe o tema escuro automaticamente.
  game,
}

/// O cartão do app.
///
/// Substitui as ~14 implementações que existiam, com quatro raios (16/20/24/16)
/// para o mesmo papel, três mecanismos de elevação e quatro fontes de
/// superfície diferentes. Aqui há um raio, um mecanismo e três variantes —
/// e a variante diz o que o cartão **é**, não como ele parece.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.variant = AppCardVariant.paper,
    this.padding = AppSpacing.card,
    this.onTap,
    this.borderColor,
    this.rewarded = false,
    this.clipBehavior = Clip.antiAlias,
    this.semanticLabel,
  });

  /// Atalho para um bloco de jogo.
  const AppCard.game({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry padding = AppSpacing.card,
    VoidCallback? onTap,
    bool rewarded = false,
    String? semanticLabel,
  }) : this(
         key: key,
         variant: AppCardVariant.game,
         padding: padding,
         onTap: onTap,
         rewarded: rewarded,
         semanticLabel: semanticLabel,
         child: child,
       );

  final Widget child;
  final AppCardVariant variant;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Borda de destaque, para quando o cartão carrega um estado (missão
  /// concluída, categoria fora do plano). `null` usa a linha do tema.
  final Color? borderColor;

  /// Liga o halo dourado de recompensa. Reservado a conquista — se aparecer
  /// em conteúdo comum, a recompensa deixa de significar algo.
  final bool rewarded;

  final Clip clipBehavior;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isGame = variant == AppCardVariant.game;

    final Color surface = switch (variant) {
      AppCardVariant.paper => palette.paper,
      AppCardVariant.raised => palette.paper,
      AppCardVariant.game => AppColors.surfaceDefault,
    };

    final Color line =
        borderColor ?? (isGame ? AppColors.surfaceRaised : palette.line);

    final List<BoxShadow> shadow = rewarded
        ? AppElevation.reward
        : switch (variant) {
            AppCardVariant.paper => AppElevation.flat,
            AppCardVariant.raised => AppElevation.raised(palette.brightness),
            AppCardVariant.game => AppElevation.raised(Brightness.dark),
          };

    Widget content = Padding(padding: padding, child: child);

    if (isGame) {
      // Dentro de um bloco de jogo tudo lê o tema escuro: texto, ícone,
      // divisor e campo passam a ter contraste sem que o chamador saiba.
      content = Theme(data: AppTheme.onGame(context), child: content);
    }

    Widget card = DecoratedBox(
      decoration: BoxDecoration(
        color: isGame ? null : surface,
        gradient: isGame ? AppGradients.game : null,
        borderRadius: AppRadius.brLg,
        border: Border.all(
          color: rewarded ? AppColors.gold : line,
          width: rewarded ? 2 : 1,
        ),
        boxShadow: shadow,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.brLg,
        clipBehavior: clipBehavior,
        child: onTap == null
            ? content
            : Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: onTap,
                  splashColor: (isGame ? AppColors.gold : palette.ink)
                      .withValues(alpha: 0.08),
                  child: content,
                ),
              ),
      ),
    );

    if (semanticLabel != null) {
      card = Semantics(
        label: semanticLabel,
        button: onTap != null,
        container: true,
        child: card,
      );
    }

    return card;
  }
}
