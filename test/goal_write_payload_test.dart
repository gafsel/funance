import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/goal/data/repositories/goal_repository_impl.dart';
import 'package:funances/features/goal/domain/models/goal_model.dart';

/// F3.5 — o formulário de meta não faz bookkeeping. O progresso e o desfecho
/// são do servidor; o que o cliente grava é só o que ele pode gravar.
void main() {
  GoalModel meta({double currentAmount = 0, GoalOutcome? outcome}) =>
      GoalModel.saveMoney(
        id: 'g1',
        name: 'Reserva',
        targetAmount: 1000,
        currentAmount: currentAmount,
        deadline: DateTime(2026, 12, 31),
        accountId: 'acc1',
        startDate: DateTime(2026, 1, 1),
        outcome: outcome,
        completedAt: outcome == GoalOutcome.success ? DateTime(2026, 6, 1) : null,
      );

  test('criação nasce em zero, com as datas como Timestamp', () {
    final data = buildGoalWriteData(meta(currentAmount: 742), creation: true);

    expect(data['currentAmount'], 0.0);
    expect(data['deadline'], isA<Timestamp>());
    expect(data['startDate'], isA<Timestamp>());
    expect(data.containsKey('id'), isFalse);
  });

  test('edição não envia currentAmount: o progresso do servidor sobrevive', () {
    final data = buildGoalWriteData(meta(currentAmount: 742), creation: false);

    expect(data.containsKey('currentAmount'), isFalse);
    expect(data['name'], 'Reserva');
    expect(data['targetAmount'], 1000);
  });

  test('o desfecho nunca é enviado, nem como null', () {
    for (final creation in [true, false]) {
      final ativa = buildGoalWriteData(meta(), creation: creation);
      final concluida = buildGoalWriteData(
        meta(outcome: GoalOutcome.success),
        creation: creation,
      );

      for (final data in [ativa, concluida]) {
        expect(data.containsKey('outcome'), isFalse);
        expect(data.containsKey('completedAt'), isFalse);
        expect(data.containsKey('failedAt'), isFalse);
      }
    }
  });

  /// O payload acima só preserva o progresso porque a gravação é um
  /// `update()`: ele toca apenas as chaves enviadas. Um `set()` sem merge
  /// zeraria `currentAmount` justamente por ele ter sido omitido — o bug
  /// voltaria pela porta dos fundos, sem nenhum teste de payload falhar.
  ///
  /// Sem um Firestore de mentira no projeto, a garantia é lida na fonte: é
  /// grosseiro, mas pega exatamente a troca que quebraria o contrato.
  group('a gravação da edição é um update', () {
    final fonte = File(
      'lib/features/goal/data/repositories/goal_repository_impl.dart',
    ).readAsStringSync();

    String corpoDe(String assinatura) {
      final inicio = fonte.indexOf(assinatura);
      expect(inicio, isNot(-1), reason: 'método $assinatura não encontrado');
      final fim = fonte.indexOf('\n  }', inicio);
      return fonte.substring(inicio, fim);
    }

    test('updateGoal chama update(), nunca set()', () {
      final corpo = corpoDe('Future<WriteOutcome> updateGoal(');

      expect(corpo, contains('.update(data)'));
      expect(corpo, isNot(contains('.set(')));
      expect(corpo, contains('creation: false'));
    });

    test('addGoal cria o documento com set() e id gerado localmente', () {
      final corpo = corpoDe('Future<Written<GoalModel>> addGoal(');

      expect(corpo, contains('.set(data)'));
      expect(corpo, contains('creation: true'));
    });
  });
}
