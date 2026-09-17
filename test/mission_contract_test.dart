import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/theme/app_theme.dart';
import 'package:funances/features/home/data/models/journey_mapper.dart';
import 'package:funances/features/home/domain/models/weekly_mission_model.dart';
import 'package:funances/features/home/presentation/widgets/missions/mission_card.dart';
import 'package:funances/features/home/presentation/widgets/missions/mission_labels.dart';
import 'package:funances/features/workspace/domain/models/badge_catalog_model.dart';
import 'package:funances/features/workspace/domain/models/workspace_model.dart';
import 'package:funances/l10n/app_localizations.dart';

/// F-design/6 — o contrato novo das missões e das badges, que o servidor já
/// publica em produção e o app ignorava: `templateKey`, `workspaceType`,
/// `actionPath`, `nameKey`, `params` na missão, e `audience` na badge.

Future<AppLocalizations> _l10n(String code) =>
    AppLocalizations.delegate.load(Locale(code));

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  String locale = 'pt',
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale(locale),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
  await tester.pump();
}

void main() {
  group('mapper', () {
    test('lê os campos novos do documento', () {
      final mission = weeklyMissionFromMap('2026-W37_consistency', {
        'name': 'Planejar limites para pelo menos 3 categorias...',
        'type': 'consistency',
        'status': 'active',
        'weekId': '2026-W37',
        'target': 3,
        'progress': 1,
        'rewardXp': 150,
        'templateKey': 'personal_consistency_plan_limits',
        'workspaceType': 'personal',
        'actionPath': '/planning',
        'nameKey': 'missionPersonalConsistencyPlanLimits',
        'params': {'target': 3},
      });

      expect(mission.templateKey, 'personal_consistency_plan_limits');
      expect(mission.workspaceType, WorkspaceAudience.personal);
      expect(mission.actionPath, '/planning');
      expect(mission.nameKey, 'missionPersonalConsistencyPlanLimits');
      expect(
        mission.params,
        {'target': '3'},
        reason: 'o servidor grava número; a frase precisa de texto',
      );
      expect(mission.targetLabel, '3');
    });

    test('um documento anterior ao contrato continua abrindo a tela', () {
      final mission = weeklyMissionFromMap('antiga', {
        'name': 'Missão de antes',
        'type': 'organization',
        'status': 'pending',
        'weekId': '2026-W30',
        'target': 5,
      });

      expect(mission.templateKey, isEmpty);
      expect(mission.workspaceType, isNull);
      expect(mission.actionPath, isNull);
      expect(mission.nameKey, isNull);
      expect(mission.params, isEmpty);
      expect(mission.targetLabel, '5', reason: 'cai no campo target');
    });

    test('workspaceType desconhecido não derruba o mapper', () {
      final mission = weeklyMissionFromMap('x', {
        'weekId': 'w',
        'workspaceType': 'franquia',
      });
      expect(mission.workspaceType, isNull);
    });
  });

  group('nome da missão', () {
    test('prefere nameKey + params ao name do servidor', () async {
      final l10n = await _l10n('pt');
      final mission = WeeklyMissionModel(
        id: 'm',
        name: 'TEXTO DO SERVIDOR',
        type: WeeklyMissionType.consistency,
        status: WeeklyMissionStatus.active,
        weekId: 'w',
        nameKey: 'missionPersonalConsistencyPlanLimits',
        params: const {'target': '3'},
      );

      expect(
        missionName(l10n, mission),
        'Planejar limites para pelo menos 3 categorias e organizar a semana.',
      );
    });

    test('a mesma missão sai em inglês num app em inglês', () async {
      final l10n = await _l10n('en');
      final mission = WeeklyMissionModel(
        id: 'm',
        name: 'Conciliar 5 itens',
        type: WeeklyMissionType.organization,
        status: WeeklyMissionStatus.active,
        weekId: 'w',
        nameKey: 'missionPersonalOrganizationReconcileItems',
        params: const {'target': '5'},
      );

      expect(
        missionName(l10n, mission),
        'Fully reconcile a statement with at least 5 items.',
        reason:
            'o servidor grava o nome em português; sem nameKey quem usa o app '
            'em inglês lia uma frase no idioma errado',
      );
    });

    test('usa o params.target do documento, não o campo target', () async {
      final l10n = await _l10n('pt');
      final mission = WeeklyMissionModel(
        id: 'm',
        name: '',
        type: WeeklyMissionType.consistency,
        status: WeeklyMissionStatus.active,
        weekId: 'w',
        target: 99,
        nameKey: 'missionPersonalConsistencyPlanLimits',
        params: const {'target': '3'},
      );

      expect(missionName(l10n, mission), contains('3 categorias'));
      expect(missionName(l10n, mission), isNot(contains('99')));
    });

    test('sem a categoria, a frase fala do papel dela', () async {
      final l10n = await _l10n('pt');

      final pessoal = WeeklyMissionModel(
        id: 'm',
        name: '',
        type: WeeklyMissionType.discipline,
        status: WeeklyMissionStatus.active,
        weekId: 'w',
        nameKey: 'missionPersonalDisciplineTopCategory',
        workspaceType: WorkspaceAudience.personal,
        params: const {'target': '5'},
      );
      expect(missionName(l10n, pessoal), contains('de maior gasto'));

      final empresa = pessoal.copyWith(
        nameKey: 'missionBusinessDisciplineTopCostCenter',
        workspaceType: WorkspaceAudience.business,
      );
      expect(missionName(l10n, empresa), contains('de maior peso'));
    });

    test('chave que o app não conhece cai no name do servidor', () async {
      final l10n = await _l10n('pt');
      final mission = WeeklyMissionModel(
        id: 'm',
        name: 'Missão de um catálogo mais novo',
        type: WeeklyMissionType.unknown,
        status: WeeklyMissionStatus.active,
        weekId: 'w',
        nameKey: 'missionPersonalAlgoQueAindaNaoExiste',
      );

      expect(missionName(l10n, mission), 'Missão de um catálogo mais novo');
    });
  });

  group('allowlist de actionPath', () {
    test('aceita exatamente as sete rotas do catálogo', () {
      for (final path in const [
        '/planning',
        '/planning-50-30-20',
        '/reconciliation',
        '/workspace/categories',
        '/workspace/accounts',
        '/category-details',
        '/transactions/form',
      ]) {
        expect(missionActionPathIsAllowed(path), isTrue, reason: path);
      }
    });

    test('inclui /reconciliation, que a allowlist do coaching não tem', () {
      expect(missionActionPathIsAllowed('/reconciliation'), isTrue);
    });

    test('a query não muda a permissão', () {
      expect(
        missionActionPathIsAllowed('/transactions/form?status=pending'),
        isTrue,
      );
    });

    test('rota fora da lista não vira botão', () {
      expect(missionActionPathIsAllowed('/workspace/settings'), isFalse);
      expect(missionActionPathIsAllowed('https://exemplo.com'), isFalse);
      expect(missionActionPathIsAllowed(null), isFalse);
      expect(missionActionPathIsAllowed(''), isFalse);
    });
  });

  group('MissionCard', () {
    WeeklyMissionModel base({
      String? actionPath,
      WeeklyMissionStatus status = WeeklyMissionStatus.active,
      WeeklyMissionType type = WeeklyMissionType.consistency,
    }) => WeeklyMissionModel(
      id: 'm',
      name: 'nome do servidor',
      type: type,
      status: status,
      weekId: 'w',
      target: 3,
      progress: 1,
      xp: 150,
      actionPath: actionPath,
      nameKey: 'missionPersonalConsistencyPlanLimits',
      params: const {'target': '3'},
    );

    testWidgets('mostra a frase traduzida, não o texto cru', (tester) async {
      await _pump(tester, MissionCard(mission: base()));

      expect(find.textContaining('3 categorias'), findsOneWidget);
      expect(find.text('nome do servidor'), findsNothing);
    });

    testWidgets('o CTA vem do actionPath e não do tipo da missão', (
      tester,
    ) async {
      await _pump(tester, MissionCard(mission: base(actionPath: '/planning')));

      expect(find.text('Planejar agora'), findsOneWidget);
    });

    testWidgets('uma missão de consistência também pode levar ao extrato', (
      tester,
    ) async {
      await _pump(
        tester,
        MissionCard(mission: base(actionPath: '/reconciliation')),
      );

      expect(
        find.text('Conciliar extrato agora'),
        findsOneWidget,
        reason:
            'antes só a missão de organização tinha botão, e ele levava sempre '
            'para a conciliação',
      );
    });

    testWidgets('actionPath fora da allowlist não desenha botão', (
      tester,
    ) async {
      await _pump(
        tester,
        MissionCard(mission: base(actionPath: '/workspace/settings')),
      );

      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('sem actionPath não há botão', (tester) async {
      await _pump(tester, MissionCard(mission: base()));
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('missão cumprida esconde o botão', (tester) async {
      await _pump(
        tester,
        MissionCard(
          mission: base(
            actionPath: '/planning',
            status: WeeklyMissionStatus.completed,
          ),
        ),
      );

      expect(find.byType(TextButton), findsNothing);
      expect(find.text('Missão cumprida'), findsOneWidget);
    });
  });

  group('vitrine de badges por público', () {
    BadgeCatalogItem badge(String id, BadgeAudience audience) =>
        BadgeCatalogItem(
          id: id,
          name: {'pt': id},
          audience: audience,
          category: BadgeCategory.savings,
        );

    final catalog = BadgeCatalog(
      badges: [
        badge('regra_de_ouro', BadgeAudience.personal),
        badge('margem_firme', BadgeAudience.business),
        badge('primeiro_passo', BadgeAudience.both),
      ],
    );

    test('a casa não vê as metas da empresa', () {
      final visible = catalog
          .forWorkspace(WorkspaceType.personal, const {})
          .badges
          .map((b) => b.id);

      expect(visible, containsAll(['regra_de_ouro', 'primeiro_passo']));
      expect(visible, isNot(contains('margem_firme')));
    });

    test('a empresa não vê as metas da casa', () {
      final visible = catalog
          .forWorkspace(WorkspaceType.business, const {})
          .badges
          .map((b) => b.id);

      expect(visible, containsAll(['margem_firme', 'primeiro_passo']));
      expect(visible, isNot(contains('regra_de_ouro')));
    });

    test('o que já foi conquistado nunca some da estante', () {
      final visible = catalog
          .forWorkspace(WorkspaceType.business, const {
            'regra_de_ouro': '2026-07-01T00:00:00.000Z',
          })
          .badges
          .map((b) => b.id);

      expect(
        visible,
        contains('regra_de_ouro'),
        reason:
            'o cofre pode ter mudado de tipo; a conquista foi ganha e apagá-la '
            'seria negar o que aconteceu',
      );
    });

    test('badge sem o campo audience vale para os dois', () {
      final semCampo = BadgeCatalogItem.fromJson(const {
        'id': 'antiga',
        'name': {'pt': 'Antiga'},
      });

      expect(semCampo.audience, BadgeAudience.both);
      expect(semCampo.audience.appliesTo(WorkspaceType.personal), isTrue);
      expect(semCampo.audience.appliesTo(WorkspaceType.business), isTrue);
    });

    test('audience desconhecido do servidor cai em "both"', () {
      final futura = BadgeCatalogItem.fromJson(const {
        'id': 'futura',
        'audience': 'franquia',
      });

      expect(futura.audience, BadgeAudience.both);
    });
  });
}
