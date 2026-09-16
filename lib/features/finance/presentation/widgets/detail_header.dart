import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/features/user/domain/models/user_model.dart';
import 'package:funances/features/user/presentation/widgets/user_avatar.dart';

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
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);
    final isSmallWidth = mq.size.width < 600;
    final effectiveBgColor = backgroundColor ?? theme.colorScheme.primary;
    final isDarkBg = effectiveBgColor.computeLuminance() < 0.5;
    final contentColor = isDarkBg ? AppColors.pureWhite : AppColors.darkNavy;

    // A altura pedida pelas telas é a do CONTEÚDO. O widget soma o que varia
    // por dispositivo — status bar/notch e escala de fonte do sistema — e
    // limita ao tamanho da tela (ex.: landscape em celulares pequenos), para
    // o header não estourar em telas pequenas nem sobrar em desktop.
    final textScale = mq.textScaler.scale(1.0).clamp(1.0, 1.3);
    final effectiveExpandedHeight = (expandedHeight * textScale + mq.padding.top)
        .clamp(0.0, mq.size.height * 0.85);

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
                  padding: const EdgeInsets.only(right: 8.0),
                  child: TextButton.icon(
                    onPressed: action.onPressed,
                    icon: Icon(
                      action.icon,
                      color: action.color ?? contentColor,
                    ),
                    label: Text(
                      action.label,
                      style: TextStyle(color: action.color ?? contentColor),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: isDarkBg
                          ? AppColors.pureWhite.withValues(alpha: 0.1)
                          : AppColors.darkNavy.withValues(alpha: 0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: ClipRect(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.deepTurquoise,
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: mq.size.width * .005,
                colors: [Colors.transparent, Colors.black54, Colors.black],
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
                    padding: const EdgeInsets.symmetric(horizontal: 20),
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
                                    const SizedBox(width: 12),
                                  ],
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                color: contentColor.withValues(
                                                  alpha: 0.7,
                                                ),
                                                fontWeight: FontWeight.w500,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (chips.isNotEmpty) ...[
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
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
                                const SizedBox(height: 4),
                                // FittedBox encolhe valores longos (ex.:
                                // "R$ 123.456,78") em telas estreitas em vez
                                // de quebrar linha ou estourar.
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    subtitle!,
                                    maxLines: 1,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          color: subtitleColor ?? contentColor,
                                          letterSpacing: -0.5,
                                          fontSize: isSmallWidth ? 42 : 60,
                                        ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (!isSmallWidth && sideContent != null) ...[
                          const SizedBox(width: 32),
                          SizedBox(
                            // Encolhe o painel lateral em larguras
                            // intermediárias (tablets/janela estreita).
                            width: (mq.size.width * 0.3).clamp(220.0, 300.0),
                            child: sideContent!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isSmallWidth && sideContent != null) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: sideContent!,
                    ),
                  ],
                  if (isSmallWidth && actions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: actions
                            .map(
                              (action) => Padding(
                                padding: const EdgeInsets.only(right: 8.0),
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
                    const SizedBox(height: 20),
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
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: contentColor,
                        fontWeight: FontWeight.bold,
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

  Widget _buildMembersList(
    BuildContext context,
    List<UserModel> members,
    bool isDarkBg,
  ) {
    const double avatarRadius = 14;
    const double overlap = 8.0;

    return SizedBox(
      height: avatarRadius * 2,
      child: Stack(
        children: [
          for (int i = 0; i < members.length; i++)
            Positioned(
              left: i * (avatarRadius * 2 - overlap),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDarkBg ? AppColors.darkNavy : AppColors.pureWhite,
                    width: 2,
                  ),
                ),
                child: UserAvatar(
                  displayName: members[i].displayName,
                  photoUrl: members[i].photoUrl,
                  radius: avatarRadius,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileAction(
    BuildContext context,
    DetailHeaderAction action,
    bool isDarkBg,
  ) {
    final theme = Theme.of(context);
    final contentColor = isDarkBg ? AppColors.pureWhite : AppColors.darkNavy;

    return InkWell(
      onTap: action.onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDarkBg
              ? AppColors.pureWhite.withValues(alpha: 0.15)
              : AppColors.darkNavy.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkBg
                ? AppColors.pureWhite.withValues(alpha: 0.1)
                : AppColors.darkNavy.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(action.icon, size: 18, color: action.color ?? contentColor),
            const SizedBox(width: 8),
            Text(
              action.label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: action.color ?? contentColor,
                fontWeight: FontWeight.bold,
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
    final isDarkBg = (chip.backgroundColor ?? bgColor).computeLuminance() < 0.5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:
            chip.backgroundColor ??
            (isDarkBg
                ? AppColors.pureWhite.withValues(alpha: 0.15)
                : AppColors.darkNavy.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            chip.icon,
            size: 14,
            color: isDarkBg ? AppColors.pureWhite : AppColors.vibrantTeal,
          ),
          const SizedBox(width: 6),
          Text(
            chip.label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDarkBg ? AppColors.pureWhite : AppColors.darkNavy,
            ),
          ),
        ],
      ),
    );
  }
}
