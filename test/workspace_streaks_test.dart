import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/workspace/domain/models/workspace_model.dart';
import 'package:funances/features/workspace/presentation/model/workspace_view_model.dart';

/// O campo `weeklyStreaks` tem dois formatos em produção: o número que
/// `updateWorkspaceStreaks` sempre gravou e o mapa `{missions, plan}` do placar
/// novo. Um `as int` direto derrubaria a Home de todo mundo no dia do deploy do
/// backend; ler só o mapa quebraria o app antes desse deploy.
WorkspaceModel _workspace(Object? weeklyStreaks) {
  return WorkspaceModel.fromJson({
    'id': 'w1',
    'name': 'Casa',
    'type': 'personal',
    'members': <String>['u1'],
    'createdAt': '2026-01-01T00:00:00.000Z',
    'weeklyStreaks': ?weeklyStreaks,
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

  group('escrita de weeklyStreaks', () {
    test('sai como NÚMERO, que é o que as rules aceitam na criação', () {
      // A rule de create exige `weeklyStreaks == 0`; um mapa seria negado, e a
      // criação do workspace grava o documento inteiro.
      final json = _workspace(const {'missions': 0, 'plan': 0}).toJson();

      expect(json['weeklyStreaks'], 0);
      expect(json['weeklyStreaks'], isA<int>());
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
