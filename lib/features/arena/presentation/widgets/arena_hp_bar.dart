import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_durations.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/widgets/animated_double.dart';

/// Barra de vida do gênero: preenchimento animado, **dano fantasma** e uma
/// faixa hachurada para o que está comprometido.
///
/// Por que em Flutter e não dentro do Flame: a barra precisa de texto
/// traduzido, de moeda formatada, de toque com área de alvo decente e dos
/// tokens do design system. Tudo isso o Flame faria à mão e pior.
///
/// O "dano fantasma" é a faixa clara que desce ATRASADA. Uma barra que só
/// encolhe informa o valor novo; a faixa que fica para trás por meio segundo
/// informa o TAMANHO DA MORDIDA, que é a coisa que o jogador quer sentir.
class ArenaHpBar extends StatelessWidget {
  const ArenaHpBar({
    super.key,
    required this.label,
    required this.value,
    required this.ratio,
    required this.color,
    this.committedRatio = 0,
    this.trailing,
    this.onTap,
    this.semanticsHint,
  });

  /// Nome da barra ("Vida", "Monstro da semana").
  final String label;

  /// O número que rola ao lado do rótulo.
  final double value;

  /// Fração preenchida, 0..1.
  final double ratio;

  /// Fração hachurada logo depois do preenchimento, 0..1.
  final double committedRatio;

  final Color color;

  /// Selo à direita: "Enfurecido: +R$ 640 atrasado", "Fugiu ferido".
  final Widget? trailing;

  final VoidCallback? onTap;
  final String? semanticsHint;

  static const double _height = 14;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final reduce = AppDurations.reduceMotion(context);

    return Semantics(
      button: onTap != null,
      hint: semanticsHint,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brSm,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xxs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // `Wrap`, e não `Row`: o selo mais longo ("Enfurecido:
              // +R$ 1.234,56 atrasado") não cabe na mesma linha do rótulo e
              // do valor num celular. Com `Row` ele saía cortado em
              // "Enfureci…" — que não informa nada. Aqui ele desce para uma
              // segunda linha e continua legível.
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xxs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: palette.onGame2,
                    ),
                  ),
                  // O número NUNCA troca seco: ele rola. É o que faz um
                  // pagamento parecer um golpe e não um refresh.
                  AnimatedDouble.currency(
                    value,
                    duration: AppDurations.respectingMotion(
                      context,
                      AppDurations.celebrate,
                    ),
                    curve: AppDurations.curve,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: palette.onGame,
                    ),
                  ),
                  ?trailing,
                ],
              ),
              AppSpacing.gapXxs,
              ClipRRect(
                borderRadius: AppRadius.brSm,
                child: SizedBox(
                  height: _height,
                  // `StackFit.expand` é obrigatório, não estilo: num `Stack`
                  // frouxo o `FractionallySizedBox` recebe altura nenhuma, e
                  // o `ColoredBox` dentro dele não tem tamanho próprio — a
                  // barra desenhava com ZERO de altura e a tela mostrava só a
                  // calha escura, com os números certos ao lado.
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(color: AppColors.surfaceDeep),
                      // 1. O fantasma: mesma fração, mas com atraso e mais
                      //    devagar. Fica POR BAIXO do preenchimento, então só
                      //    aparece no rastro do que encolheu.
                      _Fill(
                        ratio: ratio,
                        color: color.withValues(alpha: 0.38),
                        duration: reduce
                            ? Duration.zero
                            : const Duration(milliseconds: 900),
                        curve: const Interval(0.4, 1, curve: Curves.easeOut),
                      ),
                      _Fill(
                        ratio: ratio,
                        color: color,
                        duration: AppDurations.respectingMotion(
                          context,
                          AppDurations.celebrate,
                        ),
                        curve: AppDurations.curve,
                      ),
                      // 2. A faixa comprometida: hachura, e não uma cor
                      //    chapada. Cor chapada leria como "outra vida"; a
                      //    hachura lê como "reservado".
                      if (committedRatio > 0)
                        _CommittedBand(
                          start: ratio,
                          extent: committedRatio,
                          color: palette.onGame2,
                          duration: AppDurations.respectingMotion(
                            context,
                            AppDurations.celebrate,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Fill extends StatelessWidget {
  const _Fill({
    required this.ratio,
    required this.color,
    required this.duration,
    required this.curve,
  });

  final double ratio;
  final Color color;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: ratio.clamp(0.0, 1.0)),
      duration: duration,
      curve: curve,
      builder: (context, value, child) => FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value,
        child: ColoredBox(color: color),
      ),
    );
  }
}

/// A faixa hachurada do que está comprometido.
class _CommittedBand extends StatelessWidget {
  const _CommittedBand({
    required this.start,
    required this.extent,
    required this.color,
    required this.duration,
  });

  final double start;
  final double extent;
  final Color color;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: start.clamp(0.0, 1.0)),
      duration: duration,
      curve: AppDurations.curve,
      // Três caixas fracionárias encadeadas, e as DUAS precisam de
      // `heightFactor: 1`: um `Align` entrega restrição frouxa ao filho, e
      // sem a fração de altura a cadeia inteira colapsa para zero — a faixa
      // some sem erro nenhum, que foi exatamente o que aconteceu.
      builder: (context, value, child) => Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: (value + extent).clamp(0.0, 1.0),
          heightFactor: 1,
          child: Align(
            alignment: Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: (value + extent) <= 0
                  ? 0
                  : (extent / (value + extent)).clamp(0.0, 1.0),
              heightFactor: 1,
              child: CustomPaint(
                painter: _HatchPainter(color),
                // Um `CustomPaint` sem filho prefere `Size.zero`; o filho
                // expandido é o que o faz ocupar a faixa inteira.
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HatchPainter extends CustomPainter {
  const _HatchPainter(this.color);

  final Color color;

  /// Distância entre traços. Fixa em pontos lógicos de propósito: uma hachura
  /// proporcional à largura muda de densidade conforme o valor, e aí ela
  /// passa a parecer uma informação — que não é.
  static const double step = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..strokeWidth = 2;

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = color.withValues(alpha: 0.12),
    );

    for (var x = -size.height; x < size.width; x += step) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_HatchPainter oldDelegate) => oldDelegate.color != color;
}
