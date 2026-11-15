import 'package:flutter_test/flutter_test.dart';
import 'package:funances/novo/modelo/modelos.dart';
import 'package:funances/novo/regras/importar.dart';

void main() {
  const hoje = '2026-11-14';
  ResultadoDaImportacao ler(String t) => lerExtrato(t, contaId: 'cc', hoje: hoje);

  group('OFX', () {
    const ofx = '''
OFXHEADER:100
<OFX><BANKMSGSRSV1><STMTTRNRS><STMTRS><BANKTRANLIST>
<STMTTRN><TRNTYPE>DEBIT<DTPOSTED>20261103120000[-3:BRT]<TRNAMT>-45.90<FITID>abc/123<MEMO>MERCADO BOM PRECO</STMTTRN>
<STMTTRN>
<TRNTYPE>CREDIT
<DTPOSTED>20261105
<TRNAMT>5000,00
<FITID>xyz
<NAME>SALARIO EMPRESA
</STMTTRN>
<STMTTRN><DTPOSTED>2026<TRNAMT>-1.00</STMTTRN>
</BANKTRANLIST></STMTRS></STMTTRNRS></BANKMSGSRSV1></OFX>''';

    test('lê lançamentos com e sem fechamento de tag, e ignora o quebrado', () {
      final r = ler(ofx);
      expect(r.formato, 'OFX');
      expect(r.ignoradas, 1);
      expect(r.itens, hasLength(2));
      expect(r.itens[0].data, '2026-11-03');
      expect(r.itens[0].valorCentavos, 4590);
      expect(r.itens[0].tipo, 'saida');
      expect(r.itens[0].descricao, 'MERCADO BOM PRECO');
      expect(r.itens[0].id, 'imp-cc-abc123');
      expect(r.itens[1].tipo, 'entrada');
      expect(r.itens[1].valorCentavos, 500000);
    });
  });

  group('planilha', () {
    test('CSV com ponto e vírgula, cabeçalho e coluna de saldo', () {
      final r = ler('Data;Histórico;Valor;Saldo\n03/11/2026;PIX ENVIADO JOAO;-150,00;1.200,00\n04/11/2026;"TED; RECEBIDA";2.000,00;3.200,00\nTotal;;;');
      expect(r.itens.map((i) => (i.data, i.tipo, i.valorCentavos, i.descricao)), [
        ('2026-11-03', 'saida', 15000, 'PIX ENVIADO JOAO'),
        ('2026-11-04', 'entrada', 200000, 'TED; RECEBIDA'),
      ]);
      expect(r.ignoradas, 2);
    });

    test('colunas separadas de débito e crédito', () {
      final r = ler('data,descricao,debito,credito\n2026-11-03,Padaria,"18,50",\n2026-11-04,Reembolso,,"30,00"');
      expect(r.itens.map((i) => (i.tipo, i.valorCentavos)), [('saida', 1850), ('entrada', 3000)]);
    });

    test('células coladas de planilha (tabulação), sem cabeçalho e sem ano', () {
      final r = ler('03/11\tUber\t-23,90\n03/11\tUber\t-23,90');
      expect(r.itens, hasLength(2));
      expect(r.itens.first.data, '2026-11-03');
      // Duas corridas iguais no mesmo dia são dois itens diferentes…
      expect(r.itens[0].id, isNot(r.itens[1].id));
      // …mas reimportar o mesmo arquivo dá os mesmos ids.
      expect(ler('03/11\tUber\t-23,90\n03/11\tUber\t-23,90').itens.map((i) => i.id), r.itens.map((i) => i.id));
    });

    test('valor entre parênteses e com sinal no fim é negativo', () {
      final r = ler('03/11/2026;Tarifa;(12,00)\n04/11/2026;IOF;3,10-');
      expect(r.itens.map((i) => (i.tipo, i.valorCentavos)), [('saida', 1200), ('saida', 310)]);
    });
  });

  test('sugerirCategoria: regra mais específica ganha do histórico', () {
    const categorias = [
      Categoria(id: 'transporte', nome: 'Transporte', tipo: 'saida'),
      Categoria(id: 'comida', nome: 'Comida', tipo: 'saida'),
      Categoria(id: 'salario', nome: 'Salário', tipo: 'entrada'),
    ];
    String? s(String d, [String tipo = 'saida']) => sugerirCategoria(d, tipo, categorias: categorias, aprendido: const {
          'uber': 'transporte',
        }, regras: const [
          Regra(id: '1', texto: 'uber', categoriaId: 'transporte'),
          Regra(id: '2', texto: 'Uber Eats', categoriaId: 'comida'),
          Regra(id: '3', texto: 'pix', categoriaId: 'salario'),
        ]);
    expect(s('UBER *EATS PENDING'), 'comida');
    expect(s('UBER TRIP'), 'transporte');
    expect(s('PIX ENVIADO'), isNull, reason: 'categoria de entrada não serve para saída');
    expect(s('PIX RECEBIDO', 'entrada'), 'salario');
    expect(s('LOJA X'), isNull);
  });

  test('acharCorrespondente: mesmo valor, mesma conta, até três dias', () {
    Lancamento l(String id, int v, String dia, {String conta = 'cc', String tipo = 'saida', bool pago = true}) => Lancamento(
        id: id, tipo: tipo, descricao: '', data: dia, dataEfetiva: pago ? dia : null, situacao: pago ? 'efetivado' : 'previsto',
        realizadoCentavos: pago ? v : null, previstoCentavos: pago ? null : v, contaId: conta);
    const item = ItemEntrada(id: 'i', descricao: 'LUZ', valorCentavos: 18900, data: '2026-11-10', tipo: 'saida', contaId: 'cc');
    final candidatos = [
      l('longe', 18900, '2026-11-20'),
      l('outraConta', 18900, '2026-11-10', conta: 'x'),
      l('agendado', 18900, '2026-11-12', pago: false),
      l('entrada', 18900, '2026-11-10', tipo: 'entrada'),
      l('outroValor', 18901, '2026-11-10'),
    ];
    expect(acharCorrespondente(item, candidatos)?.id, 'agendado');
    expect(acharCorrespondente(item, candidatos, usados: {'agendado'}), isNull);
  });
}
