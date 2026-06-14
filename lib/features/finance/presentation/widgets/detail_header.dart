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
  final List<UserModel> members;
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
    this.members = const [],
    this.logo,
    this.sideContent,
    this.bottomContent,
    this.expandedHeight = 250,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallWidth = MediaQuery.of(context).size.width < 600;
    final effectiveBgColor = backgroundColor ?? theme.colorScheme.primary;
    final isDarkBg = effectiveBgColor.computeLuminance() < 0.5;
    final contentColor = isDarkBg ? AppColors.pureWhite : AppColors.darkNavy;
    final mq = MediaQuery.of(context);

    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      backgroundColor: AppColors.deepTurquoise,
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
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  effectiveBgColor,
                  effectiveBgColor.withValues(alpha: 0.5),
                  effectiveBgColor.withValues(alpha: 0.2),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: Stack(
              children: [
                if (isDarkBg) ...[
                  Positioned(
                    top: -60,
                    right: -60,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.pureWhite.withValues(alpha: 0.12),
                            AppColors.pureWhite.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -100,
                    left: -40,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.pureWhite.withValues(alpha: 0.08),
                            AppColors.pureWhite.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    left: 40,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.pureWhite.withValues(alpha: 0.05),
                            AppColors.pureWhite.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Positioned(
                    top: -40,
                    right: -40,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.darkNavy.withValues(alpha: 0.03),
                            AppColors.darkNavy.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                SafeArea(
                  child: Padding(
                    padding: EdgeInsetsGeometry.only(top: mq.padding.top + kToolbarHeight),
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
                                          child: Text(
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
                                        ),
                                      ],
                                    ),
                                    if (subtitle != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        subtitle!,
                                        style:
                                            (isSmallWidth
                                                    ? theme
                                                          .textTheme
                                                          .headlineSmall
                                                    : theme
                                                          .textTheme
                                                          .headlineLarge)
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w900,
                                                  color:
                                                      subtitleColor ??
                                                      contentColor,
                                                  letterSpacing: -0.5,
                                                ),
                                      ),
                                    ],
                                    if (chips.isNotEmpty ||
                                        members.isNotEmpty) ...[
                                      const SizedBox(height: 16),
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
                                          if (members.isNotEmpty)
                                            _buildMembersList(
                                              context,
                                              members,
                                              isDarkBg,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (!isSmallWidth && sideContent != null) ...[
                                const SizedBox(width: 32),
                                SizedBox(width: 300, child: sideContent!),
                              ],
                            ],
                          ),
                        ),
                        if (isSmallWidth && sideContent != null) ...[
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: sideContent!,
                          ),
                        ],
                        if (isSmallWidth && actions.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: actions
                                  .map(
                                    (action) => Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8.0,
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
                          const SizedBox(height: 20),
                          bottomContent!,
                        ],
                      ],
                    ),
                  ),
                ),
              ],
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
