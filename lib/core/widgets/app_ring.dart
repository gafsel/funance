import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_progress_bar.dart';

/// O anel de progresso do app: um arco, uma calha e o que estiver no meio.
///
/// Ele é o equivalente circular de [AppProgressBar], e existe pelo mesmo
/// motivo que ela: o app tinha o mesmo desenho feito de três jeitos — o anel
/// dos aldeões do rodapé da Arena (um `CustomPaint` próprio), o anel dos
/// desafios da Party (um `CircularProgressIndicator` com `backgroundColor` a
/// 10%) e, agora, a grade de aldeões da folha da vila. Três implementações do
/// mesmo dado divergem; é a lição que já custou catorze barras de progresso
/// diferentes a este projeto.
///
/// **Não é o `CircularProgressIndicator` do Material**, e as razões são as
/// mesmas que tiraram o anel do rodapé de lá:
///
/// 1. ele não aceita cor de CALHA de verdade — o trilho vazio é sempre uma
///    versão translúcida da tinta, e sobre a superfície de jogo isso some;
/// 2. ele desenha o arco com ponta reta, e a ponta arredondada é o que faz um
///    anel de 4 px parecer desenhado e não cortado;
/// 3. com `value` fixo ele ainda mantém um `Ticker` vivo, e uma grade de
///    dezoito aldeões seriam dezoito tickers para desenhar dezoito arcos
///    parados.
///
/// Toda cor vem de quem chama; nenhuma decisão de tinta é tomada aqui dentro.
class AppRing extends StatelessWidget {
  const AppRing({
    super.key,
    required this.value,
    required this.color,
    this.size = 40,
    this.stroke = 4,
    this.trackColor,
    this.child,
    this.semanticLabel,
  });

  /// O caso mais comum: um ícone em cápsula redonda dentro do anel.
  ///
  /// A tinta do ÍCONE é separada da do anel de propósito. No desafio da Party
  /// e no aldeão da vila o anel mostra o estado (verde, âmbar, vermelho) e o
  /// miolo mostra a CATEGORIA (a cor que o usuário escolheu para ela) — se as
  /// duas fossem a mesma, a grade inteira mudaria de cor junto e o usuário
  /// perderia a única pista de qual aldeão é qual.
  AppRing.icon({
    Key? key,
    required double value,
    required Color color,
    required IconData icon,
    required Color iconColor,
    double size = 40,
    double stroke = 4,
    Color? trackColor,
    String? semanticLabel,
  }) : this(
         key: key,
         value: value,
         color: color,
         size: size,
         stroke: stroke,
         trackColor: trackColor,
         semanticLabel: semanticLabel,
         child: _RingIcon(icon: icon, color: iconColor, size: size),
       );

  /// De 0 a 1. Fora da faixa é preso — um aldeão que estourou o orçamento
  /// mostra o anel cheio, não um anel maior que a calha.
  final double value;

  final Color color;
  final double size;
  final double stroke;

  /// A cor da CALHA. `null` usa a própria tinta a 20%, que é o mesmo trilho
  /// de [AppProgressBar] — um anel e uma barra do mesmo assunto na mesma tela
  /// não podem ter trilhos de opacidades diferentes.
  final Color? trackColor;

  final Widget? child;

  /// O que o leitor de tela ouve. `null` não cria nó nenhum: um anel dentro
  /// de um bloco que já se descreve só acrescentaria um "62%" solto no meio
  /// da leitura — a mesma regra de [AppProgressBar].
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final fraction = value.isFinite ? value.clamp(0.0, 1.0) : 0.0;

    final ring = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: AppRingPainter(
          progress: fraction,
          color: color,
          stroke: stroke,
          trackColor: trackColor ?? AppProgressBar.trackFor(color),
        ),
        child: child == null ? null : Center(child: child),
      ),
    );

    if (semanticLabel == null) return ring;

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: semanticLabel,
      value: '${(fraction * 100).round()}%',
      child: ring,
    );
  }
}

/// O pintor do anel. Público para que o rodapé da Arena — que precisa de uma
/// calha própria, a da superfície de jogo — use o MESMO arco em vez de
/// manter o seu.
class AppRingPainter extends CustomPainter {
  const AppRingPainter({
    required this.progress,
    required this.color,
    required this.stroke,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final double stroke;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (math.min(size.width, size.height) - stroke) / 2;

    final trough = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = trackColor;

    canvas.drawCircle(center, radius, trough);

    if (progress <= 0) return;

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      // Começa no topo e anda no sentido do relógio: é como um mostrador se
      // lê, e um anel sem legenda depende de o usuário entender isso sozinho.
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(AppRingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.stroke != stroke ||
      old.trackColor != trackColor;
}

/// O miolo do [AppRing.icon]: o ícone numa cápsula redonda da própria tinta.
class _RingIcon extends StatelessWidget {
  const _RingIcon({
    required this.icon,
    required this.color,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    // A cápsula ocupa o espaço DENTRO do arco, com folga; o ícone, a metade
    // do anel. Proporções e não números fixos: o mesmo miolo serve o anel de
    // 40 px da Party e o de 48 da grade de aldeões.
    return Container(
      width: size * 0.72,
      height: size * 0.72,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: size * 0.42, color: color),
    );
  }
}
