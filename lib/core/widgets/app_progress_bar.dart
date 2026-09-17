import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_durations.dart';
import '../theme/app_gradients.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';

/// Espessura da barra, pelo papel que ela cumpre.
enum AppProgressSize {
  /// Linha fina sob um tile: saldo de conta, progresso discreto.
  thin(4),

  /// Padrão: missão, meta, categoria, XP.
  medium(8),

  /// Barra que é o próprio assunto do bloco: nível, pool, Bússola.
  thick(12);

  const AppProgressSize(this.height);

  final double height;
}

/// A barra de progresso do app.
///
/// Substitui as 14 implementações independentes — oito
/// `LinearProgressIndicator` com alturas 4/8/12/15, raios 0/2/4/8 e fundos de
/// 10/12/24/30/100% de opacidade, mais três barras feitas à mão com `Stack` +
/// `FractionallySizedBox` e duas barras segmentadas do 50/30/20 que
/// desenhavam o mesmo dado com dois raios e dois mecanismos diferentes.
///
/// O preenchimento padrão é o gradiente de progresso (verde → teal): quem está
/// no começo da barra não recebe a cor da chegada. A animação é de 220 ms e
/// respeita "reduzir movimento".
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.size = AppProgressSize.medium,
    this.color,
    this.trackColor,
    this.semanticLabel,
    this.animate = true,
  });

  /// Barra de recompensa: dourada, para XP e nível.
  const AppProgressBar.reward({
    Key? key,
    required double value,
    AppProgressSize size = AppProgressSize.medium,
    String? semanticLabel,
  }) : this(
         key: key,
         value: value,
         size: size,
         color: AppColors.gold,
         semanticLabel: semanticLabel,
       );

  /// Fração de 0 a 1. Valores fora da faixa são presos — uma categoria
  /// estourada mostra a barra cheia, não uma barra maior que o trilho.
  final double value;

  final AppProgressSize size;

  /// Cor sólida do preenchimento. `null` usa o gradiente de progresso.
  final Color? color;

  /// Cor do trilho. `null` usa a linha do tema.
  final Color? trackColor;

  final String? semanticLabel;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final fraction = value.isFinite ? value.clamp(0.0, 1.0) : 0.0;
    // Pílula: o raio acompanha a altura sem precisar de um número por
    // espessura — `brPill` satura na metade da menor dimensão.
    const radius = AppRadius.brPill;

    final bar = ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: size.height,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(color: trackColor ?? palette.line),
            ),
            _Fill(
              fraction: fraction,
              color: color,
              radius: radius,
              animate: animate && !AppDurations.reduceMotion(context),
            ),
          ],
        ),
      ),
    );

    return Semantics(
      label: semanticLabel,
      value: '${(fraction * 100).round()}%',
      child: bar,
    );
  }
}

class _Fill extends StatelessWidget {
  const _Fill({
    required this.fraction,
    required this.color,
    required this.radius,
    required this.animate,
  });

  final double fraction;
  final Color? color;
  final BorderRadius radius;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    Widget paint(double f) {
      if (f <= 0) return const SizedBox.shrink();
      return Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: f,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              gradient: color == null ? AppGradients.progress : null,
              borderRadius: radius,
            ),
          ),
        ),
      );
    }

    if (!animate) return paint(fraction);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: fraction),
      duration: AppDurations.normal,
      curve: AppDurations.curve,
      builder: (context, animated, _) => paint(animated),
    );
  }
}

/// Um segmento da barra de pools do 50/30/20.
@immutable
class PoolSegment {
  const PoolSegment({required this.fraction, required this.color, this.label});

  /// Quanto do total este pool ocupa, de 0 a 1.
  final double fraction;
  final Color color;

  /// O que escrever DENTRO do segmento — na prática, a porcentagem real.
  ///
  /// Só aparece quando o segmento é largo o bastante para caber
  /// ([AppPoolBar.labelThreshold]); abaixo disso vira um "3%" cortado ao
  /// meio, que é pior do que não ter rótulo. Independente disso, o rótulo
  /// entra sempre na descrição para leitor de tela.
  final String? label;
}

/// A barra segmentada dos pools 50/30/20.
///
/// Havia duas implementações do mesmo dado — uma estática com raio 8 e uma
/// animada com raio 6. Esta é uma só, com os raios do design system e a
/// mesma curva do resto do app.
class AppPoolBar extends StatelessWidget {
  const AppPoolBar({
    super.key,
    required this.segments,
    this.height = 12,
    this.gap = 2,
    this.semanticLabel,
  });

  /// Atalho para a divisão canônica, na ordem 50 / 30 / 20.
  AppPoolBar.standard({
    Key? key,
    required double needs,
    required double wants,
    required double future,
    double height = 12,
    String? semanticLabel,
  }) : this(
         key: key,
         height: height,
         semanticLabel: semanticLabel,
         segments: [
           PoolSegment(fraction: needs, color: AppColors.pool50),
           PoolSegment(fraction: wants, color: AppColors.pool30),
           PoolSegment(fraction: future, color: AppColors.pool20),
         ],
       );

  final List<PoolSegment> segments;
  final double height;
  final double gap;
  final String? semanticLabel;

  /// A partir de quanto do trilho um segmento carrega o próprio rótulo.
  ///
  /// A barra antiga do 50/30/20 escrevia a porcentagem real dentro de cada
  /// faixa, e era a única forma de ler "gastei 62% no essencial" sem abrir a
  /// tela de detalhe — a legenda embaixo mostra o alvo (50/30/20), não o que
  /// aconteceu. A migração para este componente perdeu esse rótulo, e com ele
  /// o sentido do cartão.
  ///
  /// Ele volta com um piso: a 15% do trilho, numa barra de 16px de altura, um
  /// rótulo de 11px cabe com folga em qualquer largura de celular. Abaixo
  /// disso ele seria elidido ou vazaria para o segmento vizinho, e um número
  /// pela metade mente mais do que a ausência dele. O dado nunca se perde:
  /// quem usa leitor de tela ouve todas as faixas, largas ou não.
  static const double labelThreshold = 0.15;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final total = segments.fold<double>(
      0,
      (sum, s) => sum + (s.fraction.isFinite ? s.fraction.clamp(0.0, 1.0) : 0),
    );
    final visible = segments
        .where((s) => s.fraction.isFinite && s.fraction > 0)
        .toList(growable: false);

    final spoken = <String>[
      ?semanticLabel,
      for (final s in visible) ?s.label,
    ].join(', ');

    return Semantics(
      label: spoken.isEmpty ? null : spoken,
      // Os rótulos DESENHADOS ficam de fora da árvore de acessibilidade: o
      // `label` acima já diz as faixas todas, e sem isto o leitor de tela
      // lia a barra duas vezes — "Essenciais 62%, Conforto 25%, Futuro 3%" e
      // logo depois "Essenciais 62%. Conforto 25%.", só as largas o
      // bastante para terem rótulo na tela. Pior que a repetição era a
      // incoerência: a segunda leitura omitia justamente o pool estreito.
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: AppRadius.brXs,
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: palette.line)),
                if (visible.isNotEmpty)
                  Row(
                    children: [
                      for (var i = 0; i < visible.length; i++) ...[
                        Expanded(
                          flex: (visible[i].fraction * 1000).round(),
                          child: ColoredBox(
                            color: visible[i].color,
                            child: _label(context, visible[i]),
                          ),
                        ),
                        if (i < visible.length - 1) SizedBox(width: gap),
                      ],
                      // O resto do trilho, quando os pools não somam o total.
                      if (total < 1)
                        Expanded(
                          flex: ((1 - total) * 1000).round(),
                          child: const SizedBox.shrink(),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// O rótulo dentro do segmento, quando ele couber.
  ///
  /// A tinta sai da luminância da própria faixa: `pool30` é um âmbar claro e
  /// `pool50` um teal escuro, e uma cor fixa deixaria uma das duas ilegível.
  Widget _label(BuildContext context, PoolSegment segment) {
    final label = segment.label;
    if (label == null || segment.fraction < labelThreshold) {
      return const SizedBox.shrink();
    }

    return Center(
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: AppColors.inkOn(segment.color)),
      ),
    );
  }
}
