import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/arena/presentation/game/arena_sprites.dart';

/// A folha da Arena, carregada UMA vez para quem não é a cena.
///
/// A cena do Flame carrega a folha dentro do `onLoad` dela e não precisa
/// disto. Quem precisa é o seletor de avatar: ele mostra os mesmos bonecos da
/// Arena em telas comuns (perfil e onboarding), e sem um provider cada tile
/// decodificaria o PNG por conta própria a cada rebuild.
///
/// Não é `autoDispose` de propósito: o usuário vai e volta entre o perfil e o
/// resto do app, e a folha inteira são 5 KB.
final arenaSpritesProvider = FutureProvider<ArenaSprites>((ref) {
  return ArenaSprites.load();
});
