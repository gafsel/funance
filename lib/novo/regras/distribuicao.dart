import '../modelo/modelos.dart';
import 'formatos.dart';
import 'leitura_frase.dart';

/// Os três destinos do dinheiro. `conforto` aparece como "Estilo de vida" e
/// `investimento` como "Futuro" (o que foi guardado, investido ou sobrou).
const gruposDeGasto = ['essencial', 'conforto', 'investimento'];

String nomeDoGrupo(String grupo) => switch (grupo) {
      'essencial' => 'Essencial',
      'conforto' => 'Estilo de vida',
      _ => 'Futuro',
    };

const _essenciais = [
  'moradia', 'aluguel', 'condominio', 'mercado', 'supermercado', 'feira', 'saude', 'farmacia', 'plano', 'transporte',
  'combustivel', 'gasolina', 'luz', 'agua', 'gas', 'energia', 'internet', 'telefone', 'celular', 'conta', 'educacao',
  'escola', 'faculdade', 'creche', 'imposto', 'taxa', 'seguro', 'financiamento', 'emprestimo', 'parcela', 'fornecedor',
  'pessoal', 'folha', 'pro labore', 'prolabore', 'estrutura',
];
const _futuros = ['investimento', 'reserva', 'poupanca', 'previdencia', 'aposentadoria', 'tesouro'];

/// Grupo de uma categoria que ainda não tem um: adivinhado pelo nome. Na
/// dúvida é estilo de vida, que é o grupo que a pessoa pode mexer.
String grupoSugerido(String nome) {
  final n = normalizar(nome);
  if (_futuros.any(n.contains)) return 'investimento';
  if (_essenciais.any(n.contains)) return 'essencial';
  return 'conforto';
}

String grupoDa(Categoria c) => gruposDeGasto.contains(c.grupo) ? c.grupo! : grupoSugerido(c.nome);

/// Uma referência de distribuição da renda, em pontos percentuais.
class Referencia {
  const Referencia(this.id, this.nome, this.quando, this.essencial, this.conforto, this.investimento);
  final String id;
  final String nome;

  /// Para quem serve, em uma linha.
  final String quando;
  final int essencial;
  final int conforto;
  final int investimento;

  int de(String grupo) => switch (grupo) { 'essencial' => essencial, 'conforto' => conforto, _ => investimento };
  String get rotulo => '$essencial · $conforto · $investimento';
}

const referencias = [
  Referencia('equilibrio', 'Equilíbrio', 'O clássico: metade para o essencial, 30% para viver, 20% para o futuro.', 50, 30, 20),
  Referencia('acelerar', 'Acelerar', 'Para quitar dívida cara ou chegar antes numa meta: aperta o estilo de vida por um tempo.', 50, 20, 30),
  Referencia('fixo-alto', 'Fixo alto', 'Quando aluguel, escola ou saúde pesam e não dá para mudar agora.', 60, 20, 20),
];

Referencia referenciaDe(String? id) => referencias.where((r) => r.id == id).firstOrNull ?? referencias.first;

/// Uma categoria dentro de um grupo, com a média e a tendência.
class CategoriaNoGrupo {
  const CategoriaNoGrupo(this.categoriaId, this.mediaCentavos, this.crescimentoCentavos);
  final String categoriaId;
  final int mediaCentavos;

  /// O último mês contra a média dos anteriores. Positivo = subiu.
  final int crescimentoCentavos;
}

/// O que o app aponta. `resolver` é estrutural (cortar pequenos gastos não
/// fecha a conta); `reduzir` tem um valor e alternativas; `certo` é quando
/// está dentro da referência.
class Apontamento {
  const Apontamento({required this.tipo, required this.grupo, required this.titulo, required this.texto, this.alternativas = const [], this.categorias = const []});
  final String tipo;
  final String grupo;
  final String titulo;
  final String texto;
  final List<String> alternativas;
  final List<String> categorias;
}

class Diagnostico {
  const Diagnostico({
    required this.meses,
    required this.parcial,
    required this.rendaCentavos,
    required this.porGrupo,
    required this.referencia,
    required this.categorias,
    required this.apontamentos,
  });

  /// Os meses que entraram na média, do mais antigo para o mais novo.
  final List<String> meses;

  /// Só há o mês corrente, ainda incompleto.
  final bool parcial;

  /// Tudo em média mensal.
  final int rendaCentavos;
  final Map<String, int> porGrupo;
  final Referencia referencia;
  final Map<String, List<CategoriaNoGrupo>> categorias;

  /// O mais importante primeiro.
  final List<Apontamento> apontamentos;

  int percentual(String grupo) => rendaCentavos <= 0 ? 0 : ((porGrupo[grupo] ?? 0) * 100 / rendaCentavos).round();
  int tetoCentavos(String grupo) => rendaCentavos * referencia.de(grupo) ~/ 100;

  /// Quanto o grupo passou do teto (essencial e estilo de vida) ou ficou
  /// abaixo do piso (futuro). Zero quando está dentro.
  int foraCentavos(String grupo) {
    final diferenca = (porGrupo[grupo] ?? 0) - tetoCentavos(grupo);
    return grupo == 'investimento' ? (diferenca < 0 ? -diferenca : 0) : (diferenca > 0 ? diferenca : 0);
  }
}

/// Arredonda para cima em dezenas de reais: "baixar R$ 300" se lê melhor
/// que "baixar R$ 287,43".
int _redondo(int centavos) => ((centavos + 999) ~/ 1000) * 1000;

/// O diagnóstico da distribuição da renda. Usa a média dos três meses
/// fechados antes de [mesAtual] que tiveram renda; sem nenhum, o mês
/// corrente (parcial). Nulo quando não há renda para comparar.
Diagnostico? diagnosticar({
  required List<ResumoMes> resumos,
  required Map<String, Categoria> categorias,
  required String mesAtual,
  required Referencia referencia,
  required String Function(String categoriaId) nomeDe,
}) {
  final porMes = {for (final r in resumos) r.mes: r};
  var meses = [for (var i = 3; i >= 1; i--) somarMeses(mesAtual, -i)]
      .where((m) => (porMes[m]?.entradasCentavos ?? 0) > 0)
      .toList();
  final parcial = meses.isEmpty;
  if (parcial) {
    if ((porMes[mesAtual]?.entradasCentavos ?? 0) <= 0) return null;
    meses = [mesAtual];
  }
  final n = meses.length;
  final renda = meses.fold<int>(0, (s, m) => s + porMes[m]!.entradasCentavos) ~/ n;

  // Gasto de cada categoria de saída, mês a mês.
  final gastos = <String, List<int>>{};
  for (final (i, m) in meses.indexed) {
    porMes[m]!.categorias.forEach((id, valores) {
      final c = categorias[id];
      if (valores.$2 <= 0 || (c != null && c.tipo == 'entrada')) return;
      (gastos[id] ??= List.filled(n, 0))[i] = valores.$2;
    });
  }
  String grupoDe(String id) => categorias[id] == null ? 'conforto' : grupoDa(categorias[id]!);

  final noGrupo = <String, List<CategoriaNoGrupo>>{for (final g in gruposDeGasto) g: []};
  final gasto = <String, int>{for (final g in gruposDeGasto) g: 0};
  gastos.forEach((id, valores) {
    final media = valores.fold<int>(0, (s, v) => s + v) ~/ n;
    final anteriores = n > 1 ? valores.take(n - 1).fold<int>(0, (s, v) => s + v) ~/ (n - 1) : media;
    final g = grupoDe(id);
    noGrupo[g]!.add(CategoriaNoGrupo(id, media, valores.last - anteriores));
    gasto[g] = gasto[g]! + media;
  });
  for (final lista in noGrupo.values) {
    lista.sort((a, b) => b.mediaCentavos.compareTo(a.mediaCentavos));
  }
  // Futuro é o que foi guardado de propósito mais o que sobrou da renda.
  final porGrupo = {
    'essencial': gasto['essencial']!,
    'conforto': gasto['conforto']!,
    'investimento': renda - gasto['essencial']! - gasto['conforto']!,
  };

  final base = Diagnostico(
    meses: meses, parcial: parcial, rendaCentavos: renda, porGrupo: porGrupo,
    referencia: referencia, categorias: noGrupo, apontamentos: const [],
  );
  final apontamentos = <Apontamento>[];
  final pctEssencial = base.percentual('essencial');
  final foraEssencial = base.foraCentavos('essencial');
  final foraConforto = base.foraCentavos('conforto');
  final maiores = noGrupo['essencial']!.take(2).toList();
  String lista(Iterable<CategoriaNoGrupo> cs) => cs.map((c) => '${nomeDe(c.categoriaId)} (${reais(c.mediaCentavos)})').join(' e ');

  if (porGrupo['investimento']! < 0) {
    apontamentos.add(Apontamento(
      tipo: 'resolver', grupo: 'investimento',
      titulo: 'Os gastos passam da renda',
      texto: 'Em média saem ${reais(-porGrupo['investimento']!)} a mais do que entram por mês. '
          'Antes de pensar em distribuição, é preciso parar de gastar o que não entrou: isso vira dívida.',
    ));
  }
  // Essencial dez pontos acima da referência não se resolve cortando café.
  if (pctEssencial >= referencia.essencial + 10 && maiores.isNotEmpty) {
    apontamentos.add(Apontamento(
      tipo: 'resolver', grupo: 'essencial',
      titulo: 'O fixo está alto',
      texto: 'O essencial leva $pctEssencial% da renda (${reais(porGrupo['essencial']!)} por mês); a referência é ${referencia.essencial}%. '
          'Cortar pequenos gastos não fecha essa diferença de ${reais(foraEssencial)}. '
          'O que resolve é rever os maiores, ${lista(maiores)}, ou aumentar a renda.',
      alternativas: [
        if (referencia.id != 'fixo-alto') 'Se não dá para mudar agora, use a referência "Fixo alto" e aperte o estilo de vida.',
      ],
      categorias: [for (final c in maiores) c.categoriaId],
    ));
  }
  if (foraConforto > 0) {
    // Quem mais subiu vem primeiro; sem tendência, os maiores.
    final candidatas = noGrupo['conforto']!.toList()
      ..sort((a, b) {
        final porCrescimento = b.crescimentoCentavos.compareTo(a.crescimentoCentavos);
        return porCrescimento != 0 ? porCrescimento : b.mediaCentavos.compareTo(a.mediaCentavos);
      });
    final alvo = _redondo(foraConforto);
    final tres = candidatas.take(3).toList();
    final alternativas = <String>[];
    final unica = candidatas.where((c) => c.mediaCentavos >= alvo * 3 ~/ 2).firstOrNull;
    if (unica != null) {
      alternativas.add('Baixar ${nomeDe(unica.categoriaId)} em ${reais(alvo)}: de ${reais(unica.mediaCentavos)} para ${reais(unica.mediaCentavos - alvo)}.');
    }
    // Só entra na divisão quem gasta mais do que a sua parte do corte.
    var dividir = tres;
    for (var volta = 0; volta < 2 && dividir.length >= 2; volta++) {
      final cada = _redondo(alvo ~/ dividir.length);
      dividir = [for (final c in dividir) if (c.mediaCentavos > cada) c];
    }
    if (dividir.length >= 2) {
      final cada = _redondo(alvo ~/ dividir.length);
      alternativas.add('Dividir o corte: ${dividir.map((c) => nomeDe(c.categoriaId)).join(', ')}, ${reais(cada)} a menos em cada.');
    }
    final subiram = tres.where((c) => c.crescimentoCentavos > 0).toList();
    apontamentos.add(Apontamento(
      tipo: 'reduzir', grupo: 'conforto',
      titulo: 'Estilo de vida está ${reais(foraConforto)} acima do teto',
      texto: 'O grupo inteiro deveria caber em ${reais(base.tetoCentavos('conforto'))} por mês (${referencia.conforto}% da renda) e está em ${reais(porGrupo['conforto']!)}. '
          'Não importa onde você corta, desde que a soma caiba.'
          '${subiram.isEmpty ? '' : ' O que mais subiu: ${subiram.map((c) => '${nomeDe(c.categoriaId)} (+${reais(c.crescimentoCentavos)})').join(', ')}.'}',
      alternativas: alternativas,
      categorias: [for (final c in tres) c.categoriaId],
    ));
  }
  if (foraEssencial > 0 && pctEssencial < referencia.essencial + 10 && maiores.isNotEmpty) {
    apontamentos.add(Apontamento(
      tipo: 'reduzir', grupo: 'essencial',
      titulo: 'Essencial está ${reais(foraEssencial)} acima do teto',
      texto: 'É pouco: $pctEssencial% da renda contra ${referencia.essencial}% da referência. Vale olhar ${lista(maiores)} na próxima renovação ou troca de plano.',
      categorias: [for (final c in maiores) c.categoriaId],
    ));
  }
  if (apontamentos.isEmpty) {
    apontamentos.add(Apontamento(
      tipo: 'certo', grupo: 'investimento',
      titulo: 'A distribuição está dentro da referência',
      texto: 'Sobram ${reais(porGrupo['investimento']!)} por mês para o futuro (${base.percentual('investimento')}% da renda). '
          'O próximo passo é dar destino a esse dinheiro: reserva, dívida ou meta.',
    ));
  }

  return Diagnostico(
    meses: meses, parcial: parcial, rendaCentavos: renda, porGrupo: porGrupo,
    referencia: referencia, categorias: noGrupo, apontamentos: apontamentos,
  );
}
