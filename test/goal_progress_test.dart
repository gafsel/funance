import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/goal/domain/models/goal_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

/// F4.10 §6.5, risco nº 6 — `GoalModel.calculateProgress` não tinha NENHUM
/// teste, e dividia por `targetAmount` sem guarda: uma meta de alvo zero
/// produzia `NaN`, que atravessa o `clamp` (ele só limita números) e chega na
/// barra de progresso da tela de metas.

final _inicio = DateTime(2026, 1, 1);
final _prazo = DateTime(2026, 12, 31);

/// Metade do prazo: 181 dias de 364.
final _meioDoPrazo = DateTime(2026, 7, 1);

GoalModel _juntar({required double alvo, required double atual}) =>
    GoalModel.saveMoney(
      id: 'g1',
      name: 'Reserva',
      targetAmount: alvo,
      currentAmount: atual,
      deadline: _prazo,
      accountId: 'acc-1',
      startDate: _inicio,
    );

GoalModel _quitar({required double alvo, required double atual}) =>
    GoalModel.payDebt(
      id: 'g2',
      name: 'Empréstimo',
      targetAmount: alvo,
      currentAmount: atual,
      deadline: _prazo,
      accountId: 'acc-2',
      startDate: _inicio,
    );

GoalModel _reduzir({required double teto, required double gasto}) =>
    GoalModel.reduceExpense(
      id: 'g3',
      name: 'Delivery',
      targetAmount: teto,
      currentAmount: gasto,
      deadline: _prazo,
      category: const CategoryModel(
        id: 'delivery',
        name: 'Delivery',
        icon: 'restaurant',
        color: '#FF0000',
      ),
      startDate: _inicio,
    );

void main() {
  group('divisão por alvo zero', () {
    test('meta de acúmulo com alvo zero não produz NaN', () {
      final progresso = _juntar(alvo: 0, atual: 0).calculateProgress(
        now: _meioDoPrazo,
      );

      expect(progresso.percent.isNaN, isFalse);
      // Sem alvo não há o que alcançar: a meta está cumprida.
      expect(progresso.percent, 1.0);
      expect(progresso.status, GoalStatus.onTrack);
    });

    test('alvo zero com dinheiro guardado também não estoura', () {
      // `100 / 0` é infinito, e o `clamp` do infinito devolve 1.0 — mas a
      // conta não deveria acontecer.
      final progresso = _juntar(alvo: 0, atual: 100).calculateProgress(
        now: _meioDoPrazo,
      );

      expect(progresso.percent, 1.0);
      expect(progresso.percent.isFinite, isTrue);
    });

    test('meta de redução com teto zero: gastar nada é zero por cento', () {
      final progresso = _reduzir(teto: 0, gasto: 0).calculateProgress(
        now: _meioDoPrazo,
      );

      expect(progresso.percent.isNaN, isFalse);
      expect(progresso.percent, 0.0);
      expect(progresso.status, GoalStatus.onTrack);
    });

    test('meta de redução com teto zero: qualquer gasto já estourou', () {
      final progresso = _reduzir(teto: 0, gasto: 0.01).calculateProgress(
        now: _meioDoPrazo,
      );

      expect(progresso.percent, 1.0);
      expect(progresso.status, GoalStatus.lost);
      expect(progresso.isLost, isTrue);
    });

    test('alvo NEGATIVO cai na mesma guarda', () {
      final progresso = _juntar(alvo: -100, atual: 50).calculateProgress(
        now: _meioDoPrazo,
      );

      expect(progresso.percent, 1.0);
      expect(progresso.percent.isNegative, isFalse);
    });
  });

  group('prazo sem duração', () {
    test('começo e fim no mesmo dia: o tempo já passou inteiro', () {
      final relampago = GoalModel.saveMoney(
        id: 'g4',
        name: 'Hoje',
        targetAmount: 100,
        currentAmount: 50,
        deadline: _inicio,
        accountId: 'acc-1',
        startDate: _inicio,
      );

      final progresso = relampago.calculateProgress(now: _inicio);

      expect(progresso.predictionPercent, 1.0);
      expect(progresso.percent, 0.5);
    });
  });

  group('a escada de status das metas de acúmulo', () {
    ({double percent, GoalStatus status}) emMetadeDoPrazo(double atual) {
      final progresso = _juntar(
        alvo: 1000,
        atual: atual,
      ).calculateProgress(now: _meioDoPrazo);
      return (percent: progresso.percent, status: progresso.status);
    }

    test('metade do prazo, metade do dinheiro: em dia', () {
      // `timePercent` é ~0.497 no dia 1/7; 50% do alvo está acima disso.
      expect(emMetadeDoPrazo(500).status, GoalStatus.onTrack);
    });

    test('acima de 80% do ritmo esperado, mas abaixo dele: em risco', () {
      // 45% do alvo com ~49,7% do prazo: passou de 0.8 * 0.497 e não chegou a
      // 0.497.
      expect(emMetadeDoPrazo(450).status, GoalStatus.atRisk);
    });

    test('abaixo de 80% do ritmo: atrasada', () {
      expect(emMetadeDoPrazo(300).status, GoalStatus.behind);
    });

    test('alcançou o alvo antes do prazo: em dia, e não "adiantada"', () {
      expect(emMetadeDoPrazo(1200).percent, 1.0);
      expect(emMetadeDoPrazo(1200).status, GoalStatus.onTrack);
    });

    test('abaixo de metade do ritmo NA RETA FINAL: perdida', () {
      // `isLost` só vale na última semana: antes disso ainda dá tempo.
      final quaseNoFim = _prazo.subtract(const Duration(days: 3));
      final progresso = _juntar(
        alvo: 1000,
        atual: 100,
      ).calculateProgress(now: quaseNoFim);

      expect(progresso.status, GoalStatus.lost);
      expect(progresso.isLost, isTrue);
    });

    test('o mesmo atraso no MEIO do prazo ainda não é perdida', () {
      final progresso = _juntar(
        alvo: 1000,
        atual: 100,
      ).calculateProgress(now: _meioDoPrazo);

      expect(progresso.isLost, isFalse);
      expect(progresso.status, GoalStatus.behind);
    });

    test('quitar dívida segue a mesma escada de juntar dinheiro', () {
      expect(
        _quitar(alvo: 1000, atual: 500).calculateProgress(now: _meioDoPrazo).status,
        GoalStatus.onTrack,
      );
    });
  });

  group('metas de redução: o alvo é um TETO', () {
    test('dentro do teto, em dia — independentemente do prazo', () {
      final progresso = _reduzir(teto: 500, gasto: 200).calculateProgress(
        now: _meioDoPrazo,
      );

      expect(progresso.percent, 0.4);
      expect(progresso.status, GoalStatus.onTrack);
    });

    test('acima de 90% do teto: em risco', () {
      final progresso = _reduzir(teto: 500, gasto: 460).calculateProgress(
        now: _meioDoPrazo,
      );

      expect(progresso.status, GoalStatus.atRisk);
    });

    test('passou do teto: perdida, e o percentual satura em 100%', () {
      final progresso = _reduzir(teto: 500, gasto: 900).calculateProgress(
        now: _meioDoPrazo,
      );

      expect(progresso.status, GoalStatus.lost);
      expect(progresso.isLost, isTrue);
      expect(progresso.percent, 1.0);
    });
  });
}
