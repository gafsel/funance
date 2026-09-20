import 'dart:math';

import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';

/// A celebração de semana zerada: ícones subindo atrás do recado.
///
/// A festa é sorteada uma vez no `initState` e não a cada frame — com 20
/// ícones, sortear posição e cor dentro do `build` faria a chuva piscar
/// aleatoriamente em vez de subir.
class SuccessEmptyState extends StatefulWidget {
  const SuccessEmptyState({super.key});

  @override
  State<SuccessEmptyState> createState() => _SuccessEmptyStateState();
}

class _SuccessEmptyStateState extends State<SuccessEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_FloatingIcon> _icons = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    final List<IconData> iconOptions = [
      Icons.star,
      Icons.favorite,
      Icons.celebration,
      Icons.auto_awesome,
      Icons.savings,
      Icons.rocket_launch,
      Icons.workspace_premium,
    ];

    for (int i = 0; i < 20; i++) {
      _icons.add(
        _FloatingIcon(
          icon: iconOptions[_random.nextInt(iconOptions.length)],
          color: [
            AppColors.surfaceDeep,
            AppColors.tealInk,
            AppColors.gold,
            AppColors.goldDeep,
            AppColors.violet,
          ][_random.nextInt(5)],
          size: 12.0 + _random.nextDouble() * 20.0,
          speed: 0.3 + _random.nextDouble() * 0.7,
          xRelative: _random.nextDouble(),
          yRelative: _random.nextDouble(),
          delay: _random.nextDouble(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final l10n = context.l10n;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xl,
            horizontal: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: palette.paper2,
            borderRadius: AppRadius.brLg,
            border: Border.all(color: palette.line),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: Stack(
                      children: _icons.map((floating) {
                        // Animação individual baseada no delay e velocidade
                        final localProgress =
                            (_controller.value + floating.delay) % 1.0;

                        final x = floating.xRelative * constraints.maxWidth;
                        // Inicia de baixo (150) e vai para cima (-50)
                        final y = (1.0 - localProgress) * 200 - 25;

                        // Opacidade: fade in rápido no início, fade out no final
                        double opacity = 0.0;
                        if (localProgress < 0.2) {
                          opacity = localProgress / 0.2;
                        } else if (localProgress > 0.8) {
                          opacity = (1.0 - localProgress) / 0.2;
                        } else {
                          opacity = 1.0;
                        }

                        return Positioned(
                          left: x,
                          top: y,
                          child: Opacity(
                            opacity: opacity.clamp(0.0, 1.0),
                            child: Icon(
                              floating.icon,
                              color: floating.color.withValues(alpha: 0.5),
                              size: floating.size,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.task_alt_rounded, size: 64, color: palette.ink),
                  AppSpacing.gapMd,
                  Text(
                    l10n.weeklyMissionsSuccessTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: palette.ink,
                    ),
                  ),
                  AppSpacing.gapXs,
                  Padding(
                    padding: AppSpacing.hLg,
                    child: Text(
                      l10n.weeklyMissionsSuccessMessage,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FloatingIcon {
  final IconData icon;
  final Color color;
  final double size;
  final double speed;
  final double xRelative;
  final double yRelative;
  final double delay;

  _FloatingIcon({
    required this.icon,
    required this.color,
    required this.size,
    required this.speed,
    required this.xRelative,
    required this.yRelative,
    required this.delay,
  });
}
