import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/workspace/domain/models/workspace_model.dart';
import 'package:funances/features/workspace/presentation/model/workspace_view_model.dart';

/// A sequência mora em dois campos, porque o backend escreve os dois:
/// `weeklyStreaks` como número (o histórico) e `streaks` como mapa
/// `{missions, plan}` (o placar novo, único lugar onde a sequência de
/// planejamento existe). Um `as int` direto derrubaria a Home de todo mundo no
/// dia do deploy do backend; ler só o mapa quebraria o app antes dele.
WorkspaceModel _workspace(Object? weeklyStreaks, {Object? streaks}) {
  return WorkspaceModel.fromJson({
    'id': 'w1',
    'name': 'Casa',
    'type': 'personal',
    'members': <String>['u1'],
    'createdAt': '2026-01-01T00:00:00.000Z',
    'weeklyStreaks': ?weeklyStreaks,
    'streaks': ?streaks,
  });
}

void main() {
  group('leitura de weeklyStreaks', () {
    test('formato antigo: o número é a sequência de missões', () {
      final workspace = _workspace(4);

      expect(workspace.weeklyStreaks.missions, 4);
      // O formato antigo não contava sequência de planejamento.
      expect(workspace.weeklyStreaks.plan, 0);
    });

    test('formato novo: mapa com missions e plan', () {
      final workspace = _workspace(const {'missions': 4, 'plan': 2});

      expect(workspace.weeklyStreaks.missions, 4);
      expect(workspace.weeklyStreaks.plan, 2);
    });

    test('mapa parcial completa com zero em vez de explodir', () {
      expect(_workspace(const {'plan': 3}).weeklyStreaks.missions, 0);
      expect(_workspace(const {'plan': 3}).weeklyStreaks.plan, 3);
      expect(_workspace(const {'missions': 1}).weeklyStreaks.plan, 0);
    });

    test('campo ausente ou de tipo inesperado vira zero', () {
      expect(_workspace(null).weeklyStreaks, const WorkspaceStreaks());
      expect(_workspace('quatro').weeklyStreaks, const WorkspaceStreaks());
      expect(
        _workspace(const {'missions': 'quatro'}).weeklyStreaks.missions,
        0,
      );
    });

    test('número fracionário (nunca deveria vir) trunca sem quebrar', () {
      expect(_workspace(2.0).weeklyStreaks.missions, 2);
    });
  });

  group('campo de topo streaks', () {
    test('o plano vem do streaks, que é o único campo que o conhece', () {
      // O backend grava os dois: weeklyStreaks como número e streaks como
      // mapa. A sequência de planejamento só existe no segundo.
      final workspace = _workspace(4, streaks: const {'missions': 4, 'plan': 2});

      expect(workspace.weeklyStreaks.missions, 4);
      expect(workspace.weeklyStreaks.plan, 2);
    });

    test('streaks manda quando os dois campos discordam', () {
      // weeklyStreaks é o histórico; streaks é o placar mantido pelo servidor.
      final workspace = _workspace(1, streaks: const {'missions': 5, 'plan': 3});

      expect(workspace.weeklyStreaks.missions, 5);
      expect(workspace.weeklyStreaks.plan, 3);
    });

    test('streaks parcial completa com o que weeklyStreaks tem', () {
      final workspace = _workspace(7, streaks: const {'plan': 2});

      expect(
        workspace.weeklyStreaks.missions,
        7,
        reason: 'sem missions no mapa, vale o número do histórico',
      );
      expect(workspace.weeklyStreaks.plan, 2);
    });

    test('zero explícito no streaks é zero, e não "faltando"', () {
      // Uma sequência quebrada precisa aparecer como quebrada, mesmo com o
      // weeklyStreaks antigo ainda alto.
      final workspace = _workspace(9, streaks: const {'missions': 0, 'plan': 0});

      expect(workspace.weeklyStreaks.missions, 0);
      expect(workspace.weeklyStreaks.plan, 0);
    });

    test('streaks de tipo inesperado é ignorado, não derruba a Home', () {
      expect(_workspace(4, streaks: 'nada').weeklyStreaks.missions, 4);
      expect(
        _workspace(4, streaks: const {'missions': 'muitas'}).weeklyStreaks
            .missions,
        4,
        reason: 'valor não numérico cai no histórico em vez de virar zero',
      );
    });

    test('base anterior ao placar novo não tem streaks e segue funcionando', () {
      final workspace = _workspace(4);

      expect(workspace.weeklyStreaks.missions, 4);
      expect(workspace.weeklyStreaks.plan, 0);
    });

    test('o recorte de gamificação enxerga o plano do campo novo', () {
      final gamification = _workspace(
        4,
        streaks: const {'missions': 4, 'plan': 2},
      ).gamification;

      expect(gamification.weeklyStreaks, 4);
      expect(gamification.planStreak, 2);
    });
  });

  group('escrita de weeklyStreaks', () {
    test('sai como NÚMERO, que é o que as rules aceitam na criação', () {
      // A rule de create exige `weeklyStreaks == 0`; um mapa seria negado, e a
      // criação do workspace grava o documento inteiro.
      final json = _workspace(const {'missions': 0, 'plan': 0}).toJson();

      expect(json['weeklyStreaks'], 0);
      expect(json['weeklyStreaks'], isA<int>());
    });

    test('o campo streaks não é escrito pelo cliente', () {
      // `streaks` é do servidor. Se o app o gravasse na criação, só
      // conseguiria zerar o que o backend acabou de calcular.
      final json = _workspace(4, streaks: const {'missions': 4, 'plan': 2})
          .toJson();

      expect(json.containsKey('streaks'), isFalse);
    });

    test('um workspace novo nasce com a sequência zerada', () {
      expect(
        WorkspaceModel.empty().toJson()['weeklyStreaks'],
        0,
      );
    });
  });

  group('recorte de gamificação', () {
    test('o badge conta as missões; o planejamento fica exposto ao lado', () {
      final gamification = _workspace(
        const {'missions': 4, 'plan': 2},
      ).gamification;

      expect(gamification.weeklyStreaks, 4);
      expect(gamification.planStreak, 2);
    });

    test('formato antigo: o badge continua contando o mesmo de antes', () {
      final gamification = _workspace(4).gamification;

      expect(gamification.weeklyStreaks, 4);
      expect(gamification.planStreak, 0);
    });
  });
}
