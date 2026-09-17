import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/time/clock.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/home/domain/models/mission_model.dart';
import 'package:funances/features/home/domain/models/weekly_mission_model.dart';
import 'package:funances/features/home/domain/services/journey_service.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:funances/features/home/presentation/widgets/weekly_missions_view.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';

import 'support/journey_fakes.dart';

/// F2.4 — o app tinha DOIS sistemas de missão. O do servidor
/// (`weekly_missions`, com nome, alvo, progresso e XP de verdade) nunca
/// chegava à tela; o do cliente inventava 15 XP por parcela paga e mostrava
/// uma barra de progresso sobre um total que não existia em lugar nenhum.
MissionModel _checklist({
  List<InstallmentMission> pending = const [],
  List<InstallmentMission> completed = const [],
  List<InstallmentMission> overdue = const [],
}) {
  return MissionModel(
    pendingInstallments: pending,
    completedInstallments: completed,
    overdueInstallments: overdue,
    planningMissions: const [],
    startDate: DateTime(2026, 9, 13),
    endDate: DateTime(2026, 9, 19, 23, 59, 59),
  );
}

InstallmentMission _item(String description, {double? xp, bool paid = false}) {
  return InstallmentMission(
    isAdherent: paid,
    installment: InstallmentModel(
      id: description,
      orderId: 'o-$description',
      amount: 100,
      description: description,
      dueDate: DateTime(2026, 9, 15, 12),
      status: paid ? InstallmentStatus.paid : InstallmentStatus.pending,
      type: OrderType.expense,
      installmentType: InstallmentType.single,
      xp: xp,
    ),
  );
}

const _mission = WeeklyMissionModel(
  id: 'consistency',
  name: 'Planejar limites para 3 categorias',
  type: WeeklyMissionType.consistency,
  status: WeeklyMissionStatus.pending,
  weekId: '2026-W37',
  target: 3,
  progress: 1,
  xp: 150,
);

const _doneMission = WeeklyMissionModel(
  id: 'organization',
  name: 'Conciliar um extrato com 5 itens',
  type: WeeklyMissionType.organization,
  status: WeeklyMissionStatus.completed,
  weekId: '2026-W37',
  target: 5,
  progress: 7,
  xp: 200,
);

List<Override> _overrides({
  required FakeJourneyRepository repository,
  String? currentWeekId = '2026-W37',
  MissionModel? checklist,
}) {
  return [
    WorkspaceViewProviders.workspace.overrideWith(
      (ref) => TestWorkspaceNotifier(
        workspaceStateFor(currentWeekId: currentWeekId),
      ),
    ),
    JourneyDomainProviders.repository.overrideWithValue(repository),
    MissionViewProviders.mission.overrideWith(
      (ref) => Stream.value(checklist ?? _checklist()),
    ),
  ];
}

Widget _app(List<Override> overrides) {
  return ProviderScope(
    overrides: overrides,
    child: const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('pt', 'BR')],
      locale: Locale('pt', 'BR'),
      home: Scaffold(
        body: SingleChildScrollView(child: WeeklyMissionsView()),
      ),
    ),
  );
}

void main() {
  // `todayProvider` observa o ciclo de vida do app: sem binding, lê-lo dentro
  // de um `test()` explode.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('JourneyService.weekIdFor', () {
    test('concorda com o vetor compartilhado com o servidor', () {
      final raw = File(
        'functions/src/test/fixtures/week_vectors.json',
      ).readAsStringSync();
      final cases = (jsonDecode(raw) as Map<String, dynamic>)['cases'] as List;

      expect(cases, isNotEmpty);

      for (final entry in cases.cast<Map<String, dynamic>>()) {
        // O vetor descreve o horário LOCAL do produto; no app, "local" é
        // exatamente esse fuso. Construir um DateTime local a partir dos
        // componentes é o que o relógio do dispositivo entrega.
        final local = DateTime.parse(
          (entry['saoPauloLocal'] as String).replaceFirst(' ', 'T'),
        );

        expect(
          JourneyService.weekIdFor(local),
          entry['expectedWeekId'],
          reason: entry['label'] as String,
        );
      }
    });

    test('a semana começa no domingo', () {
      // 13/09/2026 é domingo: ele e o sábado seguinte estão na mesma semana.
      expect(JourneyService.weekIdFor(DateTime(2026, 9, 13)), '2026-W37');
      expect(JourneyService.weekIdFor(DateTime(2026, 9, 19, 23)), '2026-W37');
      // O sábado anterior ainda é a semana passada.
      expect(JourneyService.weekIdFor(DateTime(2026, 9, 12, 23)), '2026-W36');
    });
  });

  group('JourneyViewProviders', () {
    test('lê a semana corrente do workspace, sem recalcular', () async {
      final repository = FakeJourneyRepository(missions: [_mission]);
      final container = ProviderContainer(
        overrides: _overrides(repository: repository),
      );
      addTearDown(container.dispose);

      final missions = await container.read(
        JourneyViewProviders.weeklyMissions.future,
      );

      expect(missions, [_mission]);
      expect(repository.missionCalls, [('w1', '2026-W37')]);
    });

    test(
      'sem currentWeekId no workspace, cai no cálculo local em vez de ficar '
      'sem missões',
      () async {
        final repository = FakeJourneyRepository();
        final container = ProviderContainer(
          overrides: [
            ..._overrides(repository: repository, currentWeekId: null),
            clockProvider.overrideWithValue(() => DateTime(2026, 9, 16, 10)),
          ],
        );
        addTearDown(container.dispose);

        await container.read(JourneyViewProviders.weeklyMissions.future);

        expect(repository.missionCalls, [('w1', '2026-W37')]);
      },
    );

    test('o XP da semana vem do servidor, não de uma soma local', () async {
      final repository = FakeJourneyRepository(xp: 320);
      final container = ProviderContainer(
        overrides: _overrides(repository: repository),
      );
      addTearDown(container.dispose);

      expect(await container.read(JourneyViewProviders.weeklyXp.future), 320);
      expect(repository.xpCalls, [('w1', '2026-W37')]);
    });
  });

  group('WeeklyMissionsView', () {
    testWidgets('mostra as missões do servidor com alvo, progresso e XP', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          _overrides(
            repository: FakeJourneyRepository(
              missions: [_mission, _doneMission],
              xp: 150,
            ),
          ),
        ),
      );
      await tester.pump();

      final l10n = await AppLocalizations.delegate.load(
        const Locale('pt', 'BR'),
      );

      expect(find.text(_mission.name), findsOneWidget);
      expect(find.text(_doneMission.name), findsOneWidget);
      expect(find.text(l10n.journeyMissionProgress(1, 3)), findsOneWidget);
      expect(find.text(l10n.xpValue('150')), findsWidgets);
      expect(find.text(l10n.xpValue('200')), findsOneWidget);
      // A missão concluída mostra o alvo cheio, não o progresso bruto (7).
      expect(find.text(l10n.journeyMissionDone), findsOneWidget);
      expect(find.textContaining('7 de 5'), findsNothing);
    });

    testWidgets(
      'o XP da semana é um número honesto: sem barra e sem teto de missões',
      (tester) async {
        await tester.pumpWidget(
          _app(
            _overrides(
              repository: FakeJourneyRepository(
                missions: [_mission, _doneMission],
                xp: 175,
              ),
            ),
          ),
        );
        await tester.pump();

        final l10n = await AppLocalizations.delegate.load(
          const Locale('pt', 'BR'),
        );

        expect(find.text(l10n.xpValue('175')), findsOneWidget);
        // O rótulo diz de onde vem o número: `weekly_xp` só acumula XP de
        // parcelas, enquanto o XP das missões é creditado em `workspaces.xp`.
        expect(find.text(l10n.journeyWeeklyXpCaption), findsOneWidget);

        // Nada de barra com o `weekly_xp` sobre a soma do XP das missões: os
        // dois nunca se somam no servidor, então completar as três missões
        // não moveria a barra e o teto seria uma promessa falsa.
        expect(find.textContaining('350'), findsNothing);

        // As únicas barras da tela são as das missões, cada uma com o próprio
        // alvo — uma por missão com `target > 0`.
        final bars = tester
            .widgetList<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .toList();
        expect(bars, hasLength(2));
        expect(bars.first.value, closeTo(1 / 3, 0.0001));
        expect(bars.last.value, 1.0);
      },
    );

    testWidgets('sem weekly_xp publicado, diz que não há XP em vez de zero', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(_overrides(repository: FakeJourneyRepository())),
      );
      await tester.pump();

      final l10n = await AppLocalizations.delegate.load(
        const Locale('pt', 'BR'),
      );

      expect(find.text(l10n.journeyWeeklyXpEmpty), findsOneWidget);
      expect(find.text(l10n.journeyMissionsSoonTitle), findsOneWidget);
    });

    testWidgets('o checklist mostra o XP da parcela, nunca um inventado', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          _overrides(
            repository: FakeJourneyRepository(),
            checklist: _checklist(
              pending: [_item('Sem XP no documento')],
              completed: [_item('Luz', xp: 12, paid: true)],
            ),
          ),
        ),
      );
      await tester.pump();

      final l10n = await AppLocalizations.delegate.load(
        const Locale('pt', 'BR'),
      );

      expect(find.text(l10n.journeyChecklistTitle), findsOneWidget);
      // A parcela sem XP no documento não ganha os 15 XP que o app costumava
      // exibir por conta própria.
      expect(find.text(l10n.xpValue('15')), findsNothing);
      expect(find.text(l10n.xpValue('5')), findsNothing);
      // E a soma das concluídas é a dos XP que o servidor gravou.
      expect(find.text(l10n.completedMissionsSummary(1, '12')), findsOneWidget);
    });

    /// F3.6 — a conciliação morava dentro da tela de UMA conta. A missão de
    /// organização é onde o usuário está quando quer pôr a casa em ordem, e é
    /// dali que o caminho precisa sair.
    testWidgets('missão de organização aberta oferece conciliar o extrato', (
      tester,
    ) async {
      const aberta = WeeklyMissionModel(
        id: 'organization',
        name: 'Conciliar um extrato com 5 itens',
        type: WeeklyMissionType.organization,
        status: WeeklyMissionStatus.pending,
        weekId: '2026-W37',
        target: 5,
        progress: 1,
        xp: 200,
      );

      await tester.pumpWidget(
        _app(
          _overrides(repository: FakeJourneyRepository(missions: [aberta])),
        ),
      );
      await tester.pump();

      final l10n = await AppLocalizations.delegate.load(
        const Locale('pt', 'BR'),
      );

      expect(find.text(l10n.reconciliationMissionCta), findsOneWidget);
    });

    testWidgets('missão concluída não insiste, e as outras não oferecem', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          _overrides(
            repository: FakeJourneyRepository(
              missions: [_doneMission, _mission],
            ),
          ),
        ),
      );
      await tester.pump();

      final l10n = await AppLocalizations.delegate.load(
        const Locale('pt', 'BR'),
      );

      expect(find.text(l10n.reconciliationMissionCta), findsNothing);
    });
  });
}
