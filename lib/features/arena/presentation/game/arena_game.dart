import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show clampDouble;
import 'package:flutter/painting.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/features/arena/domain/models/arena_state.dart';
import 'package:funances/features/arena/presentation/game/arena_actors.dart';
import 'package:funances/features/arena/presentation/game/arena_effects.dart';
import 'package:funances/features/arena/presentation/game/arena_sprites.dart';
import 'package:funances/features/arena/presentation/game/arena_theme.dart';

/// Altura de mundo que a cena PREFERE mostrar.
///
/// Preferência, não regra: quem manda de verdade é a faixa de largura abaixo.
/// A conversão para pixels é do `camera.viewfinder.zoom` — sem
/// `FixedResolutionViewport`, sem tarja preta e com uma arte só do celular ao
/// macOS.
const double arenaPreferredHeight = 110;

/// A cena nunca é mais estreita que isto, em unidades de mundo.
///
/// É o que impede a armadilha do celular em pé: numa caixa alta e estreita, o
/// zoom pela altura deixaria o mundo com ~70 unidades de largura — dois
/// heróis de 19 e um monstro de 26 não cabem lado a lado, e a "luta" vira uma
/// pilha de sprites encostados. Quando a caixa é alta demais para esta
/// largura, o que sobra vira ALTURA DE PAREDE, que é cenário de graça.
const double arenaMinWorldWidth = 130;

/// E nunca mais larga que isto: num monitor, um mundo largo demais deixaria
/// os bonecos do tamanho de formigas em lados opostos da tela.
const double arenaMaxWorldWidth = 280;

/// Abaixo desta largura de mundo a cena é "compacta": bonecos mais juntos,
/// monstro um pouco menor.
const double arenaCompactWidth = 165;

/// Altura MÍNIMA da faixa de chão, em unidades de mundo. O resto, para cima,
/// é parede.
///
/// Numa caixa alta o chão cresce junto (ver `_floorBand`): com uma faixa fixa,
/// um celular em pé virava uma parede de tijolo de três quartos de tela com
/// uma tirinha de areia embaixo.
const double arenaMinFloorBand = 58;

/// O cenário: parede de tijolo em cima, chão de areia embaixo.
///
/// Desenhado num `render` em laço, e não com um mapa de tiles: são ~90
/// `drawImageRect` por quadro, o que um tilemap faria de qualquer jeito, e
/// cabe em trinta linhas em vez de uma dependência a mais.
class _ArenaBackdrop extends Component {
  _ArenaBackdrop(this.sprites, this.theme);

  final ArenaSprites sprites;
  final ArenaTheme theme;

  /// Lado do tile desenhado. Não é 16: a folha é de 16 px, e aqui ela é
  /// esticada para a escala da cena.
  static const double drawn = 13;

  double _worldWidth = arenaMinWorldWidth;
  double _worldHeight = arenaPreferredHeight;
  double _horizon = arenaPreferredHeight - arenaMinFloorBand;

  void resize(double width, double height, double horizon) {
    _worldWidth = width;
    _worldHeight = height;
    _horizon = horizon;
  }

  @override
  void render(Canvas canvas) {
    final columns = (_worldWidth / drawn).ceil() + 1;
    final line = _horizon;

    // A parede é desenhada de BAIXO PARA CIMA, a partir do horizonte: assim a
    // fiada que encosta no chão é sempre inteira, e o corte — que existe em
    // qualquer altura de caixa — fica lá em cima, fora do olhar.
    for (var row = 0; row * drawn < line + drawn; row++) {
      for (var column = 0; column < columns; column++) {
        sprites.wall.render(
          canvas,
          position: Vector2(column * drawn, line - (row + 1) * drawn),
          size: Vector2.all(drawn),
          overridePaint: ArenaSprites.pixelPaint,
        );
      }
    }

    for (var row = 0; line + row * drawn < _worldHeight; row++) {
      for (var column = 0; column < columns; column++) {
        // A variação salpicada entra em um de cada ONZE tiles, por posição e
        // não por sorteio: um `Random` por quadro faria o chão cintilar, e um
        // de cada cinco cobria o chão de cascalho branco.
        final speckled = (row * 7 + column * 3) % 11 == 0;

        (speckled ? sprites.floorSpeckled : sprites.floor).render(
          canvas,
          position: Vector2(column * drawn, line + row * drawn),
          size: Vector2.all(drawn),
          overridePaint: ArenaSprites.pixelPaint,
        );
      }
    }

    _renderWallShade(canvas, line);
  }

  /// Escurece a parede de cima para baixo.
  ///
  /// Duas coisas de uma vez: mata a monotonia de um campo de tijolo que num
  /// celular em pé toma metade da tela, e amarra o cinza do Kenney ao azul
  /// profundo da identidade — a luz parece vir dos braseiros, que é onde a
  /// cena quer que se olhe.
  void _renderWallShade(Canvas canvas, double line) {
    if (line <= 0) return;

    final rect = Rect.fromLTWH(0, 0, _worldWidth, line);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[theme.wallShadeTop, theme.wallShadeBottom],
        ).createShader(rect),
    );
  }
}

/// A cena da Arena.
///
/// **Não calcula nada.** Recebe um [ArenaState] pronto e um punhado de
/// eventos ("golpe de R$ 1.200 pelo herói 0"), e a única coisa que decide é
/// onde e como isso aparece. A conta mora em `ArenaCalculator`, e é
/// justamente essa separação que permite testar o número sem montar o jogo.
class ArenaGame extends FlameGame {
  ArenaGame({
    required this.theme,
    this.onMonsterTap,
    this.onMonsterLongPress,
    this.onCocoonTap,
  });

  final ArenaTheme theme;
  final VoidCallback? onMonsterTap;
  final VoidCallback? onMonsterLongPress;
  final VoidCallback? onCocoonTap;

  late final ArenaSprites sprites;

  /// A folha já carregou? Não dá para usar `isLoaded`: ele só vira `true`
  /// DEPOIS que o `onLoad` retorna, e é dentro do `onLoad` que a cena precisa
  /// montar o estado que já tinha chegado.
  bool _ready = false;

  final List<HeroActor> _heroes = <HeroActor>[];
  MonsterActor? _monster;
  CocoonActor? _cocoon;

  /// O cenário nasce no `onLoad` (depende da folha) e o `onGameResize` pode
  /// chegar antes disso — daí o nulo.
  _ArenaBackdrop? _backdrop;

  ArenaState? _state;

  /// Qual herói golpeia na próxima vez que não se souber quem pagou.
  int _nextStriker = 0;

  bool get isSceneReady => _monster != null;

  /// O zoom: a altura preferida, PRESA na faixa de largura de mundo.
  ///
  /// `clampDouble` com os dois limites vindos da largura da caixa — é a regra
  /// inteira da responsividade da cena, em uma linha.
  double get _zoom {
    if (size.x <= 0 || size.y <= 0) return 1;

    return clampDouble(
      size.y / arenaPreferredHeight,
      size.x / arenaMaxWorldWidth,
      size.x / arenaMinWorldWidth,
    );
  }

  double get _worldWidth => size.x <= 0 ? arenaMinWorldWidth : size.x / _zoom;

  double get _worldHeight =>
      size.y <= 0 ? arenaPreferredHeight : size.y / _zoom;

  /// Faixa de chão: cresce com a altura da caixa, nunca menor que o mínimo.
  double get _floorBand => math.max(arenaMinFloorBand, _worldHeight * 0.46);

  /// Onde a parede termina e o chão começa.
  double get _horizon => _worldHeight - _floorBand;

  /// A linha do chão: onde os pés dos bonecos pousam.
  double get _groundY => _worldHeight - _floorBand * 0.22;

  bool get _isCompact => _worldWidth < arenaCompactWidth;

  @override
  Color backgroundColor() => AppColors.surfaceDeep;

  @override
  Future<void> onLoad() async {
    sprites = await ArenaSprites.load();

    camera.viewfinder.anchor = Anchor.topLeft;
    _applyZoom();

    final backdrop = _ArenaBackdrop(sprites, theme)
      ..resize(_worldWidth, _worldHeight, _horizon)
      ..priority = 0;
    _backdrop = backdrop;
    world.add(backdrop);

    _addBraziers();
    _ready = true;

    final pending = _state;
    if (pending != null) {
      _state = null;
      applyState(pending, animate: false);
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (!isMounted) return;

    _applyZoom();
    _layout();
  }

  void _applyZoom() {
    if (size.y <= 0) return;
    camera.viewfinder.zoom = _zoom;
    camera.viewfinder.position = Vector2.zero();
  }

  final List<SpriteComponent> _braziers = <SpriteComponent>[];

  void _addBraziers() {
    for (var i = 0; i < 2; i++) {
      final brazier = SpriteComponent(
        sprite: sprites.brazier,
        position: Vector2.zero(),
        size: Vector2.all(14),
        anchor: Anchor.bottomCenter,
        priority: 10,
        paint: ArenaSprites.pixelPaint,
      );
      _braziers.add(brazier);
      world.add(brazier);
    }
  }

  // ── Estado ───────────────────────────────────────────────────────────────

  /// Põe a cena no estado [next].
  ///
  /// Sem animação nenhuma: quem anima é [playStrike]/[playHeal]/[playDamage],
  /// chamados pela tela quando ela SABE que houve um evento. Um estado novo
  /// chegando do Firestore (outro membro pagou, o servidor reagregou) muda os
  /// números sem fingir que o usuário fez algo.
  void applyState(ArenaState next, {bool animate = true}) {
    final previous = _state;

    // Igualdade de valor (freezed): a tela chama isto a cada `build` para
    // garantir que a cena começa no estado certo, e sem esta saída cedo cada
    // rebuild refaria o layout inteiro.
    if (previous == next && _ready) return;

    _state = next;

    if (!_ready) return;

    _syncHeroes(next);
    _syncMonster(next);
    _syncCocoon(next);
    _layout();

    if (!animate || previous == null) return;

    // Um estado que chega com o monstro mais fraco sem golpe da tela é golpe
    // de outra pessoa da equipe. A cena reage igual — é o mesmo fato.
    if (next.monsterHp < previous.monsterHp) {
      _monster?.takeHit();
    }
  }

  void _syncHeroes(ArenaState next) {
    final wanted = next.heroes;

    while (_heroes.length > wanted.length) {
      _heroes.removeLast().removeFromParent();
    }

    for (var index = 0; index < wanted.length; index++) {
      final hero = wanted[index];

      if (index < _heroes.length && _heroes[index].label == hero.name) {
        _heroes[index].mood = next.heroMood;
        continue;
      }

      if (index < _heroes.length) {
        _heroes.removeAt(index).removeFromParent();
      }

      final actor = HeroActor(
        sprite: sprites.hero(hero.skin),
        position: Vector2.zero(),
        size: Vector2.all(_isCompact ? 19 : 22),
        theme: theme,
        label: hero.name,
      )..mood = next.heroMood;

      _heroes.insert(index, actor);
      world.add(actor);
    }
  }

  void _syncMonster(ArenaState next) {
    final existing = _monster;

    if (existing == null) {
      final actor = MonsterActor(
        sprite: sprites.monster(next.monsterSkin),
        position: Vector2.zero(),
        size: Vector2.all(_isCompact ? 26 : 30),
        theme: theme,
        onTap: onMonsterTap,
        onLongPress: onMonsterLongPress,
      );
      _monster = actor;
      world.add(actor);
    } else {
      existing.sprite = sprites.monster(next.monsterSkin);
    }

    _monster!.scarText = next.isEnraged ? _overdueLabel?.call(next) : null;

    if (next.hasFled) {
      _monster!.flee();
    } else {
      _monster!.revive();
    }
  }

  /// Como escrever a cicatriz. Vem da tela porque o texto é traduzido e
  /// formatado em moeda, e nem `AppLocalizations` nem `NumberFormat` deviam
  /// ser resolvidos dentro de um componente de jogo.
  String Function(ArenaState state)? _overdueLabel;

  set overdueLabel(String Function(ArenaState state)? builder) {
    _overdueLabel = builder;
    final state = _state;
    if (state != null && _monster != null) {
      _monster!.scarText = state.isEnraged ? builder?.call(state) : null;
    }
  }

  void _syncCocoon(ArenaState next) {
    final hasInvoice = (next.invoiceAmount ?? 0) > 0;

    if (!hasInvoice) {
      _cocoon?.removeFromParent();
      _cocoon = null;
      return;
    }

    // O TAMANHO do casulo é a fatura, comparada com a vida cheia do monstro:
    // um cartão que já vale mais que a semana inteira aparece maior que o
    // bicho, e essa é exatamente a leitura que se quer provocar.
    final reference = math.max(next.monsterMaxHp, 1.0);
    final ratio = (next.invoiceAmount! / reference).clamp(0.6, 1.5);
    final side = (_isCompact ? 15.0 : 17.0) * ratio;

    final existing = _cocoon;
    if (existing == null) {
      final actor = CocoonActor(
        sprite: sprites.cocoon,
        position: Vector2.zero(),
        size: Vector2.all(side),
        theme: theme,
        onTap: onCocoonTap,
      );
      _cocoon = actor;
      world.add(actor);
    } else {
      existing.size = Vector2.all(side);
    }
  }

  /// Onde cada um fica. Chamado no resize e a cada estado novo.
  void _layout() {
    final width = _worldWidth;
    final height = _worldHeight;
    final horizon = _horizon;
    _backdrop?.resize(width, height, horizon);

    final groundY = _groundY;

    for (var i = 0; i < _braziers.length; i++) {
      _braziers[i].position = Vector2(i == 0 ? 11 : width - 11, horizon - 2);
    }

    // A distância entre os dois heróis sai da LARGURA DO SPRITE, não de uma
    // fração da tela. Com fração, num celular (mundo de ~80 unidades) os dois
    // bonecos de 19 unidades caíam um em cima do outro — e os nomes também.
    final lead = width * (_isCompact ? 0.30 : 0.26);

    for (var index = 0; index < _heroes.length; index++) {
      final hero = _heroes[index];
      hero.position = Vector2(
        lead - index * hero.size.x * 1.15,
        // Um degrau atrás: dá profundidade e separa os dois nomes.
        groundY - (index == 1 ? 6 : 0),
      );
    }

    _monster?.position = Vector2(width * (_isCompact ? 0.68 : 0.70), groundY);
    _cocoon?.position = Vector2(width * 0.88, groundY - 3);
  }

  // ── Eventos ──────────────────────────────────────────────────────────────

  /// O golpe: alguém confirmou um pagamento planejado.
  ///
  /// [striker] é quem pagou. `null` quando o dado não existe — e aí os heróis
  /// se revezam, porque um mesmo boneco golpeando sempre faria a equipe
  /// parecer um enfeite.
  void playStrike({required String amountLabel, String? striker}) {
    final monster = _monster;
    if (monster == null) return;

    final index = _indexOfHero(striker) ?? _nextStriker;
    _nextStriker = _heroes.isEmpty ? 0 : (index + 1) % _heroes.length;

    if (index < _heroes.length) {
      _heroes[index].strike(towards: monster.position.x);
    }

    // O clarão e o número esperam o avanço; sem o atraso o golpe acerta antes
    // de o herói sair do lugar.
    final delay = theme.reduceMotion ? 0.0 : 0.12;

    add(
      TimerComponent(
        period: delay <= 0 ? 0.001 : delay,
        removeOnFinish: true,
        onTick: () {
          monster.takeHit();
          world.add(
            FloatingNumber(
              text: amountLabel,
              color: theme.gold,
              baseStyle: theme.numberStyle,
              at: monster.position - Vector2(0, monster.size.y * 0.9),
              reduceMotion: theme.reduceMotion,
            ),
          );
          if (!theme.reduceMotion) {
            world.add(
              CoinBurst(
                at: monster.position - Vector2(0, monster.size.y * 0.4),
                theme: theme,
              ),
            );
          }
        },
      ),
    );
  }

  /// Receita recebida: número verde sobre o herói e pulso de cura.
  void playHeal(String amountLabel) {
    final target = _heroes.firstOrNull;
    if (target == null) return;

    target.glow();
    world.add(
      FloatingNumber(
        text: amountLabel,
        color: theme.heal,
        baseStyle: theme.numberStyle,
        at: target.position - Vector2(0, target.size.y * 1.1),
        reduceMotion: theme.reduceMotion,
      ),
    );
  }

  /// Gasto fora do plano: tremor e número vermelho.
  void playDamage(String amountLabel) {
    final target = _heroes.firstOrNull;
    if (target == null) return;

    for (final hero in _heroes) {
      hero.flinch();
    }

    world.add(
      FloatingNumber(
        text: amountLabel,
        color: theme.damage,
        baseStyle: theme.numberStyle,
        at: target.position - Vector2(0, target.size.y * 1.1),
        reduceMotion: theme.reduceMotion,
      ),
    );
  }

  int? _indexOfHero(String? userId) {
    if (userId == null) return null;
    final heroes = _state?.heroes ?? const <ArenaHero>[];
    final index = heroes.indexWhere((hero) => hero.userId == userId);
    return index < 0 ? null : index;
  }
}
