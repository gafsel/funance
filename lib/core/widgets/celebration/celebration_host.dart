import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/celebration/celebration_event.dart';
import 'package:funances/core/celebration/celebration_service.dart';
import 'package:funances/core/router/app_router.dart';
import 'package:funances/core/theme/app_durations.dart';
import 'package:funances/core/widgets/celebration_overlay.dart';
import 'package:funances/core/widgets/reward_toast.dart';
import 'package:funances/features/home/domain/models/financial_health_model.dart';
import 'package:funances/features/home/domain/models/weekly_mission_model.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:funances/features/home/presentation/widgets/compass/compass_labels.dart';
import 'package:funances/features/workspace/domain/models/badge_catalog_model.dart';
import 'package:funances/features/workspace/presentation/model/workspace_view_model.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';

/// Quem escuta as conquistas e as coloca na tela, de qualquer tela.
///
/// Mora em `core/widgets/` e não em `features/home/`. Ele ficava dentro da
/// Home por herança do tempo em que o feedback de jogo nascia de um
/// `ref.listen` da `HomeScreen` — mas hoje ele é pendurado no `builder` do
/// `MaterialApp`, vale para o app inteiro e observa providers de três
/// features. Um widget que todas as telas usam morando dentro de uma delas é
/// um convite a dependências que andam para o lado errado.
///
/// Fica pendurado no `builder` do `MaterialApp`, ao lado da tarja de
/// sincronização. Antes, **todo** o feedback de jogo nascia de um único
/// `ref.listen` dentro da `HomeScreen`: quem ganhava XP dentro da Conciliação,
/// do 50-30-20 ou do formulário de transação — telas que empilham rota por
/// cima da Home — podia não ver retorno nenhum. E dois eventos não tinham
/// canal: concluir uma missão não fazia nada, e subir de patente na Bússola
/// não tinha nem listener.
///
/// O que ele observa:
///
/// | Evento | Fonte |
/// |---|---|
/// | XP e nível | `WorkspaceViewProviders.gamification` |
/// | Badge desbloqueada | idem, pela diferença de `unlockedBadges` |
/// | Missão concluída | `JourneyViewProviders.weeklyMissions`, status → `completed` |
/// | Patente | `JourneyViewProviders.financialHealth`, `tier` |
///
/// As duas últimas são `autoDispose` e antes só viviam enquanto a Jornada
/// estava montada; observá-las daqui as mantém abertas pelo app inteiro, que é
/// o preço de ver a missão fechar na tela onde ela foi cumprida.
///
/// Nada aqui celebra a PRIMEIRA emissão: abrir o app com três missões já
/// concluídas na semana passada não é uma conquista de agora.
class CelebrationHost extends ConsumerStatefulWidget {
  const CelebrationHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<CelebrationHost> createState() => _CelebrationHostState();
}

class _CelebrationHostState extends ConsumerState<CelebrationHost> {
  /// O confete acompanha só as conquistas de peso. Antes ele existia num
  /// lugar só (subir de nível, dentro da Home) e não acompanhava badge,
  /// missão nem patente.
  late final ConfettiController _confetti = ConfettiController(
    duration: AppDurations.celebrate,
  );

  int _xpSequence = 0;

  /// Status conhecido de cada missão, por id. Só a TRANSIÇÃO para concluída
  /// celebra — o Firestore reemite o documento a cada progresso.
  final Map<String, WeeklyMissionStatus> _missionStatus = {};

  FreedomTier? _tier;
  String? _workspaceId;

  CelebrationService get _service =>
      ref.read(CelebrationProviders.queue.notifier);

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  void _emit(Iterable<CelebrationEvent> events) {
    if (events.isEmpty) return;
    final settings = ref.read(CelebrationProviders.settings);

    // A ordem de ENFILEIRAMENTO é da menor para a maior conquista, e não a
    // ordem em que os eventos foram descobertos.
    //
    // Duas coisas dependem dela, e antes as duas saíam erradas numa rajada.
    // A fila tem teto e descarta pela frente: com o nível entrando antes das
    // badges, era o nível — a conquista mais forte — que caía fora quando a
    // rajada passava do teto. E a pilha na tela é desenhada nesta ordem, com
    // a última por cima, então subir de nível aparecia ABAIXO do XP que veio
    // junto.
    //
    // É a mesma regra de `celebrateAll`, e é dele que ela sai agora: havia
    // duas cópias, e só uma estava certa.
    final ordered = events.toList()
      ..sort((a, b) => a.kind.index.compareTo(b.kind.index));

    final accepted = <CelebrationEvent>[];
    for (final event in ordered) {
      if (_service.celebrate(event)) accepted.add(event);
    }
    if (accepted.isEmpty) return;

    // Uma háptica por rajada, na maior das conquistas: três vibrações
    // seguidas viram ruído. A maior é a ÚLTIMA da lista ordenada.
    final strongest = accepted.last;
    unawaited(playCelebrationFeedback(strongest, settings));

    if (strongest.kind.isMajor && !AppDurations.reduceMotion(context)) {
      _confetti.play();
    }
  }

  void _onWorkspaceChanged(String? id) {
    // Um `null` NÃO é troca de cofre.
    //
    // O `workspaceId` some por instantes sempre que o stream do workspace
    // reconecta — voltar do background, recuperar a rede, trocar de conta no
    // Firestore. O esquecimento era disparado nesse null e DE NOVO quando o
    // mesmo id voltava: tudo que já tinha sido celebrado na sessão voltava a
    // ser celebrável, e a badge de ontem piscava outra vez. A idempotência
    // que o serviço garante era desfeita por fora.
    if (id == null) return;
    if (_workspaceId == id) return;

    final previous = _workspaceId;
    _workspaceId = id;

    // Primeira carga: não há o que esquecer, e resetar aqui só descartaria a
    // fila que outra parte do app talvez já tenha enfileirado.
    if (previous == null) return;

    _missionStatus.clear();
    _tier = null;
    // As chaves são por cofre: o nível 7 da casa não é o nível 7 da empresa.
    _service.reset();
  }

  void _listenGamification() {
    ref.listen<WorkspaceGamification>(WorkspaceViewProviders.gamification, (
      previous,
      next,
    ) {
      _onWorkspaceChanged(next.workspaceId);

      if (previous == null) return;
      if (previous.workspaceId == null || next.workspaceId == null) return;
      if (previous.workspaceId != next.workspaceId) return;

      final events = <CelebrationEvent>[];

      final newBadges = next.unlockedBadges.keys.toSet().difference(
        previous.unlockedBadges.keys.toSet(),
      );
      for (final badgeId in newBadges) {
        events.add(CelebrationEvent.badge(badgeId));
      }

      if (next.level > previous.level) {
        events.add(CelebrationEvent.level(next.level));
      } else {
        // Subir de nível já conta a história do XP; dois toasts para o mesmo
        // ganho é barulho.
        final xpDelta = next.xp - previous.xp;
        if (xpDelta > 0) {
          _xpSequence++;
          events.add(CelebrationEvent.xp(xpDelta, sequence: _xpSequence));
        }
      }

      _emit(events);
    });
  }

  void _listenMissions() {
    ref.listen<AsyncValue<List<WeeklyMissionModel>>>(
      JourneyViewProviders.weeklyMissions,
      (previous, next) {
        final missions = next.valueOrNull;
        if (missions == null) return;

        final events = <CelebrationEvent>[];
        for (final mission in missions) {
          final known = _missionStatus[mission.id];
          _missionStatus[mission.id] = mission.status;

          // `known == null` é a primeira vez que vemos esta missão: pode ser
          // a carga inicial de uma semana já concluída.
          if (known == null) continue;
          if (known == mission.status) continue;
          if (!mission.status.isCompleted) continue;

          events.add(
            CelebrationEvent.mission(
              missionId: mission.id,
              name: mission.name.isEmpty ? null : mission.name,
              xp: mission.xp > 0 ? mission.xp : null,
            ),
          );
        }
        _emit(events);
      },
    );
  }

  void _listenTier() {
    ref.listen<AsyncValue<FinancialHealth?>>(
      JourneyViewProviders.financialHealth,
      (previous, next) {
        final health = next.valueOrNull;
        if (health == null) return;

        final known = _tier;
        _tier = health.tier;

        if (known == null) return;
        if (health.tier == known) return;
        if (health.tier == FreedomTier.unknown) return;
        // Só a subida celebra. Cair de patente é informação, não conquista —
        // e recebe o tratamento da Bússola, não um halo dourado.
        if (health.tier.index <= known.index) return;

        _emit([CelebrationEvent.tier(health.tier.name)]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _listenGamification();
    _listenMissions();
    _listenTier();

    final events = ref.watch(CelebrationProviders.queue);
    if (events.isEmpty) return widget.child;

    final l10n = AppLocalizations.of(context)!;
    final catalog = ref.watch(BadgeCatalogProviders.catalog).valueOrNull;
    final locale = Localizations.localeOf(context).languageCode;

    return CelebrationOverlay(
      confetti: _confetti,
      // `reversed`: a fila guarda da menor para a maior conquista — é assim
      // que o teto descarta a menor primeiro —, e a pilha na tela cresce para
      // BAIXO a partir do topo. Sem inverter, subir de nível ficava embaixo
      // do XP que veio junto, que é o contrário do que a ordem da fila
      // promete.
      toasts: [
        for (final event in events.reversed)
          RewardToast(
            key: ValueKey(event.key),
            icon: _iconOf(event.kind),
            title: _titleOf(
              l10n,
              event,
              catalogLocale: locale,
              catalog: catalog,
            ),
            subtitle: _subtitleOf(
              l10n,
              event,
              catalogLocale: locale,
              catalog: catalog,
            ),
            xpLabel: event.xp == null ? null : l10n.xpValue('+${event.xp}'),
            major: event.kind.isMajor,
            onDismiss: () => _service.dismiss(event.key),
            onTap: () => _openFor(event),
          ),
      ],
      child: widget.child,
    );
  }

  /// Abre o que a conquista promete, quando ela promete algo.
  ///
  /// A rota sai de `ref.read(routerProvider)`, e não de `GoRouter.of(context)`.
  /// O host mora no `builder` do `MaterialApp.router` — ou seja, ACIMA do
  /// `Router` na árvore —, e lá `GoRouter.of` não encontra o
  /// `InheritedGoRouter`: tocar no toast de badge ou de nível derrubava o app
  /// com "No GoRouter found in context". O provider é a mesma instância que o
  /// `MaterialApp.router` recebe como `routerConfig`, só que alcançada por
  /// fora da árvore de widgets.
  void _openFor(CelebrationEvent event) {
    switch (event.kind) {
      case CelebrationKind.badge:
      case CelebrationKind.level:
        ref.read(routerProvider).push('/workspace/badges');
      case CelebrationKind.tier:
      case CelebrationKind.mission:
      case CelebrationKind.xp:
        break;
    }
  }

  static IconData _iconOf(CelebrationKind kind) => switch (kind) {
    CelebrationKind.xp => Icons.bolt,
    CelebrationKind.mission => Icons.task_alt,
    CelebrationKind.badge => Icons.emoji_events,
    CelebrationKind.tier => Icons.explore,
    CelebrationKind.level => Icons.stars,
  };

  String _titleOf(
    AppLocalizations l10n,
    CelebrationEvent event, {
    required String catalogLocale,
    required BadgeCatalog? catalog,
  }) => switch (event.kind) {
    CelebrationKind.xp => l10n.celebrationXpTitle,
    CelebrationKind.mission => l10n.celebrationMissionTitle,
    CelebrationKind.badge => l10n.celebrationBadgeTitle,
    CelebrationKind.tier => l10n.celebrationTierTitle,
    CelebrationKind.level => l10n.celebrationLevelTitle(event.level ?? 0),
  };

  String? _subtitleOf(
    AppLocalizations l10n,
    CelebrationEvent event, {
    required String catalogLocale,
    required BadgeCatalog? catalog,
  }) {
    switch (event.kind) {
      case CelebrationKind.xp:
        return null;
      case CelebrationKind.mission:
        return event.missionName;
      case CelebrationKind.badge:
        // O catálogo pode ainda não ter chegado; o toast não espera por ele.
        final matches =
            catalog?.badges.where((b) => b.id == event.badgeId).toList() ??
            const <BadgeCatalogItem>[];
        final name = matches.isEmpty
            ? null
            : matches.first.nameIn(catalogLocale);
        return (name == null || name.isEmpty)
            ? l10n.celebrationBadgeFallback
            : name;
      case CelebrationKind.tier:
        return compassTierLabel(
          l10n,
          FreedomTier.values.firstWhere(
            (t) => t.name == event.tierName,
            orElse: () => FreedomTier.unknown,
          ),
        );
      case CelebrationKind.level:
        return l10n.celebrationLevelSubtitle;
    }
  }
}
