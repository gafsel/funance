import 'package:flutter_test/flutter_test.dart';
import 'package:funances/novo/modelo/modelos.dart';
import 'package:funances/novo/regras/leitura_frase.dart';
import 'package:funances/novo/regras/montar.dart';

void main() {
  const corrente = Conta(id: 'cc', nome: 'Itaú', tipo: 'corrente');
  const cartao = Conta(id: 'nu', nome: 'Nubank', tipo: 'cartao');

  String Function() ids() {
    var n = 0;
    return () => 'id${n++}';
  }

  Leitura leitura({int valor = 10000, int? parcelas, bool recorrente = false, bool efetivado = true, String tipo = 'saida', String data = '2026-11-14'}) =>
      Leitura(tipo: tipo, descricao: 'Coisa', valorCentavos: valor, data: data, contaId: 'x', categoriaId: 'cat', parcelas: parcelas, recorrente: recorrente, efetivado: efetivado);

  test('repartir distribui o resto nas primeiras parcelas', () {
    expect(repartir(10000, 3), [3334, 3333, 3333]);
    expect(repartir(10000, 3).reduce((a, b) => a + b), 10000);
  });

  test('simples efetivado: realizado e data efetiva, sem previsto', () {
    final m = montar(leitura(), conta: corrente, novoId: ids());
    expect(m.serie, isNull);
    final l = m.lancamentos.single;
    expect(l.situacao, 'efetivado');
    expect(l.realizadoCentavos, 10000);
    expect(l.previstoCentavos, isNull);
    expect(l.dataEfetiva, '2026-11-14');
    expect(l.contaId, 'cc');
  });

  test('agendado: só previsto', () {
    final l = montar(leitura(efetivado: false), conta: corrente, novoId: ids()).lancamentos.single;
    expect(l.situacao, 'previsto');
    expect(l.previstoCentavos, 10000);
    expect(l.realizadoCentavos, isNull);
    expect(l.dataEfetiva, isNull);
  });

  test('parcelado no cartão: todas as parcelas efetivadas, uma por mês', () {
    final m = montar(leitura(parcelas: 3, data: '2026-11-30'), conta: cartao, novoId: ids());
    expect(m.serie!['forma'], 'parcelado');
    expect(m.serie!['parcelas'], 3);
    expect(m.lancamentos.map((l) => l.data), ['2026-11-30', '2026-12-30', '2027-01-30']);
    expect(m.lancamentos.every((l) => l.efetivado && l.serieId == m.serieId), isTrue);
    expect(m.lancamentos.map((l) => l.realizadoCentavos), [3334, 3333, 3333]);
    expect(m.lancamentos.last.parcelaNumero, 3);
  });

  test('parcelado fora do cartão: só a primeira foi paga', () {
    final m = montar(leitura(parcelas: 2), conta: corrente, novoId: ids());
    expect(m.lancamentos.map((l) => l.situacao), ['efetivado', 'previsto']);
  });

  test('recorrente: doze meses, ids que o servidor consegue continuar, dia 31 respeita o mês', () {
    final m = montar(leitura(recorrente: true, data: '2026-01-31'), conta: corrente, novoId: ids());
    expect(m.lancamentos, hasLength(mesesDeRecorrencia));
    expect(m.lancamentos[1].id, '${m.serieId}_2026-02');
    expect(m.lancamentos[1].data, '2026-02-28');
    expect(m.lancamentos[1].situacao, 'previsto');
    expect(m.lancamentos.first.situacao, 'efetivado');
    expect(m.serie!['geradoAte'], '2026-12-31');
  });

  test('transferência não leva categoria', () {
    final l = montar(
      Leitura(tipo: 'transferencia', descricao: 'x', valorCentavos: 1, data: '2026-11-14', contaId: 'cc', contaDestinoId: 'p', categoriaId: 'cat'),
      conta: corrente,
      novoId: ids(),
    ).lancamentos.single;
    expect(l.categoriaId, isNull);
    expect(l.contaDestinoId, 'p');
  });

  test('a consequência diz o que vai acontecer com o dinheiro', () {
    expect(consequencia(leitura(), conta: cartao), contains('fatura de Nubank'));
    expect(consequencia(leitura(), conta: corrente), contains('saem de Itaú'));
    expect(consequencia(leitura(parcelas: 4), conta: cartao), contains('4 parcelas'));
    expect(consequencia(leitura(efetivado: false), conta: corrente), contains('agendado'));
    expect(consequencia(leitura(tipo: 'entrada'), conta: corrente), contains('entram em Itaú'));
  });
}
