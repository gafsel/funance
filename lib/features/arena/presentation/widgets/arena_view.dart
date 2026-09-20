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
import 'package:funances/features/arena/presentation/widgets/arena_hud_footer.dart';
import 'package:funances/features/arena/presentation/widgets/arena_hud.dart';
import 'package:funances/features/arena/presentation/widgets/arena_monster_sheet.dart';
import 'package:funances/features/arena/presentation/widgets/arena_scene_icons.dart';
import 'package:funances/features/arena/presentation/widgets/arena_week_closing_banner.dart';
import 'package:funances/features/auth/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';

/// Altura da faixa do HUD MENSAL no pé da cena, em pixels lógicos.
///
/// Ela nasceu reservada e vazia, um pacote antes de ter conteúdo, justamente
/// para que a chegada dos quatro ícones não reorganizasse a cena, a altura da
/// Home e os goldens de uma vez. A altura é a MESMA em carregamento, em erro
/// e com os quatro ícones desenhados — ver [ArenaHudFooter].
double arenaFooterSlotHeight({required bool compact}) => compact ? 56 : 64;

/// O endereço da Arena.
///
/// A rota continua existindo — links antigos, notificações e o que já foi
/// compartilhado apontam para ela —, mas ela não abre mais uma tela própria:
/// desde a decisão 1 do dono ("a primeira aba deve ser só a arena"), a Arena
/// **é** a Home, e `/arena` redireciona para `/`. Ver `app_router.dart`.
const String arenaRoutePath = '/arena';

/// Largura máxima da Arena inteira, em pixels lógicos.
///
/// Num monitor a cena esticava de borda a borda e os atores iam parar em
/// pontas opostas de uma faixa de mil e duzentos pixels: deixava de ser uma
/// luta e virava um friso.
///
/// O limite passou a valer para o PLACAR também, e não só para a cena. Ele
/// era largo de propósito enquanto a Arena era um bloco no topo de uma Home
/// com outros blocos abaixo — leitura larga é boa. Agora a Arena ocupa a tela
/// inteira: com o placar de borda a borda num monitor, a vida dos heróis e a
/// do monstro ficam a mil pixels uma da outra e param de se enfrentar, que é
/// a única coisa que aquele desenho existe para fazer.
const double arenaMaxSceneWidth = 720;

/// A Arena montada: placar em cima, cena no meio, HUD mensal no pé.
///
/// Ela **é a primeira aba** — decisão 1 do dono: "ao invés de um container
/// expansível, a aba inteira será a arena, eliminando a necessidade de
/// expandir". Não há mais cartão, título "Desafio da semana" nem botão de
/// abrir em tela cheia: a cena toma a altura que sobra entre o placar e o
/// rodapé, e o que antes eram blocos abaixo dela virou a coluna de ícones da
/// lateral (ver [ArenaSceneIcons]).
///
/// O que mora aqui é a ponte entre o Riverpod e o Flame, e as duas
/// interações: tocar nos heróis (folha das contas) e tocar no monstro (folha
/// dos compromissos). A conta está em `ArenaCalculator`; a arte, no
/// `ArenaGame`.
class ArenaView extends ConsumerStatefulWidget {
  const ArenaView({super.key, this.compact = false});

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

  /// Um pagamento confirmado AQUI está a caminho.
  ///
  /// É o que decide se a queda de saldo é golpe ou dano. A rodada 1 decidia
  /// isso comparando dois instantâneos — "o monstro caiu junto?" —, e a
  /// coincidência mente: dois membros mexendo na mesma semana, ou um
  /// reagregar do servidor, produziam a mesma coincidência sem que ninguém
  /// tivesse golpeado. Quem sabe que houve um golpe é quem o deu.
  bool _strikeInFlight = false;

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

  /// O dinheiro que a CENA mostra — compacto, por decisão do dono (item 13).
  ///
  /// Os números flutuantes sobem por cima dos bonecos em unidades de mundo: um
  /// "−R$ 12.122,33" atravessa a arena inteira e cobre o monstro que ele
  /// acabou de golpear. "−R$ 12,1k" cabe sobre a cabeça dele.
  String _money(double value) =>
      value.asCompactCurrency(locale: context.locale);

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

    _strikeInFlight = true;

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

    // O golpe em voo é consumido por ESTE estado, seja ele qual for: se o
    // pagamento não chegar (offline), a bandeira não pode ficar de pé
    // esperando para engolir o tremor de um dano que não tem nada com ela.
    final striking = _strikeInFlight;
    _strikeInFlight = false;

    if (next.isDefeated && !previous.isDefeated) {
      game.playVictory(totalLabel: _money(next.monsterMaxHp));
    }

    final delta = next.currentBalance - previous.currentBalance;

    if (delta > 0) {
      game.playHeal('+${_money(delta)}');
      return;
    }

    if (delta < 0) {
      // Quando a queda é o pagamento que o usuário acabou de confirmar, o
      // tremor de dano por cima do golpe leria como "levei um golpe ao dar um
      // golpe". Só o número desce — que é o custo do golpe.
      game.playDamage('−${_money(-delta)}', flinch: !striking);
    }
  }

  /// O evento que ficou guardado enquanto a Arena não estava VISÍVEL.
  ///
  /// O gasto acontece no formulário de lançamento, que é uma rota empilhada
  /// POR CIMA da Home: a Arena continua montada o tempo todo. A rodada 1
  /// drenava uma vez por montagem, com uma bandeira que nunca voltava a
  /// falso — e por isso o segundo lançamento da sessão, e todos os
  /// seguintes, nunca animavam.
  ///
  /// Agora a condição é a certa: existe evento **e** a cena está na frente.
  /// Duas coisas chamam isto — o `ref.listen` (o evento chegou com a Arena
  /// visível) e o `build` disparado quando a rota volta a ser a de cima.
  void _drainPendingIfVisible() {
    if (!mounted || _suspended) return;
    if (ref.read(ArenaViewProviders.pendingEvent) == null) return;

    // `isCurrent` é a pergunta exata: "a Home é a rota de cima?". Enquanto o
    // formulário estiver empilhado, ela é falsa, e o golpe espera.
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return;
    if (!TickerMode.valuesOf(context).enabled) return;

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

    ref.listen(ArenaViewProviders.pendingEvent, (_, event) {
      if (event != null) _drainPendingIfVisible();
    });

    // O `TickerMode` é `false` para a rota que não está no topo da pilha.
    // É o sinal mais barato de "esta tela não está visível".
    final visible = TickerMode.valuesOf(context).enabled;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setRunning(visible && !_suspended);
      // A volta do formulário reacende o `TickerMode`, o que reconstrói este
      // widget: é aqui que o golpe guardado encontra a cena na frente de novo.
      _drainPendingIfVisible();
    });

    final state = async.valueOrNull;
    final playable = state != null && !state.isEmpty;

    // O MEIO da tela: a cena quando há luta, um recado quando não há.
    //
    // Os três estados moram no mesmo lugar de propósito. A primeira versão
    // desta tela devolvia o recado NO LUGAR da Arena inteira, e com ele iam
    // embora o rodapé mensal e — pior — a coluna de ícones: num cofre recém
    // criado, que é exatamente quem vê "a arena está vazia", as missões, a
    // Bússola e o coach sumiam do app. Quem não tem luta ainda é quem mais
    // precisa das portas.
    final Widget middle;
    if (playable) {
      final game = _gameFor(ArenaTheme.of(context));

      // O `ref.listen` acima só dispara em MUDANÇA — o primeiro estado
      // nunca passaria por ele, e a cena abriria sem monstro nenhum.
      // `applyState` sai cedo quando o estado é igual, então repetir isto a
      // cada build não custa nada.
      game.applyState(state, animate: false);
      game.overdueLabel = (value) =>
          '+${value.overdueAmount.asCompactCurrency(locale: context.locale)}';

      // A cena inteira é UM alvo para o leitor de tela: sem isto, o
      // `GameWidget` é um retângulo mudo, e quem navega por semântica não
      // tem como saber que existe uma luta ali — nem como abrir as duas
      // folhas, que só tinham porta pelas barras.
      //
      // O `ClipRect` não é enfeite: o `GameWidget` não recorta sozinho, e a
      // última fileira de tiles do chão passa da borda.
      middle = Semantics(
        container: true,
        label: context.l10n.arenaSceneSemantics(
          _monsterName(context, state.monsterSkin),
          state.monsterHp.asCurrency(locale: context.locale),
        ),
        child: ClipRect(child: GameWidget(game: game)),
      );
    } else if (async.hasError) {
      middle = _ArenaMessage(message: context.l10n.arenaError);
    } else if (state != null) {
      middle = _ArenaMessage(message: context.l10n.arenaEmpty);
    } else {
      middle = const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        if (playable)
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
        // O placar da semana que fechou, quando há um e ele ainda não foi
        // visto. Ele mora ENTRE o placar e a cena: é notícia, e notícia vem
        // antes do estado — mas depois das duas barras, que são o que a tela
        // existe para mostrar.
        const ArenaWeekClosingBanner(),
        Expanded(
          // Os ícones de jogo ficam POR CIMA da cena, e não numa coluna ao
          // lado dela: a cena é a tela inteira agora, e roubar 44px de
          // largura dela encolheria o mundo do Flame — os bonecos já estão
          // presos entre 130 e 280 unidades de largura de mundo. Sobrepostos,
          // eles custam zero à luta.
          child: Stack(
            children: [
              Positioned.fill(child: middle),
              // No ALTO da lateral, e não no meio dela: centrados, os quatro
              // ícones caíam exatamente na linha do chão, e o de baixo ficava
              // por cima do mago. Em cima eles pegam a parede e a faixa de
              // areia vazia acima dos bonecos, que é o pedaço da cena onde
              // nunca acontece nada.
              Positioned(
                left: 0,
                top: AppSpacing.xs,
                child: ArenaSceneIcons(compact: widget.compact),
              ),
            ],
          ),
        ),
        // A faixa do HUD mensal. O filete em cima dela é o que separa
        // "espaço reservado" de "cena cortada": sem a linha, a tarja escura no
        // pé parecia a cena terminando no meio.
        ArenaHudFooter(
          height: arenaFooterSlotHeight(compact: widget.compact),
          compact: widget.compact,
        ),
      ],
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
