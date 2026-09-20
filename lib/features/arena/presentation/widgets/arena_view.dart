import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/arena/domain/models/arena_state.dart';
import 'package:funances/features/arena/presentation/game/arena_game.dart';
import 'package:funances/features/arena/presentation/game/arena_theme.dart';
import 'package:funances/features/arena/presentation/providers/arena_providers.dart';
import 'package:funances/features/arena/presentation/widgets/arena_heroes_sheet.dart';
import 'package:funances/features/arena/presentation/widgets/arena_hud.dart';
import 'package:funances/features/arena/presentation/widgets/arena_monster_sheet.dart';
import 'package:funances/features/auth/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';

/// A Arena montada: placar em cima, cena embaixo.
///
/// Existe como widget, e não só como tela, porque ela é usada nos dois
/// lugares: o bloco no topo da Home e a rota `/arena` em tela cheia. As duas
/// mostram a MESMA coisa — a única diferença é quanta altura a cena recebe.
///
/// O que mora aqui é a ponte entre o Riverpod e o Flame, e as duas
/// interações: tocar nos heróis (folha das contas) e tocar no monstro (folha
/// dos compromissos). A conta está em `ArenaCalculator`; a arte, no
/// `ArenaGame`.
class ArenaView extends ConsumerStatefulWidget {
  const ArenaView({super.key, required this.sceneHeight, this.compact = false});

  /// Altura da cena. `null` = ocupa o que sobrar (a rota em tela cheia).
  final double? sceneHeight;

  /// Celular: tipografia e marcador menores.
  final bool compact;

  @override
  ConsumerState<ArenaView> createState() => _ArenaViewState();
}

class _ArenaViewState extends ConsumerState<ArenaView>
    with WidgetsBindingObserver {
  ArenaGame? _game;

  /// O tema com que o jogo foi criado. Se o usuário trocar claro/escuro ou
  /// ligar "reduzir movimento" com a Arena aberta, o jogo é refeito — os
  /// componentes do Flame recebem cor na construção e não observam tema.
  ArenaTheme? _builtWith;

  /// `true` enquanto uma folha está aberta. O loop fica parado; um jogo
  /// rodando atrás de uma folha modal é bateria gasta em pixel que ninguém vê.
  bool _suspended = false;

  /// O evento guardado já foi consumido nesta montagem?
  bool _drainedPending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App em segundo plano: o `GameWidget` continuaria recebendo tiques do
    // `Ticker` em algumas plataformas. Parar é explícito.
    _setRunning(state == AppLifecycleState.resumed && !_suspended);
  }

  void _setRunning(bool running) {
    final game = _game;
    if (game == null || !game.isMounted) return;

    if (running && game.paused) {
      game.resumeEngine();
    } else if (!running && !game.paused) {
      game.pauseEngine();
    }
  }

  ArenaGame _gameFor(ArenaTheme theme) {
    final existing = _game;
    if (existing != null && _builtWith == theme) return existing;

    final game = ArenaGame(
      theme: theme,
      onMonsterTap: _openMonsterSheet,
      onHeroTap: _openHeroesSheet,
    );

    _game = game;
    _builtWith = theme;
    return game;
  }

  ArenaState? get _state => ref.read(ArenaViewProviders.state).valueOrNull;

  String _money(double value) => value.asCurrency(locale: context.locale);

  Future<void> _openMonsterSheet() async {
    final state = _state;
    if (state == null) return;

    _suspended = true;
    _setRunning(false);

    final paid = await ArenaMonsterSheet.show(
      context,
      state,
      isBusiness: ref.read(ArenaViewProviders.isBusiness),
    );

    _suspended = false;
    _setRunning(true);

    if (paid == null || !mounted) return;

    // O golpe é de quem pagou. `currentUser` é o dado que existe hoje; o dia
    // em que a parcela guardar quem a quitou, é só trocar a origem.
    //
    // E ele custa: o dinheiro sai do caixa. Os DOIS números rolam — o do
    // monstro para baixo porque a dívida acabou, o dos heróis para baixo
    // porque o saldo pagou por ela. É a leitura que a POC 1 não tinha.
    _game?.playStrike(
      amountLabel: '−${_money(paid.referenceAmount)}',
      striker: ref.read(AuthDomainProviders.currentUser)?.id,
    );
  }

  Future<void> _openHeroesSheet() async {
    final state = _state;
    if (state == null) return;

    _suspended = true;
    _setRunning(false);

    await ArenaHeroesSheet.show(context, state);

    _suspended = false;
    _setRunning(true);
  }

  /// Reage a um estado NOVO.
  void _onStateChanged(ArenaState? previous, ArenaState next) {
    final game = _game;
    if (game == null) return;

    game.applyState(next, animate: previous != null);

    if (previous == null) return;

    final monsterFell = next.monsterHp < previous.monsterHp;
    final delta = next.currentBalance - previous.currentBalance;

    if (delta > 0) {
      game.playHeal('+${_money(delta)}');
      return;
    }

    if (delta < 0) {
      // Quando o saldo cai JUNTO com a dívida, o que houve foi um pagamento
      // planejado — o golpe já está sendo animado por `playStrike`, e o
      // tremor de dano por cima dele leria como "levei um golpe ao dar um
      // golpe". Só o número desce.
      game.playDamage('−${_money(-delta)}', flinch: !monsterFell);
    }
  }

  /// O evento que ficou guardado enquanto a Arena não estava na tela.
  ///
  /// O gasto acontece no formulário de lançamento; a cena que deveria reagir
  /// a ele está desmontada. `pendingEvent` guarda o fato, e é aqui que ele
  /// vira animação — no primeiro quadro em que a cena existe de novo.
  void _drainPending() {
    if (_drainedPending) return;
    _drainedPending = true;

    final event = ref.read(ArenaViewProviders.pendingEvent.notifier).take();
    if (event == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (event.healed > 0) _game?.playHeal('+${_money(event.healed)}');
      if (event.damage > 0) _game?.playDamage('−${_money(event.damage)}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(ArenaViewProviders.state);

    ref.listen(ArenaViewProviders.state, (previous, next) {
      final value = next.valueOrNull;
      if (value != null) _onStateChanged(previous?.valueOrNull, value);
    });

    // O `TickerMode` é `false` para a rota que não está no topo da pilha.
    // É o sinal mais barato de "esta tela não está visível".
    final visible = TickerMode.valuesOf(context).enabled;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _setRunning(visible && !_suspended),
    );

    return async.when(
      loading: () => SizedBox(
        height: widget.sceneHeight ?? 160,
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _ArenaMessage(message: context.l10n.arenaError),
      data: (state) {
        if (state.isEmpty) {
          return _ArenaMessage(message: context.l10n.arenaEmpty);
        }

        final game = _gameFor(ArenaTheme.of(context));

        // O `ref.listen` acima só dispara em MUDANÇA — o primeiro estado
        // nunca passaria por ele, e a cena abriria sem monstro nenhum.
        // `applyState` sai cedo quando o estado é igual, então repetir isto a
        // cada build não custa nada.
        game.applyState(state, animate: false);
        game.overdueLabel = (value) =>
            '+${value.overdueAmount.asCurrency(locale: context.locale)}';

        _drainPending();

        final scene = ClipRect(child: GameWidget(game: game));

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xs,
                AppSpacing.xs,
                AppSpacing.xs,
                AppSpacing.xxs,
              ),
              child: ArenaHud(
                state: state,
                monsterName: _monsterName(context, state.monsterSkin),
                compact: widget.compact,
                onTapHeroes: _openHeroesSheet,
                onTapMonster: _openMonsterSheet,
              ),
            ),
            // O `GameWidget` não recorta sozinho, e a última fileira de tiles
            // do chão passa da borda: sem o `ClipRect` o cenário vazava por
            // cima do que estivesse embaixo.
            if (widget.sceneHeight == null)
              Expanded(child: scene)
            else
              SizedBox(height: widget.sceneHeight, child: scene),
          ],
        );
      },
    );
  }
}

/// O nome do bicho da semana. Fica aqui, e não no enum, porque é texto
/// traduzido — e um enum de domínio não conhece `AppLocalizations`.
String _monsterName(BuildContext context, MonsterSkin skin) {
  final l10n = AppLocalizations.of(context)!;

  return switch (skin) {
    MonsterSkin.spider => l10n.arenaMonsterSpider,
    MonsterSkin.bat => l10n.arenaMonsterBat,
    MonsterSkin.ghost => l10n.arenaMonsterGhost,
    MonsterSkin.slime => l10n.arenaMonsterSlime,
    MonsterSkin.demon => l10n.arenaMonsterDemon,
  };
}

class _ArenaMessage extends StatelessWidget {
  const _ArenaMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.allMd,
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.inkInverse2),
          AppSpacing.gapSm,
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.inkInverse2),
            ),
          ),
        ],
      ),
    );
  }
}
