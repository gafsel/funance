import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_breakpoints.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/theme/app_typography.dart';

class DetailHeaderAction {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;
  final String? tooltip;

  DetailHeaderAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
    this.tooltip,
  });
}

class DetailHeaderChip {
  final IconData icon;
  final String label;
  final Color? backgroundColor;

  DetailHeaderChip({
    required this.icon,
    required this.label,
    this.backgroundColor,
  });
}

class SliverDetailHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color? subtitleColor;
  final Color? backgroundColor;
  final List<DetailHeaderChip> chips;
  final List<DetailHeaderAction> actions;
  final Widget? logo;
  final Widget? sideContent;
  final Widget? bottomContent;
  final double expandedHeight;
  final bool isDesktop;

  const SliverDetailHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleColor,
    this.backgroundColor,
    this.chips = const [],
    this.actions = const [],
    this.logo,
    this.sideContent,
    this.bottomContent,
    this.expandedHeight = 250,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    // A largura que decide o layout é a do PAINEL, medida pelas constraints do
    // sliver — não a da janela. Com o `NavigationRail` aberto, uma janela de
    // 1000px entregava um cabeçalho "largo" a um painel bem mais estreito.
    return SliverLayoutBuilder(
      builder: (context, constraints) =>
          _build(context, constraints.crossAxisExtent),
    );
  }

  Widget _build(BuildContext context, double width) {
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);
    final isSmallWidth = AppBreakpoints.of(width).isCompact;
    final effectiveBgColor = backgroundColor ?? theme.colorScheme.primary;
    // A cor do fundo vem de DADO (a cor da conta, da meta, da categoria), e
    // por isso a tinta não pode vir da paleta do tema: ela tem que contrastar
    // com ESTE fundo, claro ou escuro, em qualquer tema.
    final contentColor = AppColors.inkOn(effectiveBgColor);
    // "Escuro" aqui quer dizer "pediu a tinta clara" — é a MESMA decisão que
    // escolheu a tinta, e não um segundo corte que pode discordar dela. Os
    // véus abaixo seguem junto: sobre fundo escuro um branco a 10% aparece,
    // sobre fundo claro o mesmo branco some.
    final isDarkBg = contentColor == AppColors.inkInverse;

    // A altura pedida pelas telas é a do CONTEÚDO. O widget soma o que varia
    // por dispositivo — status bar/notch e escala de fonte do sistema — e
    // limita ao tamanho da tela (ex.: landscape em celulares pequenos), para
    // o header não estourar em telas pequenas nem sobrar em desktop.
    final textScale = mq.textScaler.scale(1.0).clamp(1.0, 1.3);
    final effectiveExpandedHeight =
        (expandedHeight * textScale + mq.padding.top).clamp(
          0.0,
          mq.size.height * 0.85,
        );

    return SliverAppBar(
      expandedHeight: effectiveExpandedHeight,
      pinned: true,
      backgroundColor: effectiveBgColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: contentColor),
      actions: isSmallWidth
          ? []
          : [
              ...actions.map(
                (action) => Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: TextButton.icon(
                    onPressed: action.onPressed,
                    icon: Icon(action.icon),
                    label: Text(action.label),
                    style: TextButton.styleFrom(
                      foregroundColor: action.color ?? contentColor,
                      backgroundColor: contentColor.withValues(
                        alpha: isDarkBg ? 0.1 : 0.05,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: ClipRect(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceDeep,
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: width * .005,
                colors: [
                  AppColors.transparent,
                  theme.colorScheme.scrim.withValues(alpha: 0.54),
                  theme.colorScheme.scrim,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: Padding(
              padding: EdgeInsetsGeometry.only(
                top: mq.padding.top + kToolbarHeight,
              ),
              // Guarda contra overflow: se em algum dispositivo extremo o
              // conteúdo ainda exceder a altura, ele é cortado graciosamente
              // em vez de renderizar as listras de erro de RenderFlex.
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: AppSpacing.hMd,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (logo != null) ...[
                                      logo!,
                                      const SizedBox(width: AppSpacing.sm),
                                    ],
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  color: contentColor
                                                      .withValues(alpha: 0.7),
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (chips.isNotEmpty) ...[
                                            Wrap(
                                              spacing: AppSpacing.xs,
                                              runSpacing: AppSpacing.xs,
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              children: [
                                                ...chips.map(
                                                  (chip) => _buildInfoChip(
                                                    context,
                                                    chip,
                                                    effectiveBgColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (subtitle != null) ...[
                                  AppSpacing.gapXxs,
                                  // FittedBox encolhe valores longos (ex.:
                                  // "R$ 123.456,78") em telas estreitas em vez
                                  // de quebrar linha ou estourar.
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      subtitle!,
                                      maxLines: 1,
                                      style: theme.textTheme.displayLarge
                                          ?.copyWith(
                                            color:
                                                subtitleColor ?? contentColor,
                                          )
                                          .tabularFigures,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (!isSmallWidth && sideContent != null) ...[
                            const SizedBox(width: AppSpacing.xl),
                            SizedBox(
                              // Encolhe o painel lateral em larguras
                              // intermediárias (tablets/janela estreita).
                              width: (width * 0.3).clamp(220.0, 300.0),
                              child: sideContent!,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isSmallWidth && sideContent != null) ...[
                      AppSpacing.gapMd,
                      Padding(padding: AppSpacing.hMd, child: sideContent!),
                    ],
                    if (isSmallWidth && actions.isNotEmpty) ...[
                      AppSpacing.gapMd,
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: AppSpacing.hMd,
                        child: Row(
                          children: actions
                              .map(
                                (action) => Padding(
                                  padding: const EdgeInsets.only(
                                    right: AppSpacing.xs,
                                  ),
                                  child: _buildMobileAction(
                                    context,
                                    action,
                                    isDarkBg,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                    if (bottomContent != null) ...[
                      AppSpacing.gapLg,
                      bottomContent!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        centerTitle: false,
        title: LayoutBuilder(
          builder: (context, constraints) {
            final settings = context
                .dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
            if (settings == null) return const SizedBox.shrink();
            final deltaExtent = settings.maxExtent - settings.minExtent;
            final t =
                (1.0 -
                        (settings.currentExtent - settings.minExtent) /
                            deltaExtent)
                    .clamp(0.0, 1.0);

            if (t > 0.8) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (logo != null) ...[
                    SizedBox(width: 24, height: 24, child: logo!),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Flexible(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: contentColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildMobileAction(
    BuildContext context,
    DetailHeaderAction action,
    bool isDarkBg,
  ) {
    final theme = Theme.of(context);
    final contentColor = isDarkBg ? AppColors.inkInverse : AppColors.inkLight;

    return InkWell(
      onTap: action.onPressed,
      borderRadius: AppRadius.brMd,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: contentColor.withValues(alpha: isDarkBg ? 0.15 : 0.08),
          borderRadius: AppRadius.brMd,
          border: Border.all(
            color: contentColor.withValues(alpha: isDarkBg ? 0.1 : 0.05),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(action.icon, size: 18, color: action.color ?? contentColor),
            const SizedBox(width: AppSpacing.xs),
            Text(
              action.label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: action.color ?? contentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context,
    DetailHeaderChip chip,
    Color bgColor,
  ) {
    final theme = Theme.of(context);
    // A pílula continua desenhada aqui (e não com `StatusPill`) porque o
    // chamador manda o FUNDO dela como dado — `StatusPill` recebe o acento.
    final ink = AppColors.inkOn(chip.backgroundColor ?? bgColor);
    final isDarkBg = ink == AppColors.inkInverse;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color:
            chip.backgroundColor ??
            ink.withValues(alpha: isDarkBg ? 0.15 : 0.05),
        borderRadius: AppRadius.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            chip.icon,
            size: 14,
            color: isDarkBg ? AppColors.inkInverse : AppColors.tealInk,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            chip.label,
            style: theme.textTheme.labelSmall?.copyWith(color: ink),
          ),
        ],
      ),
    );
  }
}
