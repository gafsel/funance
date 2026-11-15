import 'package:flutter_test/flutter_test.dart';
import 'package:funances/novo/modelo/modelos.dart';
import 'package:funances/novo/telas/revisao.dart';

void main() {
  Lancamento l(String id, String dia, int valor, {String? categoria, bool pago = true, String tipo = 'saida'}) => Lancamento(
      id: id, tipo: tipo, descricao: '', data: dia, dataEfetiva: pago ? dia : null, situacao: pago ? 'efetivado' : 'previsto',
      realizadoCentavos: pago ? valor : null, previstoCentavos: pago ? null : valor, contaId: 'cc', categoriaId: categoria);

  test('resume os últimos sete dias: gasto, maiores categorias, pendências', () {
    final r = resumirSemana([
      l('a', '2026-11-14', 5000, categoria: 'mercado'),
      l('b', '2026-11-10', 3000, categoria: 'lazer'),
      l('c', '2026-11-08', 2000),
      l('c', '2026-11-08', 2000),
      l('fora', '2026-11-07', 9999, categoria: 'mercado'),
      l('entrada', '2026-11-12', 7777, tipo: 'entrada'),
      l('vencido', '2026-11-11', 100, pago: false),
      l('futuro', '2026-11-20', 100, pago: false),
    ], '2026-11-14');
    expect(r.gastoCentavos, 10000);
    expect(r.maiores, [('mercado', 5000), ('lazer', 3000), (null, 2000)]);
    expect(r.semCategoria, 1);
    expect(r.vencidos, 1);
  });

  test('a semana começa na segunda', () {
    expect(inicioDaSemana('2026-11-14'), '2026-11-09');
    expect(inicioDaSemana('2026-11-09'), '2026-11-09');
    expect(marcaDaSemana('2026-11-15'), 'semana-2026-11-09');
  });
}
