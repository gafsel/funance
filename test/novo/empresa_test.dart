import 'package:flutter_test/flutter_test.dart';
import 'package:funances/novo/modelo/modelos.dart';
import 'package:funances/novo/regras/empresa.dart';

void main() {
  const hoje = '2026-11-14';
  Lancamento p(String id, String tipo, int valor, String data, {String conta = 'cc', String? destino, String descricao = ''}) => Lancamento(
      id: id, tipo: tipo, descricao: descricao, data: data, situacao: 'previsto', previstoCentavos: valor, contaId: conta, contaDestinoId: destino);

  test('faixas de prazo', () {
    expect(prazoDe('2026-11-13', hoje), Prazo.vencido);
    expect(prazoDe('2026-11-14', hoje), Prazo.seteDias);
    expect(prazoDe('2026-11-21', hoje), Prazo.seteDias);
    expect(prazoDe('2026-11-22', hoje), Prazo.trintaDias);
    expect(prazoDe('2026-12-15', hoje), Prazo.depois);
  });

  test('a receber e a pagar por prazo, sem misturar os lados', () {
    final itens = [
      p('a', 'entrada', 1000, '2026-11-01'),
      p('b', 'entrada', 2000, '2026-11-20'),
      p('c', 'saida', 500, '2026-11-18'),
      p('d', 'saida', 700, '2027-01-10'),
      p('t', 'transferencia', 9999, '2026-11-18', destino: 'x'),
    ];
    expect(porPrazo(itens, hoje, aReceber: true), {Prazo.vencido: 1000, Prazo.seteDias: 2000, Prazo.trintaDias: 0, Prazo.depois: 0});
    expect(porPrazo(itens, hoje, aReceber: false), {Prazo.vencido: 0, Prazo.seteDias: 500, Prazo.trintaDias: 0, Prazo.depois: 700});
  });

  test('caixa previsto: recebível vencido não entra; conta vencida entra hoje; acha o ponto mais baixo', () {
    final c = preverCaixa(
      hoje: hoje,
      caixaHojeCentavos: 10000,
      contasDeUso: {'cc'},
      previstos: [
        p('rec-vencido', 'entrada', 50000, '2026-11-01'),
        p('pag-vencida', 'saida', 4000, '2026-11-10'),
        p('folha', 'saida', 9000, '2026-11-20'),
        p('cliente', 'entrada', 20000, '2026-11-25'),
        p('longe', 'saida', 99999, '2027-02-01'),
        p('outra-conta', 'saida', 77777, '2026-11-20', conta: 'cartao'),
        p('aplicar', 'transferencia', 1000, '2026-11-26', destino: 'invest'),
      ],
    );
    expect(c.aReceberVencidoCentavos, 50000);
    expect(c.minimoCentavos, 10000 - 4000 - 9000);
    expect(c.diaDoMinimo, '2026-11-20');
    expect(c.finalCentavos, 10000 - 4000 - 9000 + 20000 - 1000);
  });

  test('resultado por centro de custo, com o pró-labore à parte', () {
    const resumo = ResumoMes(mes: '2026-11', deltaPorConta: {}, categorias: {
      'vendas': (900000, 1000000),
      'fornecedores': (300000, 350000),
      'marketing': (50000, 20000),
      'pl': (200000, 200000),
      'vazia': (0, 0),
    });
    final r = resultadoDoMes(resumo, const {
      'vendas': Categoria(id: 'vendas', nome: 'Vendas', tipo: 'entrada'),
      'fornecedores': Categoria(id: 'fornecedores', nome: 'Fornecedores', tipo: 'saida'),
      'marketing': Categoria(id: 'marketing', nome: 'Marketing', tipo: 'saida'),
      'pl': Categoria(id: 'pl', nome: 'Pró-labore', tipo: 'saida'),
    }, {'pl'});
    expect(r.receitaCentavos, 1000000);
    expect(r.despesas.map((d) => d.$1), ['fornecedores', 'marketing']);
    expect(r.antesDoProLaboreCentavos, 630000);
    expect(r.depoisDoProLaboreCentavos, 430000);
    expect(resultadoDoMes(null, const {}, const {}).antesDoProLaboreCentavos, 0);
  });

  test('mensagem de cobrança: um item e vários', () {
    final uma = mensagemDeCobranca('Acme', [p('a', 'entrada', 150000, '2026-11-03', descricao: 'Projeto site')], hoje);
    expect(uma, contains('Olá, Acme.'));
    expect(uma, contains(r'"Projeto site" de R$ 1.500,00, com vencimento em 03/11'));
    final varias = mensagemDeCobranca('Acme', [
      p('b', 'entrada', 20000, '2026-11-10', descricao: 'Suporte'),
      p('a', 'entrada', 150000, '2026-11-03', descricao: 'Projeto site'),
    ], hoje);
    expect(varias, contains(r'2 valores, no total de R$ 1.700,00'));
    expect(varias.indexOf('Projeto site'), lessThan(varias.indexOf('Suporte')));
  });
}
