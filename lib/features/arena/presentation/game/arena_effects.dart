import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flame/text.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';
import 'package:funances/features/arena/presentation/game/arena_theme.dart';

/// Um número que sobe e some: `+R$ 1.200` verde, `−R$ 89,90` vermelho.
///
/// É a peça que faz a cena ser sobre DINHEIRO e não sobre barrinhas. Sem ela,
/// o jogador vê a barra andar e não sabe o quanto andou.
class FloatingNumber extends TextComponent {
  FloatingNumber({
    required String text,
    required Color color,
    required TextStyle baseStyle,
    required Vector2 at,
    required this.reduceMotion,
  }) : super(
         text: text,
         anchor: Anchor.center,
         position: at,
         priority: 900,
         textRenderer: TextPaint(
           // O tamanho é reescrito porque o estilo veio do `textTheme`, em
           // pontos de tela, e aqui a unidade é a da cena (100 de altura).
           style: baseStyle.copyWith(fontSize: 9, color: color),
         ),
       );

  final bool reduceMotion;

  @override
  void onMount() {
    super.onMount();

    if (reduceMotion) {
      // Sem movimento: o número aparece, fica um instante e sai. Continua
      // dizendo QUANTO — é a informação, não o enfeite.
      add(RemoveEffect(delay: 1.2));
      return;
    }

    add(
      MoveByEffect(
        Vector2(0, -14),
        EffectController(duration: 1.0, curve: Curves.easeOutCubic),
      ),
    );
    add(
      OpacityEffect.fadeOut(
        EffectController(duration: 0.45, startDelay: 0.55),
        onComplete: removeFromParent,
      ),
    );
  }
}

/// Moedas espirrando de um ponto. É o XP tomando forma.
class CoinBurst extends ParticleSystemComponent {
  CoinBurst({
    required Vector2 at,
    required ArenaTheme theme,
    int count = 12,
    double spread = 26,
    math.Random? random,
  }) : super(
         position: at,
         priority: 800,
         particle: Particle.generate(
           count: count,
           lifespan: 0.9,
           generator: (index) {
             final rng = random ?? math.Random(index * 7919);
             final angle = -math.pi / 2 + (rng.nextDouble() - 0.5) * 2.2;
             final speed = spread * (0.6 + rng.nextDouble());

             return AcceleratedParticle(
               speed: Vector2(math.cos(angle), math.sin(angle)) * speed,
               // Gravidade: as moedas sobem e CAEM. Sem isso viram confete,
               // e confete é celebração de fim; moeda é recompensa de golpe.
               acceleration: Vector2(0, 90),
               child: CircleParticle(
                 radius: 1.6,
                 paint: Paint()..color = theme.gold,
               ),
             );
           },
         ),
       );
}

