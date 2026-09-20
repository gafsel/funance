import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_durations.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_spacing.dart';

/// Barra de vida de jogo de luta: preenchimento animado, **dano fantasma** e
/// uma faixa hachurada para o que está comprometido.
///
/// Por que em Flutter e não dentro do Flame: a barra precisa de texto
/// traduzido, de moeda formatada, de toque com área de alvo decente e dos
/// tokens do design system. Tudo isso o Flame faria à mão e pior.
///
/// O "dano fantasma" é a faixa VERMELHA que desce atrasada. Uma barra que só
/// encolhe informa o valor novo; a faixa que fica para trás por meio segundo
/// informa o TAMANHO DA MORDIDA, que é a coisa que o jogador quer sentir. É a
/// mesma leitura do Street Fighter, e é de lá que ela vem.
///
/// [mirrored] espelha tudo: o preenchimento cresce da direita para a
/// esquerda, o chanfro fica na ponta esquerda e o conteúdo alinha à direita.
/// É assim que a barra do monstro se opõe à dos heróis em vez de repeti-la.
///
/// O chanfro é cortado no recorte que envolve a barra INTEIRA, e por isso ele
/// vale para a calha e para o preenchimento ao mesmo tempo — as duas pontas
/// internas têm o mesmo bico. Um chanfro só no preenchimento deixaria um
/// dente retangular de calha sobrando quando a vida encolhesse.
class ArenaHpBar extends StatefulWidget {
  const ArenaHpBar({
    super.key,
    required this.ratio,
    required this.color,
    this.committedRatio = 0,
    this.mirrored = false,
    this.overflowing = false,
    this.pressed = false,
    this.depleted = false,
    this.height = _height,
  });

  /// Fração preenchida, 0..1.
  final double ratio;

  /// Fração hachurada, contada a partir da ponta CHEIA da barra: é a parte do
  /// que se tem que já tem dono.
  final double committedRatio;

  final Color color;

  /// Espelhada (a barra do monstro).
  final bool mirrored;

  /// A vida passou do máximo (receita acima do que saiu). A barra fica cheia
  /// e troca de cor — "overheal", o verde que diz que a semana está no azul.
  final bool overflowing;

  /// O comprometido passou do que existe em caixa.
  ///
  /// A hachura fica mais DENSA. É o único sinal possível quando a faixa já
  /// cobre a barra inteira: saturada em 100%, ela não tem mais para onde
  /// crescer, e uma barra cheia de hachura normal lê igual a "exatamente
  /// comprometido" — que é outra situação.
  final bool pressed;

  /// A vida ACABOU: a calha pulsa em vermelho e a moldura vai junto.
  ///
  /// O dono: *"a barra vazia não chama muita atenção, já uma barra piscando
  /// em vermelho chamaria e indicaria o perigo"*. Uma barra vazia e parada é
  /// indistinguível de uma barra que ninguém desenhou — foi o mesmo problema
  /// que deu à calha uma cor própria e à barra uma moldura. Parada ela diz
  /// "não há vida aqui"; pulsando ela diz "isto está errado AGORA".
  ///
  /// É uma BANDEIRA de quem chama, e não `ratio <= 0` lido aqui dentro: a
  /// barra do monstro também chega a zero, e lá o zero é a melhor notícia da
  /// semana — o bicho morreu. Um alarme vermelho no lugar do "Derrotado"
  /// diria o contrário do que aconteceu.
  final bool depleted;

  final double height;

  static const double _height = 14;

  /// Quanto a ponta interna é chanfrada, em pixels. Dá às duas barras o
  /// bico que as faz se enfrentarem no centro.
  static const double chamfer = 10;

  @override
  State<ArenaHpBar> createState() => _ArenaHpBarState();
}

class _ArenaHpBarState extends State<ArenaHpBar>
    with SingleTickerProviderStateMixin {
  /// O pulso do alarme: um ciclo por segundo, ida e volta.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  late final Animation<double> _alarm = CurvedAnimation(
    parent: _pulse,
    curve: Curves.easeInOut,
  );

  @override
  void didUpdateWidget(ArenaHpBar old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  /// Liga e desliga o alarme.
  ///
  /// Vida acima de zero não agenda quadro nenhum: o placar fica na tela a
  /// sessão inteira, e um ticker vivo por uma barra que não pisca é bateria
  /// gasta em pixel parado.
  void _sync() {
    final moves =
        widget.depleted &&
        !AppDurations.reduceMotion(context) &&
        TickerMode.valuesOf(context).enabled;

    if (moves && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!moves && _pulse.isAnimating) {
      // Parar no CHEIO, e não no zero: com "reduzir movimento" ligado no meio
      // do ciclo, uma calha meio vermelha leria como meio perigo.
      _pulse
        ..stop()
        ..value = 1;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final reduce = AppDurations.reduceMotion(context);
    final fill = widget.overflowing ? palette.successText : widget.color;

    // O chanfro é cortado no espaço do FILHO e só depois espelhado: assim o
    // bico fica sempre na ponta voltada para o centro, com um clipper só.
    //
    // A MOLDURA é desenhada por fora do recorte, sobre o mesmo caminho: é ela
    // que diz onde a barra está quando a vida acaba. Sem ela, uma barra vazia
    // lia igual a "não há barra nenhuma aqui" — ver
    // `test/arena/arena_contrast_test.dart`.
    return Transform.flip(
      flipX: widget.mirrored,
      child: CustomPaint(
        foregroundPainter: _FramePainter(
          color: widget.depleted ? AppColors.danger : AppColors.gameFrame,
          // Sem pulso, o contorno é quem carrega o alarme sozinho: mais
          // grosso, ele diz "olhe aqui" sem se mexer.
          strokeWidth: widget.depleted && reduce ? 2.5 : 1.5,
        ),
        child: ClipPath(
          clipper: const _ChamferClipper(),
          child: SizedBox(
            height: widget.height,
            // `StackFit.expand` é obrigatório, não estilo: num `Stack` frouxo
            // o `FractionallySizedBox` recebe altura nenhuma, e o `ColoredBox`
            // dentro dele não tem tamanho próprio — a barra desenhava com
            // ZERO de altura e a tela mostrava só a calha escura, com os
            // números certos ao lado.
            child: Stack(
              fit: StackFit.expand,
              children: [
                // A calha tem cor PRÓPRIA. Na rodada 1 era o mesmo
                // `surfaceDeep` do bloco, e uma barra quase vazia não tinha
                // onde terminar: "5% de vida" lia igual a "não há barra
                // nenhuma aqui".
                const ColoredBox(color: AppColors.gameTrough),
                // O ALARME: vermelho por cima da calha, com a opacidade
                // indo e voltando. Fica ABAIXO do preenchimento e da
                // hachura de propósito — quando a vida volta, o alarme sai
                // de cena sem ter pintado nada por cima dela.
                if (widget.depleted)
                  AnimatedBuilder(
                    animation: _alarm,
                    builder: (context, child) => ColoredBox(
                      color: AppColors.danger.withValues(
                        alpha: reduce ? 1 : 0.35 + 0.65 * _alarm.value,
                      ),
                    ),
                  ),
                // 1. O fantasma: mesma fração, mas com atraso e mais devagar.
                //    Fica POR BAIXO do preenchimento, então só aparece no
                //    rastro do que encolheu.
                _Fill(
                  ratio: widget.ratio,
                  color: palette.dangerText,
                  duration: reduce
                      ? Duration.zero
                      : const Duration(milliseconds: 900),
                  curve: const Interval(0.45, 1, curve: Curves.easeOut),
                ),
                _Fill(
                  ratio: widget.ratio,
                  color: fill,
                  duration: AppDurations.respectingMotion(
                    context,
                    AppDurations.celebrate,
                  ),
                  curve: AppDurations.curve,
                ),
                // 2. A faixa comprometida: hachura, e não uma cor chapada.
                //    Cor chapada leria como "outra vida"; a hachura lê como
                //    "reservado". Ela mora na ponta CHEIA da barra porque o
                //    que tem dono é a primeira coisa que sai.
                if (widget.committedRatio > 0)
                  _CommittedBand(
                    extent: widget.committedRatio,
                    color: widget.pressed
                        ? palette.dangerText
                        : palette.onGame2,
                    dense: widget.pressed,
                    duration: AppDurations.respectingMotion(
                      context,
                      AppDurations.celebrate,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// O quadro claro em volta da barra, no mesmo bico do recorte.
class _FramePainter extends CustomPainter {
  const _FramePainter({required this.color, required this.strokeWidth});

  final Color color;

  /// 1,5 e não 1: num aparelho de densidade alta uma linha de um ponto some
  /// contra o preenchimento claro do herói.
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      const _ChamferClipper().getClip(size),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  bool shouldRepaint(_FramePainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}

/// O bico da ponta interna.
///
/// O corte é sempre na DIREITA do filho; o `Transform.flip` de quem usa a
/// barra é que o leva para a esquerda na barra do monstro. Um clipper só, e o
/// bico sempre voltado para o centro.
class _ChamferClipper extends CustomClipper<Path> {
  const _ChamferClipper();

  @override
  Path getClip(Size size) {
    final cut = ArenaHpBar.chamfer.clamp(0.0, size.width / 2);

    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width - cut, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(_ChamferClipper oldClipper) => false;
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

/// A faixa hachurada do que está comprometido, ancorada no COMEÇO da barra.
class _CommittedBand extends StatelessWidget {
  const _CommittedBand({
    required this.extent,
    required this.color,
    required this.duration,
    this.dense = false,
  });

  final double extent;
  final Color color;
  final Duration duration;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: extent.clamp(0.0, 1.0)),
      duration: duration,
      curve: AppDurations.curve,
      // `heightFactor: 1` é obrigatório: um `Align` entrega restrição frouxa
      // ao filho, e sem a fração de altura a cadeia colapsa para zero — a
      // faixa some sem erro nenhum, que foi exatamente o que aconteceu.
      builder: (context, value, child) => Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: value,
          heightFactor: 1,
          child: CustomPaint(
            painter: _HatchPainter(color, dense: dense),
            // Um `CustomPaint` sem filho prefere `Size.zero`; o filho
            // expandido é o que o faz ocupar a faixa inteira.
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _HatchPainter extends CustomPainter {
  const _HatchPainter(this.color, {required this.dense});

  final Color color;

  /// Rombo: traços mais juntos, mais opacos e SEM o véu por baixo.
  ///
  /// Os três andam juntos, e o motivo é uma conta de tinta. A hachura normal
  /// é um traço a 50% sobre um véu escuro a 50% sobre o preenchimento: três
  /// camadas translúcidas que somam para o cinza, que é o que ela quer —
  /// "reservado". No rombo a cor É a informação, e o mesmo empilhamento
  /// comia o vermelho: medido no golden, #4A4544 — cinza puro, sem sinal
  /// nenhum de perigo.
  ///
  /// Sem o véu e a 85%, o traço chega à tela quase como ele mesmo.
  final bool dense;

  /// Distância entre traços. Fixa em pontos lógicos de propósito: uma hachura
  /// proporcional à largura muda de densidade conforme o valor, e aí ela
  /// passaria a parecer uma informação onde não é.
  static const double step = 6;
  static const double denseStep = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: dense ? 0.85 : 0.5)
      ..strokeWidth = 2;

    // O véu escurece o preenchimento para a hachura normal ler como
    // "reservado". No rombo ele é justamente o que mata a cor.
    if (!dense) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = AppColors.gameTrough.withValues(alpha: 0.5),
      );
    }

    final passo = dense ? denseStep : step;

    for (var x = -size.height; x < size.width; x += passo) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_HatchPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.dense != dense;
}

/// O marcador redondo do centro: o relógio da luta.
///
/// No Street Fighter é o tempo que resta no round. Aqui é o dia da semana —
/// "4/7", quarta-feira — porque é a mesma informação: quanto ainda dá para
/// reagir antes de o placar fechar.
class ArenaDayMarker extends StatelessWidget {
  const ArenaDayMarker({
    super.key,
    required this.label,
    required this.semanticsLabel,
    this.diameter = 40,
  });

  final String label;
  final String semanticsLabel;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return Semantics(
      label: semanticsLabel,
      child: Container(
        width: diameter,
        height: diameter,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceDeep,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.gold, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxs),
          child: FittedBox(
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: palette.onGame,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
