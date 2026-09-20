import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';

class AnimatedSwitchingIcon extends ImplicitlyAnimatedWidget {
  final IconData icon;
  final double size;

  /// Cor do ícone. O padrão é a tinta principal do tema claro — o widget é
  /// `ImplicitlyAnimatedWidget` e interpola a cor num `forEachTween`, que roda
  /// fora do `build` e portanto sem `BuildContext`; quem precisa da cor do
  /// tema corrente passa explicitamente.
  final Color color;
  final String? semanticLabel;
  final TextDirection? textDirection;
  final List<Shadow>? shadows;

  const AnimatedSwitchingIcon(
    this.icon, {
    super.key,
    this.size = 24.0,
    this.color = AppColors.inkLight,
    this.semanticLabel,
    this.textDirection,
    this.shadows,
    required super.duration,
    super.curve = Curves.linear,
    super.onEnd,
  });

  @override
  ImplicitlyAnimatedWidgetState<AnimatedSwitchingIcon> createState() =>
      _AnimatedSwitchingIconState();
}

class _AnimatedSwitchingIconState
    extends ImplicitlyAnimatedWidgetState<AnimatedSwitchingIcon> {
  Tween<double>? _size;
  ColorTween? _color;
  Tween<double>? _rotation;
  IconData? _previousIcon;

  @override
  void initState() {
    super.initState();
    _previousIcon = widget.icon;
  }

  @override
  void didUpdateWidget(AnimatedSwitchingIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.icon != oldWidget.icon) {
      _previousIcon = oldWidget.icon;
    }
  }

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _size =
        visitor(
              _size,
              widget.size,
              (dynamic value) => Tween<double>(begin: value as double),
            )
            as Tween<double>?;

    _color =
        visitor(
              _color,
              widget.color,
              (dynamic value) => ColorTween(begin: value as Color),
            )
            as ColorTween?;

    // Para a rotação, sempre animamos de 0 a 2*PI (uma volta completa)
    // ou resetamos e animamos novamente se o ícone mudar.
    // Como queremos girar SEMPRE que mudar, podemos usar o progresso da animação.
    _rotation =
        visitor(
              _rotation,
              widget.icon != _previousIcon ? 1.0 : 0.0,
              (dynamic value) => Tween<double>(begin: 0.0),
            )
            as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final double progress = animation.value;
        final double currentSize = _size?.evaluate(animation) ?? widget.size;
        final Color currentColor = _color?.evaluate(animation) ?? widget.color;

        final bool isSwitching = widget.icon != _previousIcon && progress < 1.0;

        // Se o ícone não mudou ou a animação terminou, apenas renderizamos o ícone atual
        if (!isSwitching) {
          return _buildIcon(
            widget.icon,
            currentSize,
            currentColor,
            // Se a animação terminou (progress == 1.0), rotacionamos 2*PI (completo)
            // Se nunca mudou (progress == 0.0), rotacionamos 0.
            progress,
          );
        }

        // Se mudou, usamos Stack para fazer o cross-fade com opacidade
        return Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: (1.0 - progress).clamp(0.0, 1.0),
              child: _buildIcon(
                _previousIcon ?? widget.icon,
                currentSize,
                currentColor,
                progress,
              ),
            ),
            Opacity(
              opacity: progress.clamp(0.0, 1.0),
              child: _buildIcon(
                widget.icon,
                currentSize,
                currentColor,
                progress,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIcon(
    IconData icon,
    double size,
    Color color,
    double rotationProgress,
  ) {
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001) // Perspectiva
        ..rotateZ(rotationProgress * 2 * math.pi),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: size,
        color: color,
        semanticLabel: widget.semanticLabel,
        textDirection: widget.textDirection,
        shadows: widget.shadows,
      ),
    );
  }
}
