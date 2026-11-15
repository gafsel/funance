import 'package:flutter_test/flutter_test.dart';
import 'package:funances/novo/modelo/modelos.dart';
import 'package:funances/novo/regras/agendados.dart';
import 'package:funances/novo/regras/leitura_frase.dart';

Lancamento agendado(String id, String descricao, int centavos, String data, {String? categoria, String tipo = 'saida', String conta = 'cc'}) =>
    Lancamento(id: id, tipo: tipo, descricao: descricao, previstoCentavos: centavos, data: data, situacao: 'previsto', contaId: conta, categoriaId: categoria);

Leitura leitura(String descricao, int centavos, {String data = '2026-11-15', String? categoria, String tipo = 'saida', bool efetivado = true, int? parcelas, bool recorrente = false}) =>
    Leitura(tipo: tipo, descricao: descricao, valorCentavos: centavos, data: data, contaId: 'cc', categoriaId: categoria, efetivado: efetivado, parcelas: parcelas, recorrente: recorrente);

void main() {
  final luz = agendado('luz', 'Conta de luz', 18900, '2026-11-18', categoria: 'moradia');
  final internet = agendado('internet', 'Internet', 11990, '2026-11-13', categoria: 'moradia');
  final freela = agendado('freela', 'Freela do site', 120000, '2026-11-21', categoria: 'salario', tipo: 'entrada');
  final todos = [luz, internet, freela];

  test('valor igual e data próxima bastam', () {
    expect(agendadoQueCorresponde(leitura('boleto', 11990), todos)?.id, 'internet');
  });

  test('valor parecido precisa da categoria ou de uma palavra em comum', () {
    // A conta de luz veio 6% mais cara.
    expect(agendadoQueCorresponde(leitura('luz', 20050), todos)?.id, 'luz');
    expect(agendadoQueCorresponde(leitura('energia', 20050, categoria: 'moradia'), todos)?.id, 'luz');
    expect(agendadoQueCorresponde(leitura('mercado', 20050), todos), isNull);
  });

  test('valor bem diferente só com categoria e palavra juntas', () {
    expect(agendadoQueCorresponde(leitura('luz', 23000, categoria: 'moradia'), todos)?.id, 'luz');
    expect(agendadoQueCorresponde(leitura('luz', 23000), todos), isNull);
    expect(agendadoQueCorresponde(leitura('luz', 40000, categoria: 'moradia'), todos), isNull);
  });

  test('tipo diferente, agendado, parcelado ou recorrente não pagam agendado', () {
    expect(agendadoQueCorresponde(leitura('freela do site', 120000), todos), isNull);
    expect(agendadoQueCorresponde(leitura('freela do site', 120000, tipo: 'entrada'), todos)?.id, 'freela');
    expect(agendadoQueCorresponde(leitura('internet', 11990, efetivado: false), todos), isNull);
    expect(agendadoQueCorresponde(leitura('internet', 11990, parcelas: 3), todos), isNull);
    expect(agendadoQueCorresponde(leitura('internet', 11990, recorrente: true), todos), isNull);
  });

  test('longe demais no calendário não é o mesmo', () {
    expect(agendadoQueCorresponde(leitura('internet', 11990, data: '2026-09-01'), todos), isNull);
    expect(agendadoQueCorresponde(leitura('internet', 11990, data: '2026-12-20'), todos)?.id, 'internet');
    expect(agendadoQueCorresponde(leitura('internet', 11990, data: '2027-02-01'), todos), isNull);
  });

  test('entre dois iguais, o de vencimento mais próximo; cada um só uma vez', () {
    final parcelas = [
      agendado('p1', 'Parcela 1', 12000, '2026-11-17', categoria: 'compras'),
      agendado('p2', 'Parcela 2', 12000, '2026-12-17', categoria: 'compras'),
    ];
    final a = leitura('parcela da loja', 12000, categoria: 'compras');
    final b = leitura('parcela da loja', 12000, categoria: 'compras', data: '2026-12-10');
    final pares = agendadosDasLeituras([a, b], parcelas);
    expect(pares[a]?.id, 'p1');
    expect(pares[b]?.id, 'p2');
    expect(agendadosDasLeituras([a, a.copiar(descricao: 'outra')], [parcelas.first]).length, 1);
  });
}
