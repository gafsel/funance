import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_durations.dart';
import '../theme/app_elevation.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// O aviso de conquista.
///
/// É o canal **separado do erro**. O app mostrava badge desbloqueada num
/// `SnackBar` comum — o mesmo widget, com o mesmo peso visual, que anuncia
/// falha de escrita — e não mostrava nada ao concluir uma missão. Aqui a
/// conquista tem forma própria: aro e halo dourados, entrada com um leve
/// ultrapasso, e saída sozinha.
///
/// O halo é a única sombra colorida do app ([AppElevation.reward]) e só
/// aparece em [major] — se toda subida de XP brilhasse, o brilho deixaria de
/// significar conquista.
///
/// Respeita "reduzir movimento": com a preferência ligada, o toast aparece
/// pronto, sem escala nem deslocamento, e ainda assim some sozinho.
class RewardToast extends StatefulWidget {
  const RewardToast({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.xpLabel,
    this.major = false,
    this.onDismiss,
    this.onTap,
    this.dwell = AppDurations.toastDwell,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// "+40 XP", já traduzido.
  final String? xpLabel;

  /// Conquista de peso (badge, patente, nível): ganha o halo dourado.
  final bool major;

  final VoidCallback? onDismiss;
  final VoidCallback? onTap;

  /// Quanto tempo fica na tela.
  final Duration dwell;

  @override
  State<RewardToast> createState() => _RewardToastState();
}

class _RewardToastState extends State<RewardToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.celebrate,
    reverseDuration: AppDurations.normal,
  );

  /// As duas curvas do toast, criadas UMA vez.
  ///
  /// Elas nasciam dentro do `builder` do `AnimatedBuilder` — ou seja, um
  /// `CurvedAnimation` novo por frame, cada um se inscrevendo no controller e
  /// nenhum sendo descartado. Numa rajada de três toasts de 700ms isso são
  /// centenas de objetos e centenas de listeners vivos até o controller
  /// morrer; o `flutter_test` reclama de `CurvedAnimation` não descartado
  /// desde que passou a rastreá-los.
  late final CurvedAnimation _motion = CurvedAnimation(
    parent: _controller,
    curve: AppDurations.curveReward,
    reverseCurve: AppDurations.curveExit,
  );

  late final CurvedAnimation _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  Timer? _exitTimer;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    // O agendamento da saída vive no `initState` e não num `Future.delayed`
    // solto: se o widget sair da árvore antes (troca de tela, `dismissAll`),
    // o controller é descartado e o timer morre com ele.
    _controller.forward();
    _controller.addStatusListener(_onStatus);
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_leaving) {
      _scheduleExit();
    } else if (status == AnimationStatus.dismissed && _leaving) {
      widget.onDismiss?.call();
    }
  }

  void _scheduleExit() {
    // Um `Timer` que o `dispose` cancela, e não um `Future.delayed` solto: um
    // toast na tela quando a árvore é desmontada (troca de rota, logout, fim
    // de um teste) deixaria o atraso pendurado.
    _exitTimer?.cancel();
    _exitTimer = Timer(widget.dwell, () {
      if (!mounted || _leaving) return;
      _leaving = true;
      _controller.reverse();
    });
  }

  void _dismissNow() {
    if (_leaving) return;
    _leaving = true;
    _exitTimer?.cancel();
    _controller.reverse();
  }

  @override
  void dispose() {
    _exitTimer?.cancel();
    _controller.removeStatusListener(_onStatus);
    _motion.dispose();
    _fade.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduce = AppDurations.reduceMotion(context);

    final card = Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brPill,
        border: Border.all(
          color: AppColors.gold.withValues(alpha: widget.major ? 1 : 0.45),
          width: widget.major ? 2 : 1,
        ),
        boxShadow: widget.major
            ? AppElevation.reward
            : AppElevation.overlay(Brightness.dark),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: AppSpacing.allXxs,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(widget.icon, size: 18, color: AppColors.gold),
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.inkInverse,
                  ),
                ),
                if (widget.subtitle != null)
                  Text(
                    widget.subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.inkInverse2,
                    ),
                  ),
              ],
            ),
          ),
          if (widget.xpLabel != null) ...[
            const SizedBox(width: AppSpacing.xs),
            Text(
              widget.xpLabel!,
              style: AppTypography.counter(
                AppColors.gold,
              ).copyWith(fontSize: 14, height: 18 / 14),
            ),
          ],
        ],
      ),
    );

    // Um nó só para o leitor de tela: "Missão concluída. Planejar 5
    // categorias. +40 XP" é uma frase, não três fragmentos soltos.
    // `liveRegion` faz o anúncio acontecer sem o usuário ter que procurar.
    final tappable = Semantics(
      container: true,
      liveRegion: true,
      button: true,
      excludeSemantics: true,
      onTap: () {
        widget.onTap?.call();
        _dismissNow();
      },
      label: [widget.title, ?widget.subtitle, ?widget.xpLabel].join('. '),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: AppRadius.brPill,
          onTap: () {
            widget.onTap?.call();
            _dismissNow();
          },
          child: card,
        ),
      ),
    );

    if (reduce) {
      // Sem movimento: o toast aparece e desaparece com um fade curto, que é
      // o mínimo para não piscar na tela.
      return FadeTransition(opacity: _fade, child: tappable);
    }

    // Escuta a CURVA, não o controller: é o valor que o builder lê, e assim a
    // animação usada fica observável de fora (um teste consegue afirmar que
    // ela é a MESMA a cada frame).
    return AnimatedBuilder(
      animation: _motion,
      builder: (context, child) {
        final t = _motion.value;
        return Opacity(
          opacity: _controller.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, -16 * (1 - t)),
            child: Transform.scale(scale: 0.92 + 0.08 * t, child: child),
          ),
        );
      },
      child: tappable,
    );
  }
}
