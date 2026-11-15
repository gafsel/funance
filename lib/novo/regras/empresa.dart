import '../modelo/modelos.dart';
import 'formatos.dart';

/// Faixas de prazo do que está em aberto.
enum Prazo { vencido, seteDias, trintaDias, depois }

const rotulosDePrazo = {
  Prazo.vencido: 'Vencido',
  Prazo.seteDias: 'Até 7 dias',
  Prazo.trintaDias: 'De 8 a 30 dias',
  Prazo.depois: 'Depois de 30 dias',
};

Prazo prazoDe(String data, String hoje) {
  if (data.compareTo(hoje) < 0) return Prazo.vencido;
  if (data.compareTo(somarDias(hoje, 7)) <= 0) return Prazo.seteDias;
  if (data.compareTo(somarDias(hoje, 30)) <= 0) return Prazo.trintaDias;
  return Prazo.depois;
}

/// Total em aberto por faixa de prazo, para um lado (a receber ou a pagar).
Map<Prazo, int> porPrazo(Iterable<Lancamento> previstos, String hoje, {required bool aReceber}) {
  final totais = {for (final p in Prazo.values) p: 0};
  for (final l in previstos) {
    if (!l.previsto || l.ehTransferencia || l.ehEntrada != aReceber) continue;
    final faixa = prazoDe(l.data, hoje);
    totais[faixa] = totais[faixa]! + l.valorCentavos;
  }
  return totais;
}

/// Caixa previsto para os próximos 30 dias.
class CaixaPrevisto {
  const CaixaPrevisto({
    required this.hojeCentavos,
    required this.minimoCentavos,
    required this.diaDoMinimo,
    required this.finalCentavos,
    required this.aReceberVencidoCentavos,
  });

  final int hojeCentavos;
  final int minimoCentavos;
  final String? diaDoMinimo;
  final int finalCentavos;

  /// Ficou de fora da previsão: quem já atrasou pode não pagar.
  final int aReceberVencidoCentavos;
}

/// Projeta o caixa das contas de uso. Regras:
/// - o que está a receber e já venceu NÃO entra (não dá para contar com ele);
/// - o que está a pagar e já venceu entra como se vencesse hoje (a conta
///   continua existindo).
CaixaPrevisto preverCaixa({
  required String hoje,
  required int caixaHojeCentavos,
  required Set<String> contasDeUso,
  required Iterable<Lancamento> previstos,
}) {
  final limite = somarDias(hoje, 30);
  var aReceberVencido = 0;
  final movimentos = <(String, int)>[];
  for (final l in previstos) {
    if (!l.previsto) continue;
    final vencido = l.data.compareTo(hoje) < 0;
    if (!vencido && l.data.compareTo(limite) > 0) continue;
    var valor = 0;
    if (l.ehEntrada && contasDeUso.contains(l.contaId)) valor += l.valorCentavos;
    if (!l.ehEntrada && contasDeUso.contains(l.contaId)) valor -= l.valorCentavos;
    if (l.ehTransferencia && contasDeUso.contains(l.contaDestinoId)) valor += l.valorCentavos;
    if (valor == 0) continue;
    if (vencido && valor > 0) {
      aReceberVencido += valor;
      continue;
    }
    movimentos.add((vencido ? hoje : l.data, valor));
  }
  movimentos.sort((a, b) => a.$1.compareTo(b.$1));

  var caixa = caixaHojeCentavos;
  var minimo = caixa;
  String? diaDoMinimo;
  for (final (dia, valor) in movimentos) {
    caixa += valor;
    if (caixa < minimo) {
      minimo = caixa;
      diaDoMinimo = dia;
    }
  }
  return CaixaPrevisto(
    hojeCentavos: caixaHojeCentavos,
    minimoCentavos: minimo,
    diaDoMinimo: diaDoMinimo,
    finalCentavos: caixa,
    aReceberVencidoCentavos: aReceberVencido,
  );
}

/// Resultado do mês por centro de custo, com o pró-labore à parte.
class ResultadoDoMes {
  const ResultadoDoMes({required this.receitas, required this.despesas, required this.proLabore});

  /// (categoriaId, previsto, realizado), do maior realizado para o menor.
  final List<(String, int, int)> receitas;
  final List<(String, int, int)> despesas;

  /// (previsto, realizado) somado das categorias de pró-labore.
  final (int, int) proLabore;

  int get receitaCentavos => receitas.fold(0, (s, r) => s + r.$3);
  int get despesaCentavos => despesas.fold(0, (s, r) => s + r.$3);

  /// Resultado da operação, antes da retirada do dono.
  int get antesDoProLaboreCentavos => receitaCentavos - despesaCentavos;
  int get depoisDoProLaboreCentavos => antesDoProLaboreCentavos - proLabore.$2;
}

ResultadoDoMes resultadoDoMes(ResumoMes? resumo, Map<String, Categoria> categorias, Set<String> proLaboreIds) {
  final receitas = <(String, int, int)>[];
  final despesas = <(String, int, int)>[];
  var proLabore = (0, 0);
  resumo?.categorias.forEach((id, valores) {
    if (valores.$1 == 0 && valores.$2 == 0) return;
    if (proLaboreIds.contains(id)) {
      proLabore = (proLabore.$1 + valores.$1, proLabore.$2 + valores.$2);
    } else if (categorias[id]?.tipo == 'entrada') {
      receitas.add((id, valores.$1, valores.$2));
    } else {
      despesas.add((id, valores.$1, valores.$2));
    }
  });
  receitas.sort((a, b) => b.$3.compareTo(a.$3));
  despesas.sort((a, b) => b.$3.compareTo(a.$3));
  return ResultadoDoMes(receitas: receitas, despesas: despesas, proLabore: proLabore);
}

/// Mensagem de cobrança para copiar. O app não envia nada: quem manda é a
/// pessoa, pelo canal que ela usa com o cliente.
String mensagemDeCobranca(String nome, List<Lancamento> vencidos, String hoje) {
  final itens = [...vencidos]..sort((a, b) => a.data.compareTo(b.data));
  final total = itens.fold<int>(0, (s, l) => s + l.valorCentavos);
  String data(String d) => '${d.substring(8, 10)}/${d.substring(5, 7)}';
  final linhas = [
    'Olá, $nome. Tudo bem?',
    '',
    if (itens.length == 1)
      'Consta em aberto ${itens.single.descricao.isEmpty ? 'um valor' : '"${itens.single.descricao}"'} de ${reais(total)}, com vencimento em ${data(itens.single.data)}.'
    else ...[
      'Constam em aberto ${itens.length} valores, no total de ${reais(total)}:',
      for (final l in itens) '- ${l.descricao.isEmpty ? 'Sem descrição' : l.descricao}: ${reais(l.valorCentavos)}, vencido em ${data(l.data)}',
    ],
    '',
    'Consegue me confirmar a previsão de pagamento? Se já pagou, me avise que eu dou baixa.',
    '',
    'Obrigado.',
  ];
  return linhas.join('\n');
}
