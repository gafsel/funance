import 'dart:ui' as ui;

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:funances/features/arena/domain/models/arena_state.dart';

/// A folha de sprites da Arena e o endereço de cada figura nela.
///
/// A folha é a `tilemap_packed.png` do Kenney *Tiny Dungeon* (CC0): 12 × 11
/// tiles de 16 × 16 px, **sem espaçamento**. O índice de um tile é
/// `linha * 12 + coluna`, e é por isso que os números abaixo parecem soltos —
/// eles são coordenadas, não escolhas. A tabela legível está em
/// `assets/arena/LICENSE.md`.
///
/// Quando a arte definitiva chegar, é este arquivo que troca. O resto da cena
/// só conhece `spriteFor(HeroSkin)` e `spriteFor(MonsterSkin)`.
class ArenaSprites {
  ArenaSprites._(this._sheet);

  static const String sheetAsset = 'kenney_tiny_dungeon.png';
  static const String assetPrefix = 'assets/arena/';

  /// Lado do tile na folha, em pixels.
  static const double tile = 16;

  static const int _columns = 12;

  final ui.Image _sheet;

  /// Carrega a folha por um cache PRÓPRIO, com o prefixo da Arena.
  ///
  /// Não usa o `Flame.images` global de propósito: o global tem prefixo
  /// `assets/images/`, que este projeto não tem, e mexer nele deixaria um
  /// efeito colateral de escopo de app inteiro para uma tela só.
  static Future<ArenaSprites> load({Images? cache}) async {
    final images = cache ?? Images(prefix: assetPrefix);
    return ArenaSprites._(await images.load(sheetAsset));
  }

  /// Um tile pelo índice na folha.
  Sprite byIndex(int index) => Sprite(
    _sheet,
    srcPosition: Vector2((index % _columns) * tile, (index ~/ _columns) * tile),
    srcSize: Vector2.all(tile),
  );

  Sprite hero(HeroSkin skin) => byIndex(switch (skin) {
    HeroSkin.knight => 96,
    HeroSkin.mage => 84,
    HeroSkin.ranger => 112,
    HeroSkin.warrior => 100,
  });

  Sprite monster(MonsterSkin skin) => byIndex(switch (skin) {
    MonsterSkin.spider => 122,
    MonsterSkin.bat => 120,
    MonsterSkin.ghost => 121,
    MonsterSkin.slime => 108,
    MonsterSkin.demon => 110,
  });

  /// Chão da arena.
  ///
  /// Marrom escuro, e não a areia do tile 48, por um motivo de ARTE e não de
  /// gosto: todo personagem desta folha vem com um cartão escuro de fundo
  /// (`#3F2631`, medido) que é parte do sprite e não dá para recortar. Sobre
  /// a areia clara cada boneco vira um adesivo colado na cena; sobre o chão
  /// escuro o cartão quase some.
  Sprite get floor => byIndex(0);
  Sprite get floorSpeckled => byIndex(24);
  Sprite get wall => byIndex(40);
  Sprite get brazier => byIndex(29);

  /// A tinta de todo pixel art da cena.
  ///
  /// `FilterQuality.none` e sem antialias: um sprite de 16 px esticado 4× com
  /// interpolação vira um borrão cinza: o contorno preto do Kenney some e o
  /// boneco deixa de ter cara de boneco.
  static Paint get pixelPaint => Paint()
    ..filterQuality = FilterQuality.none
    ..isAntiAlias = false;
}
