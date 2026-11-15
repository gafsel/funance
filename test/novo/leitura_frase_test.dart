import 'package:flutter_test/flutter_test.dart';
import 'package:funances/novo/modelo/modelos.dart';
import 'package:funances/novo/regras/formatos.dart';
import 'package:funances/novo/regras/leitura_frase.dart';

void main() {
  const ctx = ContextoDeLeitura(
    hoje: '2026-11-14',
    contas: [
      Conta(id: 'cc', nome: 'Itaú', tipo: 'corrente'),
      Conta(id: 'nu', nome: 'Cartão Nubank', tipo: 'cartao'),
      Conta(id: 'poup', nome: 'Poupança', tipo: 'investimento'),
    ],
    categorias: [
      Categoria(id: 'mercado', nome: 'Mercado', tipo: 'saida'),
      Categoria(id: 'transporte', nome: 'Transporte', tipo: 'saida'),
      Categoria(id: 'salario', nome: 'Salário', tipo: 'entrada'),
    ],
    aprendido: {'uber': 'transporte'},
    contaPadraoId: 'cc',
  );

  Leitura ler(String s) => lerLinha(s, ctx)!;

  group('lerCentavos', () {
    test('formatos brasileiros', () {
      expect(lerCentavos('45'), 4500);
      expect(lerCentavos('45,9'), 4590);
      expect(lerCentavos('45.90'), 4590);
      expect(lerCentavos('1.234,56'), 123456);
      expect(lerCentavos('1.234'), 123400);
      expect(lerCentavos(r'R$ 12,00'), 1200);
      expect(lerCentavos('abc'), isNull);
      expect(lerCentavos('0'), isNull);
    });

    test('reais formata com milhar e sinal', () {
      expect(reais(123456), r'R$ 1.234,56');
      expect(reais(-5), r'-R$ 0,05');
      expect(reais(100000000), r'R$ 1.000.000,00');
    });
  });

  group('lerLinha', () {
    test('gasto simples: valor, descrição, conta padrão e hoje', () {
      final l = ler('mercado 45,90');
      expect(l.tipo, 'saida');
      expect(l.valorCentavos, 4590);
      expect(l.descricao, 'Mercado');
      expect(l.contaId, 'cc');
      expect(l.categoriaId, 'mercado');
      expect(l.data, '2026-11-14');
      expect(l.efetivado, isTrue);
      expect(l.completa, isTrue);
    });

    test('conta citada, ontem e categoria aprendida do histórico', () {
      final l = ler('uber 23 ontem no cartão nubank');
      expect(l.contaId, 'nu');
      expect(l.data, '2026-11-13');
      expect(l.categoriaId, 'transporte');
      expect(l.descricao, 'Uber');
    });

    test('"no cartão" resolve quando só existe um', () {
      expect(ler('farmácia 30 no cartão').contaId, 'nu');
    });

    test('parcelado: o número de vezes não vira valor', () {
      final l = ler('tv 1.200 em 10x nubank');
      expect(l.valorCentavos, 120000);
      expect(l.parcelas, 10);
      expect(l.descricao, 'Tv');
    });

    test('entrada e recorrência', () {
      final l = ler('recebi salário 5000 todo mês');
      expect(l.tipo, 'entrada');
      expect(l.categoriaId, 'salario');
      expect(l.recorrente, isTrue);
    });

    test('data dita: dia/mês, dia solto e futuro vira previsto', () {
      expect(ler('aluguel 2000 dia 5').data, '2026-11-05');
      expect(ler('dentista 300 20/12').data, '2026-12-20');
      expect(ler('dentista 300 20/12').efetivado, isFalse);
      expect(ler('luz 180 vence amanhã').efetivado, isFalse);
      expect(ler('ifood 20 31/02').data, '2026-02-28');
    });

    test('transferência: da conta padrão para a citada, ou entre duas citadas', () {
      final uma = ler('guardei 200 na poupança');
      expect(uma.tipo, 'transferencia');
      expect(uma.contaId, 'cc');
      expect(uma.contaDestinoId, 'poup');
      expect(uma.categoriaId, isNull);

      final duas = ler('transferi 500 da poupança para o itaú');
      expect(duas.contaId, 'poup');
      expect(duas.contaDestinoId, 'cc');
    });

    test('sem valor não há leitura', () {
      expect(lerLinha('comprei pão', ctx), isNull);
      expect(lerLinha('   ', ctx), isNull);
    });

    test('várias linhas, uma por lançamento', () {
      final r = lerTexto('pão 8\nsem valor aqui\ngasolina 150; café 12', ctx);
      expect(r.map((e) => e.$2?.valorCentavos), [800, null, 15000, 1200]);
    });
  });

  test('aprenderCategorias fica com a categoria mais usada por palavra', () {
    Lancamento l(String d, String c) => Lancamento(
        id: d + c, tipo: 'saida', descricao: d, data: '2026-01-01', situacao: 'efetivado', contaId: 'cc', categoriaId: c);
    final mapa = aprenderCategorias([l('Uber centro', 'transporte'), l('Uber', 'transporte'), l('Uber Eats', 'comida')]);
    expect(mapa['uber'], 'transporte');
    expect(mapa['eats'], 'comida');
  });
}
