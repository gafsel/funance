import 'package:flutter_test/flutter_test.dart';
import 'package:funances/novo/modelo/modelos.dart';
import 'package:funances/novo/regras/caminho.dart';
import 'package:funances/novo/regras/metas.dart';

void main() {
  const hoje = '2026-11-14';
  const corrente = Conta(id: 'cc', nome: 'Corrente', tipo: 'corrente');
  const reserva = Conta(id: 'res', nome: 'Reserva', tipo: 'investimento');
  const divida = Conta(id: 'div', nome: 'Empréstimo', tipo: 'divida');

  Lancamento l(int i, String tipo) => Lancamento(
      id: '$tipo$i', tipo: tipo, descricao: '', data: '2026-11-05', dataEfetiva: '2026-11-05', situacao: 'efetivado', realizadoCentavos: 1000, contaId: 'cc');

  ResumoMes mes(String m, int entradas, int saidas, {Map<String, int> contas = const {}, Map<String, (int, int)> categorias = const {}}) =>
      ResumoMes(mes: m, deltaPorConta: contas, categorias: categorias, entradasCentavos: entradas, saidasCentavos: saidas);

  DadosDoCaminho dados({
    List<Conta> contas = const [corrente, reserva],
    Map<String, int> saldos = const {},
    List<ResumoMes> resumos = const [],
    List<Fatura> faturas = const [],
    List<Meta> metas = const [],
    List<Fechamento> fechamentos = const [],
    List<Lancamento> doMes = const [],
    bool empresa = false,
    Set<String> proLabore = const {},
    int previsto = 0,
  }) =>
      DadosDoCaminho(
        hoje: hoje, ehEmpresa: empresa, contas: contas, saldos: saldos, resumos: resumos, faturas: faturas, metas: metas,
        fechamentos: fechamentos, lancamentosDoMes: doMes, categoriaProLaboreIds: proLabore, previstoProximos30Centavos: previsto);

  group('caminho pessoal', () {
    test('quem acabou de chegar está no primeiro degrau, com um passo concreto', () {
      final caminho = calcularCaminho(dados());
      expect(caminho.map((g) => g.id), ['enxergar', 'sobrar', 'divida', 'reserva', 'metas']);
      final atual = degrauAtual(caminho)!;
      expect(atual.id, 'enxergar');
      expect(atual.proximoPasso, contains('recebeu'));
    });

    test('enxergar: renda e dez gastos no mês, ou um mês fechado', () {
      final comLancamentos = calcularCaminho(dados(doMes: [l(0, 'entrada'), for (var i = 0; i < 10; i++) l(i, 'saida')]));
      expect(comLancamentos.first.feito, isTrue);
      final comFechamento = calcularCaminho(dados(fechamentos: const [Fechamento(mes: '2026-10', situacao: 'fechado')]));
      expect(comFechamento.first.feito, isTrue);
    });

    test('sobrar olha o último mês completo', () {
      expect(calcularCaminho(dados(resumos: [mes('2026-10', 500000, 450000)]))[1].feito, isTrue);
      final faltou = calcularCaminho(dados(resumos: [mes('2026-10', 400000, 450000), mes('2026-11', 900000, 1)]))[1];
      expect(faltou.feito, isFalse);
      expect(faltou.situacao, contains(r'faltaram R$ 500,00'));
    });

    test('dívida cara: dívida em aberto ou fatura atrasada seguram o degrau', () {
      final comDivida = calcularCaminho(dados(contas: const [corrente, divida], saldos: const {'div': -800000}))[2];
      expect(comDivida.feito, isFalse);
      expect(comDivida.situacao, contains(r'R$ 8.000,00'));
      final comFatura = calcularCaminho(dados(faturas: const [
        Fatura(id: 'f', contaId: 'x', vencimento: '2026-11-10', fechamento: '2026-11-05', inicio: '2026-10-05', fim: '2026-11-04', totalCentavos: 100),
      ]))[2];
      expect(comFatura.feito, isFalse);
      expect(comFatura.proximoPasso, contains('fatura atrasada'));
      expect(calcularCaminho(dados())[2].feito, isTrue);
    });

    test('reserva: três meses da média de gastos, com progresso', () {
      final resumos = [mes('2026-08', 1, 300000), mes('2026-09', 1, 300000), mes('2026-10', 1, 300000)];
      final metade = calcularCaminho(dados(resumos: resumos, saldos: const {'res': 450000}))[3];
      expect(metade.feito, isFalse);
      expect(metade.fracao, 0.5);
      expect(calcularCaminho(dados(resumos: resumos, saldos: const {'res': 900000}))[3].feito, isTrue);
    });
  });

  test('caminho da empresa tem os próprios degraus', () {
    final tres = [mes('2026-08', 100, 50, categorias: {'pl': (0, 10)}), mes('2026-09', 100, 50, categorias: {'pl': (0, 10)}), mes('2026-10', 100, 50, categorias: {'pl': (0, 10)})];
    final caminho = calcularCaminho(dados(empresa: true, contas: const [corrente], saldos: const {'cc': 60}, resumos: tres, proLabore: {'pl'}));
    expect(caminho.map((g) => g.id), ['separar', 'previsivel', 'giro', 'prolabore', 'lucro']);
    expect(caminho[2].feito, isTrue, reason: 'caixa cobre um mês de despesas');
    expect(caminho[3].feito, isTrue);
    expect(caminho[4].feito, isTrue);
    expect(degrauAtual(caminho)!.id, 'separar');
  });

  group('metas', () {
    const meta = Meta(id: 'm', nome: 'Reserva', tipo: 'juntar', alvoCentavos: 1200000, inicio: '2026-01-01', prazo: '2027-05-10', contaId: 'res', parcelaMensalCentavos: 100000);

    test('juntar ligada a investimento: o progresso é o saldo real da conta', () {
      final p = progressoDaMeta(meta, hoje: hoje, contas: const {'res': reserva}, saldos: const {'res': 600000}, resumos: const []);
      expect(p.atualCentavos, 600000);
      expect(p.fracao, 0.5);
      expect(p.mesesRestantes, 6);
      expect(p.parcelaNecessariaCentavos, 100000);
      expect(situacaoDaMeta(meta, p, hoje), contains('No ritmo'));
    });

    test('saldo alto não é cortado (na web, deslocamento de bits tem 32 bits)', () {
      final p = progressoDaMeta(meta, hoje: hoje, contas: const {'res': reserva}, saldos: const {'res': 900000000}, resumos: const []);
      expect(p.atualCentavos, 900000000);
    });

    test('parcela insuficiente é dita com o valor que resolveria', () {
      final p = progressoDaMeta(meta, hoje: hoje, contas: const {'res': reserva}, saldos: const {'res': 0}, resumos: const []);
      expect(p.parcelaNecessariaCentavos, 200000);
      expect(situacaoDaMeta(meta, p, hoje), contains(r'seriam R$ 2.000,00'));
    });

    test('reduzir gasto: o alvo é um teto', () {
      const teto = Meta(id: 't', nome: 'Menos delivery', tipo: 'reduzirGasto', alvoCentavos: 50000, inicio: '2026-10-01', prazo: '2026-11-30', categoriaId: 'del');
      final p = progressoDaMeta(teto, hoje: hoje, contas: const {}, saldos: const {}, resumos: [
        mes('2026-10', 0, 0, categorias: {'del': (0, 30000)}),
        mes('2026-11', 0, 0, categorias: {'del': (0, 30000)}),
      ]);
      expect(p.atualCentavos, 60000);
      expect(p.atingida, isFalse);
      expect(situacaoDaMeta(teto, p, hoje), contains(r'Passou do teto em R$ 100,00'));
    });

    test('mesesAte conta o mês corrente e zera depois do prazo', () {
      expect(mesesAte('2026-11-14', '2026-11-30'), 1);
      expect(mesesAte('2026-11-14', '2027-02-01'), 3);
      expect(mesesAte('2026-11-14', '2026-11-01'), 0);
    });
  });
}
