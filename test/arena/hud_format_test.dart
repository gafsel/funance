import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/money/money.dart';
import 'package:funances/features/arena/domain/models/hud_state.dart';
import 'package:funances/features/arena/presentation/widgets/hud_format.dart';

/// Como a razão vira TEXTO.
///
/// Uma casa decimal responde "isto é grande?" e é o que a faixa precisa. O
/// problema é o que ela faz com o número pequeno: R$ 263,41 guardados sobre
/// R$ 18.550,00 de receita dão 0,0142, e `toStringAsFixed(1)` escreve isso
/// como "0,0". A faixa passava a dizer, ao lado de uma poção que TEM saldo,
/// que não há nada ali — e zero é uma afirmação, não um arredondamento.

HudRatio _razao(int numerador, int denominador) => HudRatio(
  amount: Money.fromCents(numerador),
  income: denominador == 0 ? null : Money.fromCents(denominador),
);

void main() {
  group('a razão em texto', () {
    test('o cofrinho de R\$ 263,41 não é zero: é "< 0,1"', () {
      // 26.341 / 1.855.000 = 0,0142 — o caso real do cofre do dono.
      expect(hudRatioValue(_razao(26341, 1855000), 'pt'), '< 0,1');
      expect(hudRatioValue(_razao(26341, 1855000), 'en'), '< 0.1');
    });

    test('zero de verdade continua "0,0"', () {
      // Aqui o numerador é zero MESMO, e o denominador existe: a poção está
      // vazia, e dizê-lo é correto.
      expect(hudRatioValue(_razao(0, 1855000), 'pt'), '0,0');
      expect(hudRatioValue(_razao(0, 1855000), 'en'), '0.0');
    });

    test('um centavo sobre a receita inteira ainda é "< 0,1"', () {
      expect(hudRatioValue(_razao(1, 1855000), 'pt'), '< 0,1');
    });

    test('a partir de 0,05 o arredondamento já mostra 0,1', () {
      // 92.750 / 1.855.000 = 0,05 exato, que arredonda para 0,1.
      expect(hudRatioValue(_razao(92750, 1855000), 'pt'), '0,1');
    });

    test('o ovo do cofre real: 1,1×', () {
      expect(hudRatioValue(_razao(2018780, 1855000), 'pt'), '1,1');
    });

    test('a gota do cofre real: 0,4×', () {
      expect(hudRatioValue(_razao(762368, 1855000), 'pt'), '0,4');
    });

    test('sem denominador não há texto nenhum', () {
      expect(hudRatioValue(_razao(26341, 0), 'pt'), isNull);
    });

    test('saldo negativo é piso zero, e não um "< 0,1" com sinal', () {
      final negativo = HudRatio(
        amount: Money.fromCents(-5000),
        income: Money.fromCents(1855000),
      );

      expect(hudRatioValue(negativo, 'pt'), '0,0');
    });
  });

  group('os cortes, em centavos inteiros', () {
    test('meio mês exato JÁ é semi — a faixa é fechada à esquerda', () {
      expect(_razao(927500, 1855000).tier, HudTier.semi);
      expect(_razao(927499, 1855000).tier, HudTier.none);
    });

    test('a casca do ovo muda nos mesmos cortes, e sem passar por double', () {
      // 0,5 × 1.855.000 é exato em int e aproximado em ponto flutuante: a
      // casca não pode depender de qual dos dois o Dart escolheu.
      expect(
        HudEgg(invoices: const [], ratio: _razao(927500, 1855000)).stage,
        1,
      );
      expect(
        HudEgg(invoices: const [], ratio: _razao(927499, 1855000)).stage,
        0,
      );
      expect(
        HudEgg(invoices: const [], ratio: _razao(1855000, 1855000)).stage,
        2,
      );
      expect(
        HudEgg(invoices: const [], ratio: _razao(1854999, 1855000)).stage,
        1,
      );
    });

    test('o tremor começa em quatro quintos da receita, exato', () {
      // 0,8 × 1.855.000 = 1.484.000.
      expect(
        HudEgg(invoices: const [], ratio: _razao(1484000, 1855000)).isTrembling,
        isTrue,
      );
      expect(
        HudEgg(invoices: const [], ratio: _razao(1483999, 1855000)).isTrembling,
        isFalse,
      );
    });

    test('sem denominador o ovo é liso e quieto', () {
      final semRenda = HudEgg(invoices: const [], ratio: _razao(2018780, 0));

      expect(semRenda.stage, 0);
      expect(semRenda.isTrembling, isFalse);
    });
  });
}
