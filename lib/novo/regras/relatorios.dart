import '../modelo/modelos.dart';
import 'formatos.dart';

/// Uma fatia do gasto do mês.
class Fatia {
  const Fatia({required this.categoriaId, required this.centavos, required this.anteriorCentavos, required this.fracao});

  /// `null` = as categorias menores, somadas em "Outras".
  final String? categoriaId;
  final int centavos;

  /// O mesmo no mês anterior, para comparar.
  final int anteriorCentavos;

  /// Parte do total do mês (0 a 1).
  final double fracao;

  int get variacaoCentavos => centavos - anteriorCentavos;
}

/// Para onde foi (ou de onde veio) o dinheiro num mês: uma fatia por
/// categoria, da maior para a menor. Além das `maximo` maiores, o resto vira
/// uma fatia só, "Outras": com vinte categorias, um gráfico com vinte cores
/// não se lê.
List<Fatia> fatiasDoMes(
  ResumoMes? resumo,
  ResumoMes? anterior,
  Map<String, Categoria> categorias, {
  String tipo = 'saida',
  int maximo = 8,
}) {
  bool doTipo(String id) => (categorias[id]?.tipo ?? 'saida') == tipo;
  final atuais = <String, int>{
    for (final e in (resumo?.categorias ?? const <String, (int, int)>{}).entries)
      if (e.value.$2 > 0 && doTipo(e.key)) e.key: e.value.$2,
  };
  final total = atuais.values.fold<int>(0, (s, v) => s + v);
  if (total == 0) return const [];
  int antes(String id) => anterior?.categorias[id]?.$2 ?? 0;

  final ordenadas = atuais.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  final fatias = [
    for (final e in ordenadas.take(maximo))
      Fatia(categoriaId: e.key, centavos: e.value, anteriorCentavos: antes(e.key), fracao: e.value / total),
  ];
  final resto = ordenadas.skip(maximo).toList();
  if (resto.isNotEmpty) {
    final soma = resto.fold<int>(0, (s, e) => s + e.value);
    fatias.add(Fatia(
      categoriaId: null,
      centavos: soma,
      anteriorCentavos: resto.fold<int>(0, (s, e) => s + antes(e.key)),
      fracao: soma / total,
    ));
  }
  return fatias;
}

/// Valor mês a mês, do mais antigo para o mais novo, terminando em `mes`.
/// Com `categoriaId`, o realizado da categoria; sem, o total de saídas (ou
/// de entradas).
List<(String mes, int centavos)> serieMensal(
  Iterable<ResumoMes> resumos,
  String mes, {
  int meses = 6,
  String? categoriaId,
  bool entradas = false,
}) {
  final porMes = {for (final r in resumos) r.mes: r};
  return [
    for (var i = meses - 1; i >= 0; i--)
      () {
        final m = somarMeses(mes, -i);
        final r = porMes[m];
        final valor = r == null
            ? 0
            : (categoriaId != null ? (r.categorias[categoriaId]?.$2 ?? 0) : (entradas ? r.entradasCentavos : r.saidasCentavos));
        return (m, valor);
      }(),
  ];
}
