import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/home/data/models/journey_mapper.dart';
import 'package:funances/features/home/domain/models/financial_health_model.dart';
import 'package:funances/features/home/domain/models/weekly_mission_model.dart';

/// F2.4 — o app lê o documento que o SERVIDOR grava, não o do contrato
/// escrito. Os dois divergem hoje: `gamification.service.ts` grava `rewardXp`
/// e `status: "pending"`, enquanto o contrato do produto fala em `xp` e
/// `active`. O mapper aceita os dois para que servidor e app possam ir a
/// produção em qualquer ordem.
void main() {
  group('weeklyMissionFromMap', () {
    test('lê o documento LITERAL de createWeeklyMission', () {
      // Cópia fiel de `gamification.service.ts:749-758` (missão de
      // consistência), com o id de documento `{weekId}_{type}`.
      final mission = weeklyMissionFromMap('2026-W37_consistency', {
        'id': 'consistency',
        'name':
            'Equipe planeja limites para pelo menos 3 categorias para '
            'organizar a semana.',
        'type': 'consistency',
        'status': 'pending',
        'rewardXp': 150,
        'progress': 0,
        'target': 3,
        'weekId': '2026-W37',
        'createdAt': '2026-09-13T03:00:00.000Z',
      });

      expect(mission.id, 'consistency');
      expect(mission.type, WeeklyMissionType.consistency);
      expect(mission.status, WeeklyMissionStatus.pending);
      expect(mission.weekId, '2026-W37');
      expect(mission.target, 3);
      expect(mission.progress, 0);
      // `rewardXp` é o nome no servidor; o app o expõe como `xp`.
      expect(mission.xp, 150);
      expect(mission.completion, 0);
      expect(mission.name, contains('3 categorias'));
    });

    test('a missão de disciplina paga 250 e a de organização 200', () {
      final disciplina = weeklyMissionFromMap('2026-W37_discipline', {
        'id': 'discipline',
        'name': 'Equipe mantém a categoria Alimentação dentro do orçamento '
            'planejado por 5 dias.',
        'type': 'discipline',
        'status': 'pending',
        'rewardXp': 250,
        'progress': 2,
        'target': 5,
        'weekId': '2026-W37',
        'createdAt': '2026-09-13T03:00:00.000Z',
      });

      final organizacao = weeklyMissionFromMap('2026-W37_organization', {
        'id': 'organization',
        'name': 'Fazer a conciliação bancária completa de um extrato contendo '
            'pelo menos 5 itens.',
        'type': 'organization',
        'status': 'pending',
        'rewardXp': 200,
        'progress': 0,
        'target': 5,
        'weekId': '2026-W37',
        'createdAt': '2026-09-13T03:00:00.000Z',
      });

      expect(disciplina.type, WeeklyMissionType.discipline);
      expect(disciplina.xp, 250);
      expect(disciplina.completion, closeTo(0.4, 0.0001));

      expect(organizacao.type, WeeklyMissionType.organization);
      expect(organizacao.xp, 200);
    });

    test('a missão concluída mostra o alvo, não o progresso que a fechou', () {
      // `completeMissionAndAwardXp` grava o progresso que fechou a missão, que
      // pode passar do alvo (7 conciliações para um alvo de 5).
      final mission = weeklyMissionFromMap('2026-W37_organization', {
        'id': 'organization',
        'name': 'Conciliar um extrato',
        'type': 'organization',
        'status': 'completed',
        'rewardXp': 200,
        'progress': 7,
        'target': 5,
        'weekId': '2026-W37',
      });

      expect(mission.status, WeeklyMissionStatus.completed);
      expect(mission.displayProgress, 5);
      expect(mission.completion, 1.0);
    });

    test('aceita `xp` e os status do contrato do produto', () {
      final mission = weeklyMissionFromMap('2026-W37_consistency', {
        'id': 'consistency',
        'name': 'Planejar',
        'type': 'consistency',
        'status': 'active',
        'xp': 150,
        'progress': 1,
        'target': 3,
        'weekId': '2026-W37',
      });

      expect(mission.xp, 150);
      expect(mission.status, WeeklyMissionStatus.active);

      final falhou = weeklyMissionFromMap('2026-W36_consistency', {
        'status': 'failed',
        'weekId': '2026-W36',
      });
      expect(falhou.status, WeeklyMissionStatus.failed);
      expect(falhou.status.isFailed, isTrue);
    });

    test('documento incompleto não derruba a tela', () {
      final mission = weeklyMissionFromMap('2026-W37_novidade', const {});

      // O id do documento vira o id do modelo quando o campo falta.
      expect(mission.id, '2026-W37_novidade');
      expect(mission.name, '');
      expect(mission.type, WeeklyMissionType.unknown);
      expect(mission.status, WeeklyMissionStatus.unknown);
      expect(mission.xp, 0);
      expect(mission.completion, 0);
    });
  });

  group('financialHealthFromMap', () {
    test('lê o índice com os quatro componentes', () {
      final health = financialHealthFromMap({
        'score': 62,
        'tier': 'estrategista',
        'monthKey': '2026-08',
        'components': {
          'folego': {'score': 40, 'months': 2.5},
          'poupanca': {'score': 70, 'rate': 0.18},
          'disciplina': {'score': 80, 'within': 8, 'total': 10},
          'alivio': {'score': 55, 'delta': -320},
        },
      });

      expect(health, isNotNull);
      expect(health!.score, 62);
      expect(health.tier, FreedomTier.estrategista);
      expect(health.monthKey, '2026-08');
      expect(health.components, hasLength(4));

      expect(health.componentOf(FreedomComponent.folego)!.months, 2.5);
      expect(health.componentOf(FreedomComponent.poupanca)!.rate, 0.18);
      expect(health.componentOf(FreedomComponent.disciplina)!.within, 8);
      expect(health.componentOf(FreedomComponent.disciplina)!.total, 10);
      expect(health.componentOf(FreedomComponent.alivio)!.delta, -320);
    });

    test('sem score não há índice', () {
      expect(financialHealthFromMap(null), isNull);
      expect(financialHealthFromMap(const {}), isNull);
      expect(financialHealthFromMap(const {'tier': 'mestre'}), isNull);
    });

    test('componente sem score some, os outros ficam', () {
      final health = financialHealthFromMap({
        'score': 50,
        'tier': 'estrategista',
        'components': {
          'folego': {'months': 2.5},
          'poupanca': {'score': 70},
        },
      });

      expect(health!.componentOf(FreedomComponent.folego), isNull);
      expect(health.componentOf(FreedomComponent.poupanca)!.score, 70);
      expect(health.components, hasLength(1));
    });

    test('tier ausente ou desconhecido vem da faixa do score', () {
      // Mostrar 84 pontos ao lado de "Em avaliação" faria o índice parecer
      // inválido justamente para quem está indo bem.
      expect(
        financialHealthFromMap(const {'score': 84})!.tier,
        FreedomTier.livre,
      );
      expect(
        financialHealthFromMap(const {'score': 25, 'tier': 'patente_nova'})!
            .tier,
        FreedomTier.guardiao,
      );
    });

    test('o tier do servidor tem prioridade sobre a faixa', () {
      // Se o servidor mudar a régua, a tela acompanha sem deploy do app.
      final health = financialHealthFromMap(const {
        'score': 10,
        'tier': 'livre',
      });

      expect(health!.tier, FreedomTier.livre);
    });
  });

  group('FreedomTier.forScore', () {
    test('as faixas do produto, nas bordas', () {
      expect(FreedomTier.forScore(0), FreedomTier.aprendiz);
      expect(FreedomTier.forScore(19), FreedomTier.aprendiz);
      expect(FreedomTier.forScore(20), FreedomTier.guardiao);
      expect(FreedomTier.forScore(39), FreedomTier.guardiao);
      expect(FreedomTier.forScore(40), FreedomTier.estrategista);
      expect(FreedomTier.forScore(59), FreedomTier.estrategista);
      expect(FreedomTier.forScore(60), FreedomTier.mestre);
      expect(FreedomTier.forScore(79), FreedomTier.mestre);
      expect(FreedomTier.forScore(80), FreedomTier.livre);
      expect(FreedomTier.forScore(100), FreedomTier.livre);
    });

    test('nenhum score cai em "em avaliação"', () {
      for (var score = 0; score <= 100; score++) {
        expect(
          FreedomTier.forScore(score.toDouble()),
          isNot(FreedomTier.unknown),
          reason: 'score $score',
        );
      }
    });
  });

  group('healthPointFromMap', () {
    test('o id do documento é a chave do mês', () {
      final point = healthPointFromMap('2026-07', const {'score': 55});

      expect(point!.monthKey, '2026-07');
      expect(point.score, 55);
      // Sem tier no documento, a faixa responde.
      expect(point.tier, FreedomTier.estrategista);
    });

    test('mês sem score é descartado', () {
      expect(healthPointFromMap('2026-07', const {}), isNull);
    });
  });
}
