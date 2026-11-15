import 'package:flutter_test/flutter_test.dart';
import 'package:funances/novo/modelo/modelos.dart';
import 'package:funances/novo/regras/relatorios.dart';

void main() {
  const categorias = {
    'a': Categoria(id: 'a', nome: 'A', tipo: 'saida'),
    'b': Categoria(id: 'b', nome: 'B', tipo: 'saida'),
    'c': Categoria(id: 'c', nome: 'C', tipo: 'saida'),
    'sal': Categoria(id: 'sal', nome: 'Salário', tipo: 'entrada'),
  };
  ResumoMes mes(String m, Map<String, int> realizado, {int entradas = 0, int saidas = 0}) => ResumoMes(
      mes: m, deltaPorConta: const {}, categorias: {for (final e in realizado.entries) e.key: (0, e.value)}, entradasCentavos: entradas, saidasCentavos: saidas);

  test('fatias: da maior para a menor, com a parte do total e a comparação', () {
    final f = fatiasDoMes(mes('2026-11', {'a': 6000, 'b': 3000, 'c': 1000, 'sal': 99999}), mes('2026-10', {'a': 5000, 'c': 4000}), categorias);
    expect(f.map((x) => x.categoriaId), ['a', 'b', 'c']);
    expect(f.first.fracao, 0.6);
    expect(f.map((x) => x.variacaoCentavos), [1000, 3000, -3000]);
  });

  test('fatias: além do máximo, o resto vira "Outras"', () {
    final f = fatiasDoMes(mes('2026-11', {'a': 6000, 'b': 3000, 'c': 1000}), mes('2026-10', {'b': 100, 'c': 200}), categorias, maximo: 1);
    expect(f.map((x) => (x.categoriaId, x.centavos, x.anteriorCentavos)), [('a', 6000, 0), (null, 4000, 300)]);
  });

  test('fatias de entradas e mês vazio', () {
    expect(fatiasDoMes(mes('2026-11', {'a': 10, 'sal': 500}), null, categorias, tipo: 'entrada').single.categoriaId, 'sal');
    expect(fatiasDoMes(null, null, categorias), isEmpty);
  });

  test('série mensal: seis meses terminando no mês pedido, com zero onde não há resumo', () {
    final resumos = [mes('2026-11', {'a': 300}, saidas: 900, entradas: 2000), mes('2026-09', {'a': 100}, saidas: 400)];
    expect(serieMensal(resumos, '2026-11', meses: 3), [('2026-09', 400), ('2026-10', 0), ('2026-11', 900)]);
    expect(serieMensal(resumos, '2026-11', meses: 3, categoriaId: 'a').map((x) => x.$2), [100, 0, 300]);
    expect(serieMensal(resumos, '2026-11', meses: 2, entradas: true).map((x) => x.$2), [0, 2000]);
    expect(serieMensal(resumos, '2027-01', meses: 3).first.$1, '2026-11');
  });
}
