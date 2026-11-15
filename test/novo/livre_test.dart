import 'package:flutter_test/flutter_test.dart';
import 'package:funances/novo/modelo/modelos.dart';
import 'package:funances/novo/regras/livre.dart';

Lancamento l(String tipo, int valor, {String data = '2026-11-10', bool efetivado = true, String? serie, String? destino, String conta = 'cc'}) =>
    Lancamento(
      id: '$tipo$valor$data$serie',
      tipo: tipo,
      descricao: '',
      data: data,
      dataEfetiva: efetivado ? data : null,
      situacao: efetivado ? 'efetivado' : 'previsto',
      previstoCentavos: efetivado ? null : valor,
      realizadoCentavos: efetivado ? valor : null,
      contaId: conta,
      contaDestinoId: destino,
      serieId: serie,
    );

void main() {
  test('livre = renda − compromissos − metas − gasto', () {
    final r = calcularLivre(
      hoje: '2026-11-14',
      lancamentos: [
        l('entrada', 500000),
        l('entrada', 100000, data: '2026-11-25', efetivado: false),
        l('saida', 200000, serie: 'aluguel'),
        l('saida', 18000, data: '2026-11-20', efetivado: false),
        l('saida', 45000),
        l('transferencia', 99999, destino: 'poup'),
        l('saida', 77777, data: '2026-10-30'),
      ],
      metas: const [
        Meta(id: 'm', nome: 'Reserva', tipo: 'juntar', alvoCentavos: 1, inicio: '2026-01-01', prazo: '2027-01-01', parcelaMensalCentavos: 50000),
        Meta(id: 'x', nome: 'Encerrada', tipo: 'juntar', alvoCentavos: 1, inicio: '2026-01-01', prazo: '2027-01-01', parcelaMensalCentavos: 9999, resultado: 'atingida'),
      ],
    );
    expect(r.rendaCentavos, 600000);
    expect(r.compromissosCentavos, 218000);
    expect(r.metasCentavos, 50000);
    expect(r.gastoCentavos, 45000);
    expect(r.livreCentavos, 287000);
    expect(r.diasRestantes, 17);
    expect(r.porDiaCentavos, 287000 ~/ 17);
    expect(r.explicacao, contains('contas do mês'));
  });

  test('sem renda, explica o que falta em vez de mostrar conta sem sentido', () {
    final r = calcularLivre(hoje: '2026-11-14', lancamentos: [l('saida', 1000)], metas: const []);
    expect(r.livreCentavos, -1000);
    expect(r.porDiaCentavos, 0);
    expect(r.explicacao, contains('não há renda'));
  });

  test('saldo: inicial + meses anteriores + mês atual até hoje', () {
    const conta = Conta(id: 'cc', nome: 'Corrente', tipo: 'corrente', saldoInicialCentavos: 100000, saldoInicialData: '2026-01-01');
    final saldo = saldoDaConta(
      conta: conta,
      hoje: '2026-11-14',
      resumos: const [
        ResumoMes(mes: '2026-10', deltaPorConta: {'cc': 5000}, categorias: {}),
        ResumoMes(mes: '2026-11', deltaPorConta: {'cc': 999999}, categorias: {}),
        ResumoMes(mes: '2026-12', deltaPorConta: {'cc': 999999}, categorias: {}),
      ],
      lancamentosDoMes: [
        l('saida', 3000),
        l('entrada', 10000, data: '2026-11-14'),
        l('saida', 7000, data: '2026-11-20'),
        l('saida', 500, efetivado: false),
        l('transferencia', 2000, conta: 'poup', destino: 'cc'),
      ],
    );
    expect(saldo, 100000 + 5000 - 3000 + 10000 + 2000);
  });
}
