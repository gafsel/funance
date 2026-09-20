import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:intl/date_symbol_data_local.dart';

/// O dinheiro do JOGO — item 13 das decisões do dono.
///
/// "ao invés de R$ 12.122,33 ficaria apenas R$ 12,1k". O que este teste
/// guarda é cada uma das regras que essa frase implica e que um formatador
/// ingênuo erra: onde a faixa vira `k`, onde ela vira `M`, quando a casa
/// decimal some, o que acontece com os centavos e como um negativo se
/// escreve.
///
/// O espaço entre o símbolo e o número é NÃO SEPARÁVEL (U+00A0) — é o que o
/// `intl` produz em português. As asserções usam ` ` de propósito: um
/// teste escrito com o espaço comum falha por um caractere invisível, e a
/// mensagem de falha mostra duas strings idênticas.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt');
    await initializeDateFormatting('en');
  });

  group('português', () {
    test('o número do dono: R\$ 12.122,33 vira R\$ 12,1k', () {
      expect(12122.33.asCompactCurrency(locale: 'pt'), 'R\$\u00A012,1k');
    });

    test('abaixo de mil, o inteiro — e os centavos somem', () {
      expect(980.asCompactCurrency(locale: 'pt'), 'R\$\u00A0980');
      expect(980.49.asCompactCurrency(locale: 'pt'), 'R\$\u00A0980');
      expect(0.asCompactCurrency(locale: 'pt'), 'R\$\u00A00');
    });

    test('milhão vira M', () {
      expect(1200000.asCompactCurrency(locale: 'pt'), 'R\$\u00A01,2M');
      expect(12122330.asCompactCurrency(locale: 'pt'), 'R\$\u00A012,1M');
    });

    test('a casa decimal cai quando é zero', () {
      // "R$ 12,0k" gasta dois caracteres para dizer que não há nada depois da
      // vírgula. A casa existe para separar 12,1 de 12,9.
      expect(12000.asCompactCurrency(locale: 'pt'), 'R\$\u00A012k');
      expect(2000000.asCompactCurrency(locale: 'pt'), 'R\$\u00A02M');
    });

    test('negativo leva o menos tipográfico', () {
      expect(
        (-12122.33).asCompactCurrency(locale: 'pt'),
        '\u2212R\$\u00A012,1k',
        reason: 'é o mesmo "−" que a cena usa nos números que descem',
      );
      expect((-980).asCompactCurrency(locale: 'pt'), '\u2212R\$\u00A0980');
    });

    test('o que ARREDONDA para zero não leva sinal', () {
      // "−R$ 0" afirma uma perda de nada. Zero é neutro, como em
      // `asSignedCurrency`.
      expect((-0.4).asCompactCurrency(locale: 'pt'), 'R\$\u00A00');
      expect((-0.0).asCompactCurrency(locale: 'pt'), 'R\$\u00A00');
    });
  });

  group('a faixa é escolhida sobre o valor arredondado', () {
    test('R\$ 999.999 é R\$ 1M, e não R\$ 1.000,0k', () {
      expect(999999.asCompactCurrency(locale: 'pt'), 'R\$\u00A01M');
    });

    test('R\$ 999,60 é R\$ 1k, e não R\$ 1.000', () {
      expect(999.6.asCompactCurrency(locale: 'pt'), 'R\$\u00A01k');
    });

    test('mas R\$ 999,40 continua inteiro', () {
      expect(999.4.asCompactCurrency(locale: 'pt'), 'R\$\u00A0999');
    });

    test('e a borda de baixo de cada faixa é a própria faixa', () {
      expect(1000.asCompactCurrency(locale: 'pt'), 'R\$\u00A01k');
      expect(1000000.asCompactCurrency(locale: 'pt'), 'R\$\u00A01M');
    });
  });

  group('inglês', () {
    test('ponto decimal, símbolo colado, mesmos sufixos', () {
      expect(12122.33.asCompactCurrency(locale: 'en'), r'$12.1k');
      expect(980.asCompactCurrency(locale: 'en'), r'$980');
      expect(1200000.asCompactCurrency(locale: 'en'), r'$1.2M');
      expect((-12122.33).asCompactCurrency(locale: 'en'), '−\$12.1k');
    });
  });

  group('sem o símbolo', () {
    test('é o MESMO número, só sem o "R\$"', () {
      // Para quem já diz "R\$" num rótulo ao lado — eixo de gráfico,
      // cabeçalho de coluna. Existir como parâmetro, e não como um segundo
      // formatador, é o que impede as duas formas de divergirem.
      expect(12122.33.asCompactCurrency(locale: 'pt', symbol: false), '12,1k');
      expect(980.asCompactCurrency(locale: 'pt', symbol: false), '980');
      expect(12000.asCompactCurrency(locale: 'pt', symbol: false), '12k');
      expect(
        (-1200000).asCompactCurrency(locale: 'pt', symbol: false),
        '\u22121,2M',
      );
      expect(12122.33.asCompactCurrency(locale: 'en', symbol: false), '12.1k');
    });
  });

  test('o detalhe continua exato', () {
    // A regra de produto inteira: o compacto é do relance, o exato é de quem
    // tocou para ver o que compõe o número.
    expect(12122.33.asCurrency(locale: 'pt'), 'R\$\u00A012.122,33');
  });
}
