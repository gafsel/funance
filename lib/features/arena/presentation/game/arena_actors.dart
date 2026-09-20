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

  @override
  void update(double dt) {
    super.update(dt);
    if (theme.reduceMotion) return;

    _clock += dt;
    final breath = math.sin(_clock * math.pi * 2 / breathPeriod) * breathDepth;

    // Só o Y respira. Escalar os dois eixos faz o boneco "pular" no lugar;
    // esticar só a altura é o agachamento que o olho lê como fôlego.
    scale.setValues(_baseScale, _baseScale * (1 + breath));
  }

  /// Sombra elíptica no chão. Sem ela, o boneco flutua.
  @override
  void render(Canvas canvas) {
    // A sombra segue a OPACIDADE do boneco. Ela é desenhada com tinta
    // própria, então o `OpacityEffect` da fuga do monstro não a alcançava: o
    // bicho sumia e ficava uma mancha escura sozinha no chão.
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
      ),
    );
  }

  /// A derrota: o bicho encolhe e some. Ele volta na semana que vem com os
  /// compromissos dela — o que acabou foi ESTA semana.
  ///
  /// Quando a morte acontece NA TELA (o último compromisso foi quitado
  /// agora), quem chama acrescenta o susto e as moedas; aqui fica só o
  /// encolher, porque este mesmo método roda quando a cena ABRE com a semana
  /// já vencida, e nesse caso não houve golpe nenhum para comemorar.
  void flee() {
    if (_fled) return;
    _fled = true;

    if (theme.reduceMotion) {
      opacity = 0.25;
      return;
    }

    add(
      ScaleEffect.to(
        Vector2.all(0.15),
        EffectController(duration: 0.55, curve: Curves.easeInBack),
      ),
    );
    add(OpacityEffect.fadeOut(EffectController(duration: 0.55)));
  }

  /// O golpe final: um susto branco antes de encolher.
  void deathThroes() {
    if (theme.reduceMotion) return;

    add(
      ColorEffect(
        theme.ink,
        EffectController(duration: 0.08, reverseDuration: 0.12, repeatCount: 2),
        opacityTo: 1,
      ),
    );
  }

  /// Desfaz a derrota — o estado voltou a ter compromisso pendente (uma
  /// parcela desfeita, um lançamento novo). Sem isto o monstro ficaria
  /// invisível para sempre depois do primeiro fechamento da semana.
  void revive() {
    if (!_fled) return;
    _fled = false;
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
