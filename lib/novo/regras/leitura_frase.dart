import '../modelo/modelos.dart';
import 'contas_na_frase.dart';
import 'formatos.dart';

/// O que foi entendido de uma frase. É o mesmo formato que a IA devolve
/// (`interpretarFrase` no servidor): a tela não sabe quem leu.
class Leitura {
  const Leitura({
    required this.tipo,
    required this.descricao,
    required this.valorCentavos,
    required this.data,
    this.contaId,
    this.contaDestinoId,
    this.categoriaId,
    this.parcelas,
    this.recorrente = false,
    this.efetivado = true,
    this.original = '',
    this.contraparteId,
  });

  final String tipo;
  final String descricao;
  final int valorCentavos;
  final String data;
  final String? contaId;
  final String? contaDestinoId;
  final String? categoriaId;
  final int? parcelas;
  final bool recorrente;
  final bool efetivado;

  /// A linha como a pessoa escreveu.
  final String original;

  /// Cliente ou fornecedor (só em espaço de empresa).
  final String? contraparteId;

  /// Dá para salvar sem perguntar mais nada?
  bool get completa =>
      valorCentavos > 0 &&
      contaId != null &&
      (tipo != 'transferencia' || (contaDestinoId != null && contaDestinoId != contaId));

  Leitura copiar({
    String? tipo,
    String? descricao,
    int? valorCentavos,
    String? data,
    String? Function()? contaId,
    String? Function()? contaDestinoId,
    String? Function()? categoriaId,
    int? Function()? parcelas,
    bool? recorrente,
    bool? efetivado,
    String? Function()? contraparteId,
  }) =>
      Leitura(
        tipo: tipo ?? this.tipo,
        descricao: descricao ?? this.descricao,
        valorCentavos: valorCentavos ?? this.valorCentavos,
        data: data ?? this.data,
        contaId: contaId != null ? contaId() : this.contaId,
        contaDestinoId: contaDestinoId != null ? contaDestinoId() : this.contaDestinoId,
        categoriaId: categoriaId != null ? categoriaId() : this.categoriaId,
        parcelas: parcelas != null ? parcelas() : this.parcelas,
        recorrente: recorrente ?? this.recorrente,
        efetivado: efetivado ?? this.efetivado,
        original: original,
        contraparteId: contraparteId != null ? contraparteId() : this.contraparteId,
      );

  factory Leitura.deMapa(Map<Object?, Object?> m, String original) => Leitura(
        tipo: m['tipo'] as String? ?? 'saida',
        descricao: m['descricao'] as String? ?? '',
        valorCentavos: (m['valorCentavos'] as num?)?.toInt() ?? 0,
        data: m['data'] as String? ?? '',
        contaId: m['contaId'] as String?,
        contaDestinoId: m['contaDestinoId'] as String?,
        categoriaId: m['categoriaId'] as String?,
        parcelas: (m['parcelas'] as num?)?.toInt(),
        recorrente: m['recorrente'] == true,
        efetivado: m['efetivado'] != false,
        original: original,
      );
}

/// O que o leitor precisa saber do espaço para entender uma frase.
class ContextoDeLeitura {
  const ContextoDeLeitura({
    required this.hoje,
    required this.contas,
    required this.categorias,
    this.aprendido = const {},
    this.contaPadraoId,
    this.membros = const [],
    this.euId,
  });

  /// Membros do espaço e quem está lançando: é o que permite entender
  /// "meu nubank" e "nubank da bárbara".
  final List<Membro> membros;
  final String? euId;

  final String hoje;
  final List<Conta> contas;
  final List<Categoria> categorias;

  /// Palavra da descrição → categoria mais usada com ela, tirado do histórico.
  final Map<String, String> aprendido;

  /// Conta usada quando a frase não cita nenhuma.
  final String? contaPadraoId;
}

/// Tira acentos e caixa, para comparar o que a pessoa digitou.
String normalizar(String s) {
  const de = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  const para = 'aaaaaeeeeiiiiooooouuuucn';
  final b = StringBuffer();
  for (final r in s.toLowerCase().runes) {
    final c = String.fromCharCode(r);
    final i = de.indexOf(c);
    b.write(i >= 0 ? para[i] : c);
  }
  return b.toString();
}

final _valor = RegExp(r'(?:r\$\s*)?(\d{1,3}(?:\.\d{3})+(?:,\d{1,2})?|\d+(?:[.,]\d{1,2})?)(?!\s*x\b)(?![\d/])');
final _parcelas = RegExp(r'\b(?:em\s+)?(\d{1,3})\s*x\b|\b(\d{1,3})\s+(?:vezes|parcelas)\b');
final _dataNumerica = RegExp(r'\b(?:dia\s+)?(\d{1,2})/(\d{1,2})(?:/(\d{2,4}))?\b');
final _diaSolto = RegExp(r'\bdia\s+(\d{1,2})\b');

const _palavrasDeEntrada = [
  'recebi', 'receber', 'recebido', 'ganhei', 'entrou', 'salario', 'pagaram',
  'me pagou', 'reembolso', 'rendimento', 'vendi', 'venda',
];
const _palavrasDeTransferencia = [
  'transferi', 'transferencia', 'transferir', 'passei', 'guardei', 'apliquei',
  'resgatei', 'movi',
];
const _palavrasDeFuturo = [
  'vence', 'vencimento', 'a pagar', 'a receber', 'vou pagar', 'vou receber',
  'agendar', 'agendado', 'previsto',
];
const _palavrasDeRecorrencia = [
  'todo mes', 'todos os meses', 'mensal', 'mensalmente', 'por mes',
];
/// Verbos que dizem o tipo e não fazem parte da descrição. Substantivos
/// como "salário" ficam: é por eles que a categoria é encontrada.
const _verbos = {
  'recebi', 'receber', 'recebido', 'ganhei', 'entrou', 'pagaram', 'vendi',
  'transferi', 'transferir', 'passei', 'guardei', 'apliquei', 'resgatei',
  'movi', 'vence', 'vou', 'pagar', 'mes', 'todo', 'todos', 'os', 'meses',
  'mensal', 'mensalmente',
};
const _ruido = {
  'de', 'da', 'do', 'no', 'na', 'em', 'com', 'para', 'pra', 'por', 'o', 'a',
  'e', 'reais', 'real', 'hoje', 'ontem', 'amanha', 'anteontem', 'dia', 'x',
  'pelo', 'pela', 'um', 'uma', 'paguei', 'gastei', 'comprei', 'pago',
};

/// Lê UMA linha. Sem valor reconhecível devolve `null`: é o sinal para a
/// tela tentar a IA ou abrir o modo avançado.
Leitura? lerLinha(String linha, ContextoDeLeitura ctx) {
  final original = linha.trim();
  if (original.isEmpty) return null;
  var resto = ' ${normalizar(original)} ';

  // Parcelas ("em 10x", "3 vezes") saem antes do valor, para o "10" de
  // "10x" não ser lido como dinheiro.
  int? parcelas;
  final mp = _parcelas.firstMatch(resto);
  if (mp != null) {
    final n = int.parse(mp.group(1) ?? mp.group(2)!);
    if (n >= 2 && n <= 120) parcelas = n;
    resto = resto.replaceRange(mp.start, mp.end, ' ');
  }

  // Data.
  var data = ctx.hoje;
  var dataDita = false;
  final md = _dataNumerica.firstMatch(resto);
  if (md != null) {
    final dia = int.parse(md.group(1)!);
    final mes = int.parse(md.group(2)!);
    var ano = int.parse(ctx.hoje.substring(0, 4));
    if (md.group(3) != null) {
      ano = int.parse(md.group(3)!);
      if (ano < 100) ano += 2000;
    }
    if (mes >= 1 && mes <= 12 && dia >= 1 && dia <= 31) {
      data = diaNoMes('$ano-${doisDigitos(mes)}', dia);
      dataDita = true;
      resto = resto.replaceRange(md.start, md.end, ' ');
    }
  } else {
    final ms = _diaSolto.firstMatch(resto);
    if (ms != null) {
      final dia = int.parse(ms.group(1)!);
      if (dia >= 1 && dia <= 31) {
        data = diaNoMes(ctx.hoje.substring(0, 7), dia);
        dataDita = true;
        resto = resto.replaceRange(ms.start, ms.end, ' ');
      }
    } else if (resto.contains(' anteontem ')) {
      data = somarDias(ctx.hoje, -2);
      dataDita = true;
    } else if (resto.contains(' ontem ')) {
      data = somarDias(ctx.hoje, -1);
      dataDita = true;
    } else if (resto.contains(' amanha ')) {
      data = somarDias(ctx.hoje, 1);
      dataDita = true;
    }
  }

  // Valor: o primeiro número que sobrou.
  final mv = _valor.firstMatch(resto);
  if (mv == null) return null;
  final valor = lerCentavos(mv.group(1)!);
  if (valor == null) return null;
  resto = resto.replaceRange(mv.start, mv.end, ' ');

  // Tipo.
  bool tem(List<String> palavras) => palavras.any((p) => resto.contains(' $p '));
  var tipo = 'saida';
  if (tem(_palavrasDeTransferencia)) {
    tipo = 'transferencia';
  } else if (tem(_palavrasDeEntrada)) {
    tipo = 'entrada';
  }
  final recorrente = tem(_palavrasDeRecorrencia);
  final efetivado = !(tem(_palavrasDeFuturo) || (dataDita && data.compareTo(ctx.hoje) > 0));

  // Contas citadas, na ordem em que aparecem.
  final achadas = acharContas(resto, ctx);
  final citadas = achadas.citadas;
  resto = achadas.resto;

  // Citou uma conta que não deu para decidir qual é: melhor perguntar do
  // que cair na conta padrão em silêncio.
  String? contaId = citadas.isNotEmpty ? citadas.first.$2.id : (achadas.ambigua ? null : ctx.contaPadraoId);
  String? destinoId;
  if (tipo == 'transferencia') {
    if (citadas.length >= 2) {
      destinoId = citadas[1].$2.id;
    } else if (citadas.length == 1 && ctx.contaPadraoId != null && ctx.contaPadraoId != citadas.first.$2.id) {
      // "guardei 200 na poupança": sai da conta padrão, entra na citada.
      contaId = ctx.contaPadraoId;
      destinoId = citadas.first.$2.id;
    } else {
      contaId = citadas.isNotEmpty ? citadas.first.$2.id : null;
    }
  }

  // Descrição: o que sobrou, sem as palavras de função.
  final palavras = resto
      .split(RegExp(r'[^a-z0-9]+'))
      .where((p) => p.length > 1 && !_ruido.contains(p))
      .where((p) => !_verbos.contains(p))
      .toList();
  var descricao = _descricaoOriginal(original, palavras);
  if (descricao.isEmpty) {
    descricao = switch (tipo) {
      'entrada' => 'Recebimento',
      'transferencia' => 'Transferência',
      _ => 'Gasto',
    };
  }

  // Categoria: nome citado, depois o que o histórico ensinou.
  String? categoriaId;
  if (tipo != 'transferencia') {
    final doTipo = ctx.categorias.where((c) => !c.arquivada && c.tipo == tipo).toList()
      ..sort((a, b) => b.nome.length.compareTo(a.nome.length));
    final texto = ' ${palavras.join(' ')} ';
    for (final c in doTipo) {
      if (texto.contains(' ${normalizar(c.nome)} ')) {
        categoriaId = c.id;
        break;
      }
    }
    if (categoriaId == null) {
      for (final p in palavras) {
        final aprendida = ctx.aprendido[p];
        if (aprendida != null && doTipo.any((c) => c.id == aprendida)) {
          categoriaId = aprendida;
          break;
        }
      }
    }
  }

  return Leitura(
    tipo: tipo,
    descricao: descricao,
    valorCentavos: valor,
    data: data,
    contaId: contaId,
    contaDestinoId: destinoId,
    categoriaId: categoriaId,
    parcelas: parcelas,
    recorrente: recorrente,
    efetivado: efetivado,
    original: original,
  );
}

/// Recupera as palavras da descrição com a grafia que a pessoa usou.
String _descricaoOriginal(String original, List<String> palavras) {
  final restantes = [...palavras];
  final saida = <String>[];
  for (final pedaco in original.split(RegExp(r'\s+'))) {
    final limpo = normalizar(pedaco).replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (limpo.isNotEmpty && restantes.contains(limpo)) {
      restantes.remove(limpo);
      saida.add(pedaco.replaceAll(RegExp(r'^[^\wÀ-ſ]+|[^\wÀ-ſ]+$'), ''));
    }
  }
  if (saida.isEmpty) return '';
  final texto = saida.join(' ');
  return '${texto[0].toUpperCase()}${texto.substring(1)}';
}

/// Lê um texto com uma linha por lançamento. Linhas sem valor ficam `null`
/// na posição correspondente.
List<(String, Leitura?)> lerTexto(String texto, ContextoDeLeitura ctx) => texto
    .split(RegExp(r'[\n;]+'))
    .map((l) => l.trim())
    .where((l) => l.isNotEmpty)
    .map((l) => (l, lerLinha(l, ctx)))
    .toList();

/// Palavra → categoria mais frequente, a partir de lançamentos já feitos.
Map<String, String> aprenderCategorias(Iterable<Lancamento> historico) {
  final contagem = <String, Map<String, int>>{};
  for (final l in historico) {
    final categoria = l.categoriaId;
    if (categoria == null || l.ehTransferencia) continue;
    for (final p in normalizar(l.descricao).split(RegExp(r'[^a-z0-9]+'))) {
      if (p.length < 3 || _ruido.contains(p)) continue;
      final porCategoria = contagem.putIfAbsent(p, () => {});
      porCategoria[categoria] = (porCategoria[categoria] ?? 0) + 1;
    }
  }
  return contagem.map((palavra, porCategoria) {
    final melhor = porCategoria.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return MapEntry(palavra, melhor.key);
  });
}
