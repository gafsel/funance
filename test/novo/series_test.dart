import 'package:flutter_test/flutter_test.dart';
import 'package:funances/novo/modelo/modelos.dart';
import 'package:funances/novo/regras/series.dart';

Lancamento parcela(int n, {bool paga = false, String descricao = 'Academia', int centavos = 9000, String? categoria = 'saude'}) => Lancamento(
      id: 's_$n',
      tipo: 'saida',
      descricao: descricao,
      previstoCentavos: centavos,
      realizadoCentavos: paga ? centavos : null,
      data: '2026-${n.toString().padLeft(2, '0')}-10',
      dataEfetiva: paga ? '2026-${n.toString().padLeft(2, '0')}-10' : null,
      situacao: paga ? 'efetivado' : 'previsto',
      contaId: 'cc',
      categoriaId: categoria,
      serieId: 's',
    );

void main() {
  final serie = [parcela(9, paga: true), parcela(10, paga: true), parcela(11), parcela(12)];
  final este = serie[2];

  test('pagar ou mudar só o que foi pago não pede para replicar', () {
    expect(mudancaReplicavel(este, este.copiar(situacao: 'efetivado', realizadoCentavos: () => 9500, dataEfetiva: () => '2026-11-12')), isFalse);
    expect(mudancaReplicavel(este, este.copiar(previstoCentavos: () => 9900)), isTrue);
    expect(mudancaReplicavel(este, este.copiar(categoriaId: () => 'lazer')), isTrue);
    expect(mudancaReplicavel(este, este.copiar(data: '2026-11-15')), isTrue);
  });

  test('só este: nenhum outro muda', () {
    expect(replicarEdicao(este, este.copiar(previstoCentavos: () => 9900), serie, Alcance.soEste), isEmpty);
  });

  test('próximos: leva valor, conta e dia para os que vencem depois', () {
    final depois = este.copiar(previstoCentavos: () => 9900, contaId: 'outra', data: '2026-11-28');
    final mudados = replicarEdicao(este, depois, serie, Alcance.proximos);
    expect(mudados.map((l) => l.id), ['s_12']);
    expect(mudados.single.previstoCentavos, 9900);
    expect(mudados.single.contaId, 'outra');
    expect(mudados.single.data, '2026-12-28');
  });

  test('todos: no que já foi pago só mudam descrição e categoria', () {
    final depois = este.copiar(descricao: 'Academia nova', previstoCentavos: () => 9900, categoriaId: () => 'lazer');
    final mudados = {for (final l in replicarEdicao(este, depois, serie, Alcance.todos)) l.id: l};
    expect(mudados.keys.toSet(), {'s_9', 's_10', 's_12'});
    expect(mudados['s_9']!.descricao, 'Academia nova');
    expect(mudados['s_9']!.categoriaId, 'lazer');
    expect(mudados['s_9']!.previstoCentavos, 9000);
    expect(mudados['s_9']!.realizadoCentavos, 9000);
    expect(mudados['s_12']!.previstoCentavos, 9900);
  });

  test('mudança só de valor não toca nos que já foram pagos', () {
    expect(replicarEdicao(este, este.copiar(previstoCentavos: () => 9900), serie, Alcance.todos).map((l) => l.id), ['s_12']);
  });

  test('dia 31 se ajusta ao tamanho de cada mês', () {
    final fev = parcela(2);
    final mudados = replicarEdicao(parcela(1), parcela(1).copiar(data: '2026-01-31'), [parcela(1), fev], Alcance.proximos);
    expect(mudados.single.data, '2026-02-28');
  });

  test('excluir: sai junto só o que ainda está agendado', () {
    expect(excluirJunto(este, serie, Alcance.soEste), isEmpty);
    expect(excluirJunto(este, serie, Alcance.proximos).map((l) => l.id), ['s_12']);
    expect(excluirJunto(serie[0], serie, Alcance.todos).map((l) => l.id), ['s_11', 's_12']);
  });

  test('o cadastro da série acompanha o que mudou', () {
    expect(ajusteDaSerie(este, este.copiar(previstoCentavos: () => 9900, data: '2026-11-15')), {'valorCentavos': 9900, 'diaVencimento': 15});
    expect(ajusteDaSerie(este, este.copiar(situacao: 'efetivado')), isEmpty);
  });
}
