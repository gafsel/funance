import 'package:flutter_test/flutter_test.dart';
import 'package:funances/novo/modelo/modelos.dart';
import 'package:funances/novo/regras/conferencia.dart';
import 'package:funances/novo/regras/faturas.dart';
import 'package:funances/novo/regras/importar.dart';

Conta conta(String id, String tipo, {String? banco, List<String> donos = const ['eu'], String? conferidoAte}) =>
    Conta(id: id, nome: id, tipo: tipo, banco: banco, donos: donos, conferidoAte: conferidoAte);

Lancamento compra(String id, int centavos, String dia, {String descricao = '', int? parcela, bool estorno = false}) => Lancamento(
      id: id,
      tipo: estorno ? 'entrada' : 'saida',
      descricao: descricao.isEmpty ? id : descricao,
      realizadoCentavos: centavos,
      data: dia,
      dataEfetiva: dia,
      situacao: 'efetivado',
      contaId: 'cartao',
      parcelaNumero: parcela,
      parcelaTotal: parcela == null ? null : 10,
    );

ItemImportado banco(String descricao, int centavos, String dia, {bool estorno = false}) =>
    ItemImportado(id: descricao, descricao: descricao, valorCentavos: centavos, data: dia, tipo: estorno ? 'entrada' : 'saida');

void main() {
  test('roteiro: as minhas primeiro, por banco, e o cartão antes da conta', () {
    final ordem = roteiroDaConferencia([
      conta('conta itau', 'corrente', banco: 'itau', donos: ['eu', 'ela']),
      conta('conta nubank dela', 'corrente', banco: 'nubank', donos: ['ela']),
      conta('cartao nubank dela', 'cartao', banco: 'nubank', donos: ['ela']),
      conta('conta nubank', 'corrente', banco: 'nubank'),
      conta('cartao nubank', 'cartao', banco: 'nubank'),
      conta('cartao inter', 'cartao', banco: 'inter'),
      conta('divida', 'divida', banco: 'inter'),
      Conta(id: 'velha', nome: 'velha', tipo: 'corrente', arquivada: true, donos: const ['eu']),
    ], 'eu');
    expect(ordem.map((c) => c.id), [
      'cartao inter', 'cartao nubank', 'conta nubank', 'conta itau', 'cartao nubank dela', 'conta nubank dela',
    ]);
  });

  group('faturas para conferir', () {
    Fatura fatura(String id, String vence, String fecha, {int total = 10000, int pago = 0}) =>
        Fatura(id: id, contaId: 'cartao', vencimento: vence, fechamento: fecha, inicio: fecha, fim: fecha, totalCentavos: total, pagoCentavos: pago);
    const hoje = '2026-11-16';
    final dezembro = fatura('dez', '2026-12-10', '2026-12-05');

    test('fechada e sem pagamento: confere ela e a aberta', () {
      final s = situacoesDasFaturas([dezembro, fatura('nov', '2026-11-20', '2026-11-13')], hoje);
      expect(faturasParaConferir(s, 'cartao').map((x) => x.fatura.id), ['nov', 'dez']);
    });

    test('depois de paga, só a aberta', () {
      final s = situacoesDasFaturas([dezembro, fatura('nov', '2026-11-20', '2026-11-13', pago: 10000)], hoje);
      expect(faturasParaConferir(s, 'cartao').map((x) => x.fatura.id), ['dez']);
    });

    test('duas fechadas sem pagamento entram as duas, da mais antiga para a mais nova', () {
      final s = situacoesDasFaturas([dezembro, fatura('nov', '2026-11-10', '2026-11-05'), fatura('out', '2026-10-10', '2026-10-05')], hoje);
      expect(faturasParaConferir(s, 'cartao').map((x) => x.fatura.id), ['out', 'nov', 'dez']);
    });

    test('sem fatura nenhuma, nada a conferir', () {
      expect(faturasParaConferir(situacoesDasFaturas(const [], hoje), 'cartao'), isEmpty);
    });
  });

  test('dias sem conferir', () {
    expect(diasSemConferir(Passo(conta('a', 'corrente', conferidoAte: '2026-11-09')), '2026-11-16'), 7);
    expect(diasSemConferir(Passo(conta('a', 'corrente')), '2026-11-16'), isNull);
  });

  test('cada fatura é um passo, com a sua própria data de conferência', () {
    const cartao = Conta(
      id: 'cartao', nome: 'Cartão', tipo: 'cartao', donos: ['eu'], conferidoAte: '2026-11-14',
      faturasConferidasEm: {'nov': '2026-11-14'},
    );
    final situacoes = situacoesDasFaturas(const [
      Fatura(id: 'nov', contaId: 'cartao', vencimento: '2026-11-20', fechamento: '2026-11-13', inicio: '', fim: '', totalCentavos: 10000),
      Fatura(id: 'dez', contaId: 'cartao', vencimento: '2026-12-20', fechamento: '2026-12-13', inicio: '', fim: '', totalCentavos: 5000),
    ], '2026-11-16');
    final passos = passosDaConferencia([cartao, conta('conta', 'corrente')], 'eu', situacoes);
    expect(passos.map((p) => p.id), ['cartao/nov', 'cartao/dez', 'conta']);
    expect(passos[0].conferidoAte, '2026-11-14');
    expect(diasSemConferir(passos[0], '2026-11-16'), 2);
    // A fatura aberta nunca foi conferida, mesmo o cartão tendo uma data.
    expect(passos[1].conferidoAte, isNull);
  });

  test('cartão sem fatura a conferir ainda é um passo', () {
    final passos = passosDaConferencia([conta('cartao', 'cartao')], 'eu', const {});
    expect(passos.single.fatura, isNull);
    expect(passos.single.id, 'cartao');
  });

  test('saldo no fim de cada dia, andando para trás a partir de hoje', () {
    final saldos = saldosNoFimDeCadaDia(
      saldoHoje: 100000,
      hoje: '2026-11-16',
      desde: '2026-11-13',
      movimentoPorDia: {'2026-11-16': -5000, '2026-11-14': 20000},
    );
    expect(saldos, {'2026-11-16': 100000, '2026-11-15': 105000, '2026-11-14': 105000, '2026-11-13': 85000});
  });

  test('busca da diferença: pergunta o dia do meio até os dois ficarem vizinhos', () {
    expect(diaDoMeio('2026-11-01', '2026-11-16'), '2026-11-08');
    expect(diaDoMeio('2026-11-08', '2026-11-16'), '2026-11-12');
    expect(diaDoMeio('2026-11-12', '2026-11-14'), '2026-11-13');
    expect(diaDoMeio('2026-11-13', '2026-11-14'), isNull);
  });

  group('comparar fatura item a item', () {
    test('tudo igual: bate', () {
      final c = compararFatura(
        [compra('mercado', 38450, '2026-11-08'), compra('uber', 2390, '2026-11-14')],
        [banco('UBER TRIP', 2390, '2026-11-15'), banco('MERCADO BOM', 38450, '2026-11-08')],
      );
      expect(c.bate, isTrue);
      expect(c.iguais, hasLength(2));
    });

    test('centavos de parcela aparecem como valor diferente, mesmo com datas distantes', () {
      final c = compararFatura(
        [compra('tenis', 13333, '2026-11-20', descricao: 'Tênis 3/10', parcela: 3)],
        [banco('LOJA TENIS 03/10', 13334, '2026-09-20')],
      );
      expect(c.bate, isFalse);
      expect(c.valorDiferente.single.$1.id, 'tenis');
      expect(c.valorDiferente.single.$2.valorCentavos, 13334);
      expect(c.soNoBanco, isEmpty);
      expect(c.soNoApp, isEmpty);
    });

    test('o que falta de um lado ou de outro fica separado', () {
      final c = compararFatura(
        [compra('mercado', 38450, '2026-11-08'), compra('lancado a mais', 9900, '2026-11-10')],
        [banco('MERCADO', 38450, '2026-11-08'), banco('FARMACIA', 4720, '2026-11-12')],
      );
      expect(c.soNoApp.single.id, 'lancado a mais');
      expect(c.soNoBanco.single.descricao, 'FARMACIA');
    });

    test('duas compras de mesmo valor casam uma com cada', () {
      final c = compararFatura(
        [compra('uber ida', 2390, '2026-11-10'), compra('uber volta', 2390, '2026-11-11')],
        [banco('UBER', 2390, '2026-11-10'), banco('UBER', 2390, '2026-11-11')],
      );
      expect(c.bate, isTrue);
    });

    test('compra à vista com data muito distante não é a mesma', () {
      final c = compararFatura([compra('padaria', 1850, '2026-11-02')], [banco('PADARIA', 1850, '2026-11-20')]);
      expect(c.iguais, isEmpty);
      expect(c.soNoApp, hasLength(1));
      expect(c.soNoBanco, hasLength(1));
    });

    test('estorno só casa com estorno', () {
      final c = compararFatura(
        [compra('loja', 5000, '2026-11-10')],
        [banco('ESTORNO LOJA', 5000, '2026-11-11', estorno: true)],
      );
      expect(c.iguais, isEmpty);
      expect(c.valorDiferente, isEmpty);
    });
  });
}
