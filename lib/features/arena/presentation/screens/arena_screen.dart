import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_breakpoints.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/core/widgets/app_chip.dart';
import 'package:funances/core/widgets/app_scaffold.dart';
import 'package:funances/core/widgets/empty_state.dart';
import 'package:funances/core/widgets/error_view.dart';
import 'package:funances/features/arena/domain/models/arena_state.dart';
import 'package:funances/features/arena/presentation/game/arena_game.dart';
import 'package:funances/features/arena/presentation/game/arena_theme.dart';
import 'package:funances/features/arena/presentation/providers/arena_providers.dart';
import 'package:funances/features/arena/presentation/widgets/arena_hp_bar.dart';
import 'package:funances/features/arena/presentation/widgets/arena_monster_sheet.dart';
import 'package:funances/features/auth/presentation/providers.dart';
import 'package:go_router/go_router.dart';

/// A rota da Arena. Uma tela, um `GameWidget`, duas barras.
const String arenaRoutePath = '/arena';

/// A POC: a semana como uma luta.
///
/// O que está na tela e de onde vem cada número está em
/// `ArenaCalculator`; aqui só mora a ponte entre o Riverpod e o Flame, e as
/// três interações: tocar no monstro (folha de parcelas), tocar na barra de
/// vida (`/planning`) e segurar o monstro (histórico).
class ArenaScreen extends ConsumerStatefulWidget {
  const ArenaScreen({super.key});

  @override
  ConsumerState<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends ConsumerState<ArenaScreen>
    with WidgetsBindingObserver {
  ArenaGame? _game;

  /// O tema com que o jogo foi criado. Se o usuário trocar claro/escuro ou
  /// ligar "reduzir movimento" com a Arena aberta, o jogo é refeito — os
  /// componentes do Flame recebem cor na construção e não observam tema.
  ArenaTheme? _builtWith;

  /// `true` enquanto a folha de parcelas está aberta. O loop fica parado;
  /// um jogo rodando atrás de uma folha modal é bateria gasta em pixel que
  /// ninguém vê.
  bool _suspended = false;

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
      onMonsterLongPress: _openHistory,
      onCocoonTap: _openInvoice,
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
      state.pendingInstallments,
    );

    _suspended = false;
    _setRunning(true);

    if (paid == null || !mounted) return;

    // O golpe é de quem pagou. `currentUser` é o dado que existe hoje; o dia
    // em que a parcela guardar quem a quitou, é só trocar a origem.
    _game?.playStrike(
      amountLabel: '−${_money(paid.referenceAmount)}',
      striker: ref.read(AuthDomainProviders.currentUser)?.id,
    );
  }

  void _openHistory() {
    // A "mesa de controle": a aba de histórico da Home, que é onde os
    // lançamentos da semana moram de verdade.
    context.go('/');
  }

  void _openInvoice() {
    final id = _state?.invoiceInstallmentId;
    if (id == null) return;
    context.push('/invoices/$id');
  }

  void _openPlanning() => context.push('/planning');

  /// Reage a um estado NOVO: cura, dano e a sincronia da cena.
  void _onStateChanged(ArenaState? previous, ArenaState next) {
    final game = _game;
    if (game == null) return;

    game.applyState(next, animate: previous != null);

    if (previous == null) return;

    // A cura e o dano são DIFERENÇAS, não totais: o que interessa mostrar é
    // o que acabou de acontecer.
    final healed = next.healedThisWeek - previous.healedThisWeek;
    if (healed > 0) game.playHeal('+${_money(healed)}');

    final hurt = next.damageThisWeek - previous.damageThisWeek;
    if (hurt > 0) game.playDamage('−${_money(hurt)}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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

    return AppScaffold(
      constrained: false,
      backgroundColor: AppColors.surfaceDeep,
      appBar: AppBar(
        title: Text(l10n.arenaTitle),
        backgroundColor: AppColors.surfaceDeep,
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Padding(
          padding: AppSpacing.allMd,
          child: ErrorView.forError(context, error),
        ),
        data: (state) {
          final game = _gameFor(ArenaTheme.of(context));

          // O `ref.listen` acima só dispara em MUDANÇA — o primeiro estado
          // nunca passaria por ele, e a cena abriria sem monstro nenhum.
          // `applyState` sai cedo quando o estado é igual, então repetir isto
          // a cada build não custa nada.
          game.applyState(state, animate: false);

          return _ArenaBody(
            state: state,
            game: game,
            onOpenPlanning: _openPlanning,
            onOpenMonster: _openMonsterSheet,
          );
        },
      ),
    );
  }
}

class _ArenaBody extends StatelessWidget {
  const _ArenaBody({
    required this.state,
    required this.game,
    required this.onOpenPlanning,
    required this.onOpenMonster,
  });

  final ArenaState state;
  final ArenaGame game;
  final VoidCallback onOpenPlanning;
  final VoidCallback onOpenMonster;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = context.palette;

    // A etiqueta da cicatriz é montada AQUI porque é aqui que existem
    // tradução e formatação de moeda — o componente do Flame só recebe texto.
    game.overdueLabel = (value) => l10n.arenaEnraged(
      value.overdueAmount.asCurrency(locale: context.locale),
    );

    if (state.isEmpty) {
      return EmptyState.centered(
        icon: Icons.shield_outlined,
        title: l10n.arenaWeekMonster,
        message: l10n.arenaEmpty,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = constraints.layout;

        // A cena fica com metade da altura no compacto e um pouco mais no
        // largo, e nunca menos de 180 — abaixo disso os bonecos ficam do
        // tamanho de um ícone e a animação deixa de comunicar.
        final sceneHeight = (constraints.maxHeight *
                (layout.usesRail ? 0.62 : 0.52))
            .clamp(180.0, 420.0);

        return Column(
          children: [
            SizedBox(
              height: sceneHeight,
              width: double.infinity,
              child: GameWidget(game: game),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xs,
                AppSpacing.sm,
                AppSpacing.xs,
                AppSpacing.xs,
              ),
              child: Column(
                children: [
                  ArenaHpBar(
                    label: l10n.arenaHeroLife,
                    value: state.heroHp,
                    ratio: state.heroHpRatio,
                    committedRatio: state.committedRatio,
                    color: state.heroMood == HeroMood.exhausted
                        ? palette.dangerText
                        : AppColors.teal,
                    onTap: onOpenPlanning,
                    semanticsHint: l10n.arenaCommitted,
                    trailing: _heroTrailing(context),
                  ),
                  AppSpacing.gapXs,
                  ArenaHpBar(
                    label: l10n.arenaWeekMonster,
                    value: state.monsterHp,
                    ratio: state.monsterHpRatio,
                    color: AppColors.violet,
                    onTap: onOpenMonster,
                    trailing: state.hasFled
                        ? StatusPill(
                            label: l10n.arenaMonsterFled,
                            tone: StatusTone.ok,
                            dense: true,
                            onGame: true,
                          )
                        : state.isEnraged
                        ? StatusPill(
                            label: l10n.arenaEnraged(
                              state.overdueAmount.asCurrency(
                                locale: context.locale,
                              ),
                            ),
                            tone: StatusTone.danger,
                            dense: true,
                            onGame: true,
                          )
                        : null,
                  ),
                ],
              ),
            ),
            if ((state.invoiceAmount ?? 0) > 0)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xxs,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.egg_outlined,
                      size: 14,
                      color: palette.onGame2,
                    ),
                    AppSpacing.gapXxs,
                    Text(
                      '${l10n.arenaInvoiceCocoon} · '
                      '${state.invoiceAmount!.asCurrency(locale: context.locale)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: palette.onGame2,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget? _heroTrailing(BuildContext context) {
    final l10n = context.l10n;

    if (state.heroMood == HeroMood.exhausted) {
      return StatusPill(
        label: l10n.arenaExhausted,
        tone: StatusTone.danger,
        dense: true,
        onGame: true,
      );
    }

    if (state.extraMembers > 0) {
      return StatusPill(
        label: l10n.arenaTeamExtra(state.extraMembers),
        tone: StatusTone.neutral,
        dense: true,
        onGame: true,
      );
    }

    return null;
  }
}

