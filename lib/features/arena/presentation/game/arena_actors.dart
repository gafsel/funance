import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';
import 'package:funances/features/arena/domain/models/arena_state.dart';
import 'package:funances/features/arena/presentation/game/arena_sprites.dart';
import 'package:funances/features/arena/presentation/game/arena_theme.dart';

/// Base dos bonecos: respiração e sombra.
///
/// A respiração é um seno na escala vertical — três linhas que separam "um
/// PNG parado na tela" de "uma criatura esperando". É a diferença que faz a
/// cena parecer viva antes de qualquer arte boa existir.
abstract class _BreathingActor extends SpriteComponent {
  _BreathingActor({
    required super.sprite,
    required super.position,
    required super.size,
    required this.theme,
    required this.breathPeriod,
    required this.breathDepth,
    super.priority,
  }) : super(anchor: Anchor.bottomCenter, paint: ArenaSprites.pixelPaint);

  final ArenaTheme theme;
  final double breathPeriod;
  final double breathDepth;

  double _clock = 0;

  /// Escala base — o tremor e o avanço multiplicam-se sobre ela.
  double _baseScale = 1;

  /// `true` enquanto a pose de "machucado" está ligada.
  bool _slouching = false;

  /// `false` quando o boneco está NO CHÃO.
  ///
  /// Duas coisas dependem disto, e as duas denunciavam um cadáver vivo: a
  /// respiração — um corpo caído que sobe e desce continua respirando — e a
  /// sombra elíptica, que é desenhada no espaço LOCAL do boneco e gira junto
  /// com ele; deitado, ela virava uma mancha vertical atravessando o corpo.
  bool alive = true;

  @override
  void update(double dt) {
    super.update(dt);
    if (!alive || theme.reduceMotion) return;

    _clock += dt;
    final breath = math.sin(_clock * math.pi * 2 / breathPeriod) * breathDepth;

    // Só o Y respira. Escalar os dois eixos faz o boneco "pular" no lugar;
    // esticar só a altura é o agachamento que o olho lê como fôlego.
    scale.setValues(_baseScale, _baseScale * (1 + breath));
  }

  /// Sombra elíptica no chão. Sem ela, o boneco flutua.
  @override
  void render(Canvas canvas) {
    if (!alive) {
      super.render(canvas);
      return;
    }

    // A sombra segue a OPACIDADE do boneco. Ela é desenhada com tinta
    // própria, então um `OpacityEffect` sobre o boneco não a alcançaria: ele
    // sumiria e ficaria uma mancha escura sozinha no chão.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x / 2, size.y - size.y * 0.06),
        width: size.x * 0.62,
        height: size.y * 0.12,
      ),
      Paint()..color = theme.shadow.withValues(alpha: theme.shadow.a * opacity),
    );
    super.render(canvas);
  }

  void setSlouching(bool value) {
    if (_slouching == value) return;
    _slouching = value;
    // Machucado NÃO é só cor: o boneco encolhe e inclina. Um tint vermelho
    // sozinho some contra um sprite que já tem vermelho.
    angle = value ? 0.12 : 0;
    _baseScale = value ? 0.92 : 1;
    scale.setValues(_baseScale, _baseScale);
  }
}

/// O herói de um membro do workspace.
class HeroActor extends _BreathingActor with TapCallbacks {
  HeroActor({
    required super.sprite,
    required super.position,
    required super.size,
    required super.theme,
    required this.skin,
    this.onTap,
  }) : super(breathPeriod: 2.6, breathDepth: 0.035, priority: 300);

  /// Que boneco este ator é. É a identidade dele para a sincronia de estado:
  /// o nome mora no placar, não na cena.
  final HeroSkin skin;

  /// Tocar no herói abre o detalhe das contas — o mesmo destino da barra.
  final VoidCallback? onTap;

  @override
  void onTapDown(TapDownEvent event) => onTap?.call();

  HeroMood _mood = HeroMood.healthy;

  set mood(HeroMood value) {
    if (_mood == value) return;
    _mood = value;

    // Pressionado também curva o boneco: o rombo não aparece na barra (ela
    // pode estar cheia), então ele tem de aparecer na POSE.
    setSlouching(value != HeroMood.healthy);

    // Exausto = filtro escuro leve, e só. Vermelho aqui competiria com o
    // vermelho do DANO, que é um evento e precisa se destacar de um estado.
    paint.colorFilter = value == HeroMood.exhausted
        ? ColorFilter.mode(theme.exhaustion, BlendMode.srcATop)
        : null;
  }

  /// O avanço e o retorno do golpe.
  ///
  /// `easeOutBack` na volta é o que dá o "peso": o herói passa do ponto e
  /// assenta. Com uma curva simétrica o movimento fica de metrônomo.
  void strike({required double towards}) {
    if (theme.reduceMotion) return;

    final direction = towards > position.x ? 1.0 : -1.0;

    add(
      MoveByEffect(
        Vector2(size.x * 0.75 * direction, 0),
        EffectController(
          duration: 0.12,
          curve: Curves.easeOutQuad,
          reverseDuration: 0.34,
          reverseCurve: Curves.easeOutBack,
        ),
      ),
    );
  }

  /// O herói apanhou: tremor curto e clarão vermelho.
  void flinch() {
    if (theme.reduceMotion) return;

    add(
      MoveByEffect(
        Vector2(-size.x * 0.12, 0),
        EffectController(duration: 0.05, reverseDuration: 0.05, repeatCount: 3),
      ),
    );
    add(
      ColorEffect(
        theme.damage,
        EffectController(duration: 0.12, reverseDuration: 0.2),
        opacityTo: 0.75,
      ),
    );
  }

  /// A pose de vitória: o herói dá um pulo e assenta.
  ///
  /// Um pulo, e não uma animação de sprite: a folha do Kenney tem um quadro
  /// por personagem. O que dá a leitura de comemoração é o TEMPO — subir
  /// rápido, cair devagar —, e isso não precisa de arte nova.
  void cheer() {
    if (theme.reduceMotion) return;

    add(
      MoveByEffect(
        Vector2(0, -size.y * 0.35),
        EffectController(
          duration: 0.18,
          curve: Curves.easeOutQuad,
          reverseDuration: 0.30,
          reverseCurve: Curves.bounceOut,
          repeatCount: 2,
        ),
      ),
    );
  }

  /// O herói foi curado: pulso verde.
  void glow() {
    if (theme.reduceMotion) return;

    add(
      ColorEffect(
        theme.heal,
        EffectController(duration: 0.2, reverseDuration: 0.35),
        opacityTo: 0.6,
      ),
    );
  }
}

/// O monstro da semana.
class MonsterActor extends _BreathingActor with TapCallbacks {
  MonsterActor({
    required super.sprite,
    required super.position,
    required super.size,
    required super.theme,
    this.onTap,
  }) : super(breathPeriod: 1.9, breathDepth: 0.06, priority: 400);

  final VoidCallback? onTap;

  /// A cicatriz do atraso: "+R$ 640,00 atrasado", pendurada no bicho.
  TextComponent? _scar;

  bool _fled = false;

  @override
  void onTapDown(TapDownEvent event) => onTap?.call();

  /// Leva o golpe: tremor, clarão e — quem chama — moedas.
  void takeHit() {
    if (theme.reduceMotion) return;

    add(
      MoveByEffect(
        Vector2(size.x * 0.14, 0),
        EffectController(duration: 0.04, reverseDuration: 0.04, repeatCount: 4),
      ),
    );
    add(
      ColorEffect(
        theme.ink,
        EffectController(duration: 0.06, reverseDuration: 0.24),
        opacityTo: 0.9,
      )..onComplete = _restoreTint,
    );
  }

  /// A derrota: o bicho **cai e fica lá**, morto.
  ///
  /// Decisão 2 do dono, literal: *"quando a vida do monstro chegar a zero,
  /// precisamos que ele apareça como morto"*. Até aqui ele encolhia e
  /// desaparecia — e um monstro que some deixa a arena vazia justamente no
  /// momento em que ela deveria mostrar o troféu. Pior: quem abrisse o app
  /// numa semana já vencida via uma cena sem adversário nenhum e nenhum sinal
  /// de que houve luta.
  ///
  /// O corpo é o MESMO sprite — a folha do Kenney tem um quadro por criatura,
  /// e não existe pose de morto para recortar. O que diz "morto" são três
  /// coisas que não precisam de arte nova:
  ///
  /// 1. **caído**: um quarto de volta, deitado sobre a lateral. Quem desloca
  ///    o corpo para ele descansar no chão é o `_layout` do jogo, porque a
  ///    rotação acontece em torno do pé e joga metade do bicho para debaixo
  ///    da areia;
  /// 2. **cinza**: a luminância do próprio sprite, sem cor nenhuma. Não é um
  ///    tint por cima — um filtro colorido sobre um demônio vermelho continua
  ///    vermelho —, é a saturação zerada;
  /// 3. **o X**, que quem desenha é a cena ([DeathMark]): ele vive no mundo e
  ///    não no boneco, senão giraria junto com o corpo.
  ///
  /// Ele volta na semana que vem com os compromissos dela. Quando a morte
  /// acontece NA TELA, quem chama acrescenta o susto e as moedas; aqui fica
  /// só a queda, porque este mesmo método roda quando a cena ABRE com a
  /// semana já vencida — e aí não houve golpe nenhum para comemorar.
  void fall() {
    if (_fled) return;
    _fled = true;

    alive = false;
    paint.colorFilter = corpseFilter;
    opacity = 0.9;
    angle = fallenAngle;
    // A escala volta ao normal: o bicho pode ter morrido no meio de um
    // tremor, e um cadáver esticado em 1,14 de altura é um bug visível.
    scale.setValues(1, 1);
  }

  /// O quarto de volta da queda. Positivo: ele tomba para o lado OPOSTO aos
  /// heróis, que é para onde o golpe o empurrou.
  static const double fallenAngle = math.pi / 2;

  /// Cinza por LUMINÂNCIA — os coeficientes de brilho do sRGB.
  ///
  /// Público porque o teste da morte AO VIVO o compara com o que sobrou no
  /// `paint` depois de a animação assentar: o defeito que ele guarda não tem
  /// como ser visto numa captura de estado parado.
  ///
  /// Não é uma cor: é a matriz que joga os três canais para o mesmo valor. É
  /// por isso que ela não mora em `AppColors`, e é por isso que ela funciona
  /// nas cinco skins — inclusive no demônio vermelho, que qualquer filtro de
  /// tinta deixaria vermelho.
  static const ColorFilter corpseFilter = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  /// O golpe final: um susto branco antes de tombar.
  ///
  /// O `onComplete` não é zelo: o `ColorEffect` do Flame **escreve** em
  /// `paint.colorFilter` a cada quadro e, no fim, deixa lá o filtro da cor de
  /// origem com opacidade zero — `ColorFilter.mode(transparent, srcATop)`. Ele
  /// não restaura o que havia antes.
  ///
  /// Quando o monstro morre AO VIVO, os dois acontecem na mesma virada de
  /// estado: [fall] pinta o cadáver de cinza e o susto entra por cima. Ao
  /// terminar, o susto deixava um filtro transparente no lugar do cinza — e o
  /// bicho ficava deitado, com o X, **em cor cheia** até a semana seguinte.
  /// Quem abria a Home numa semana já vencida via o cadáver certo; quem
  /// assistia à morte via o errado, que é o pior dos dois casos, porque é o
  /// momento em que a pessoa está olhando.
  ///
  /// A ordem entre `fall()` e este método deixou de importar: seja qual for,
  /// o fim do efeito repõe o estado atual do ator.
  void deathThroes() {
    if (theme.reduceMotion) return;

    add(
      ColorEffect(
        theme.ink,
        EffectController(duration: 0.08, reverseDuration: 0.12, repeatCount: 2),
        opacityTo: 1,
      )..onComplete = _restoreTint,
    );
  }

  /// A tinta que o ator deve ter quando nenhum efeito está por cima.
  void _restoreTint() {
    paint.colorFilter = _fled ? corpseFilter : null;
  }

  /// `true` enquanto o bicho está no chão. O `_layout` da cena pergunta isto
  /// para saber onde apoiar o corpo deitado.
  bool get isFallen => _fled;

  /// Desfaz a derrota — o estado voltou a ter compromisso pendente (uma
  /// parcela desfeita, um lançamento novo). Sem isto o monstro ficaria caído
  /// para sempre depois do primeiro fechamento da semana.
  void revive() {
    if (!_fled) return;
    _fled = false;
    alive = true;
    paint.colorFilter = null;
    angle = 0;
    scale.setValues(1, 1);
    opacity = 1;
  }

  set scarText(String? text) {
    if (text == null) {
      _scar?.removeFromParent();
      _scar = null;
      return;
    }

    if (_scar != null) {
      _scar!.text = text;
      return;
    }

    _scar = TextComponent(
      text: text,
      anchor: Anchor.bottomCenter,
      position: Vector2(size.x / 2, -1),
      textRenderer: TextPaint(
        // 4, e não 5: o texto completo ("Enfurecido: +R$ 640,00 atrasado")
        // atravessava a cena inteira. Na cicatriz vai só o VALOR; a frase
        // inteira está no selo da barra, onde há largura para ela.
        style: theme.labelStyle.copyWith(fontSize: 4, color: theme.damage),
      ),
    );
    add(_scar!);
  }
}

/// O X sobre o monstro morto.
///
/// Dois riscos e nada mais — é o símbolo que qualquer jogo usa para "isto
/// acabou", e ele lê a 30px onde a expressão de um sprite de 16px não lê.
///
/// Ele mora no MUNDO, e não pendurado no monstro: um filho herda a rotação do
/// pai, e sobre um corpo tombado um quarto de volta o X sairia deitado —
/// deixando de ser um X e virando um `+`.
class DeathMark extends PositionComponent {
  DeathMark({required this.color, required Vector2 size})
    : super(size: size, anchor: Anchor.center, priority: 500);

  final Color color;

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.x * 0.18
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = false;

    canvas.drawLine(Offset.zero, Offset(size.x, size.y), paint);
    canvas.drawLine(Offset(size.x, 0), Offset(0, size.y), paint);
  }
}
