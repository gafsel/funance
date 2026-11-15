import 'dart:convert';

import '../modelo/modelos.dart';
import 'formatos.dart';
import 'leitura_frase.dart';

/// Uma linha de extrato ou planilha, já lida, antes de virar item da caixa
/// de entrada.
class ItemImportado {
  const ItemImportado({
    required this.id,
    required this.descricao,
    required this.valorCentavos,
    required this.data,
    required this.tipo,
  });

  /// Estável para a mesma linha: importar o mesmo arquivo duas vezes não
  /// duplica nada.
  final String id;
  final String descricao;

  /// Sempre positivo; o sentido está em `tipo`.
  final int valorCentavos;
  final String data;

  /// `entrada` ou `saida`.
  final String tipo;
}

class ResultadoDaImportacao {
  const ResultadoDaImportacao(this.itens, this.ignoradas, this.formato);
  final List<ItemImportado> itens;

  /// Linhas que não foram entendidas (cabeçalhos repetidos, totais, lixo).
  final int ignoradas;
  final String formato;
}

String _idEstavel(String contaId, String data, int valorComSinal, String descricao, int repeticao) {
  // FNV-1a de 32 bits em duas passadas: suficiente para um id sem colisão
  // prática dentro de uma conta, sem depender de pacote de hash.
  int fnv(String s, int semente) {
    var h = semente;
    for (final c in utf8.encode(s)) {
      h ^= c;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    return h;
  }

  final base = '$contaId|$data|$valorComSinal|${normalizar(descricao)}|$repeticao';
  return 'imp-${fnv(base, 0x811C9DC5).toRadixString(16).padLeft(8, '0')}'
      '${fnv(base, 0x01234567).toRadixString(16).padLeft(8, '0')}';
}

/// Lê o texto de um arquivo OFX, CSV ou de uma tabela colada.
ResultadoDaImportacao lerExtrato(String texto, {required String contaId, required String hoje}) {
  final ofx = texto.contains('<STMTTRN>') || texto.contains('<OFX>');
  final brutos = ofx ? _lerOfx(texto) : _lerTabela(texto, hoje);
  final repeticoes = <String, int>{};
  final itens = <ItemImportado>[];
  for (final (data, valor, descricao, fitid) in brutos.$1) {
    final chave = '$data|$valor|${normalizar(descricao)}';
    final n = repeticoes[chave] = (repeticoes[chave] ?? 0) + 1;
    itens.add(ItemImportado(
      id: fitid != null ? 'imp-$contaId-${fitid.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '')}' : _idEstavel(contaId, data, valor, descricao, n),
      descricao: descricao,
      valorCentavos: valor.abs(),
      data: data,
      tipo: valor < 0 ? 'saida' : 'entrada',
    ));
  }
  return ResultadoDaImportacao(itens, brutos.$2, ofx ? 'OFX' : 'planilha');
}

typedef _Bruto = (String data, int valorComSinal, String descricao, String? fitid);

(List<_Bruto>, int) _lerOfx(String texto) {
  final itens = <_Bruto>[];
  var ignoradas = 0;
  String? campo(String bloco, String nome) =>
      RegExp('<$nome>([^<\\r\\n]*)', caseSensitive: false).firstMatch(bloco)?.group(1)?.trim();

  for (final m in RegExp(r'<STMTTRN>([\s\S]*?)(?:</STMTTRN>|(?=<STMTTRN>)|$)', caseSensitive: false).allMatches(texto)) {
    final bloco = m.group(1)!;
    final dia = campo(bloco, 'DTPOSTED');
    final valor = campo(bloco, 'TRNAMT');
    final centavos = valor == null ? null : _valorComSinal(valor.replaceAll(',', '.'), pontoDecimal: true);
    if (dia == null || dia.length < 8 || centavos == null || centavos == 0) {
      ignoradas++;
      continue;
    }
    itens.add((
      '${dia.substring(0, 4)}-${dia.substring(4, 6)}-${dia.substring(6, 8)}',
      centavos,
      campo(bloco, 'MEMO') ?? campo(bloco, 'NAME') ?? 'Sem descrição',
      campo(bloco, 'FITID'),
    ));
  }
  return (itens, ignoradas);
}

int? _valorComSinal(String texto, {bool pontoDecimal = false}) {
  var t = texto.trim().replaceAll(RegExp(r'[Rr]\$|\s'), '');
  if (t.isEmpty) return null;
  var negativo = false;
  if (t.startsWith('(') && t.endsWith(')')) {
    negativo = true;
    t = t.substring(1, t.length - 1);
  }
  if (t.startsWith('-') || t.endsWith('-')) {
    negativo = true;
    t = t.replaceAll('-', '');
  }
  t = t.replaceAll('+', '');
  if (!RegExp(r'^\d[\d.,]*$').hasMatch(t)) return null;
  int? centavos;
  if (pontoDecimal) {
    final v = double.tryParse(t);
    centavos = v == null ? null : (v * 100).round();
  } else {
    centavos = lerCentavos(t);
    if (centavos == null && RegExp(r'^0+([.,]0+)?$').hasMatch(t)) centavos = 0;
  }
  if (centavos == null) return null;
  return negativo ? -centavos : centavos;
}

String? _dataDe(String texto, String hoje) {
  final t = texto.trim();
  var m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(t);
  if (m != null) return '${m.group(1)}-${m.group(2)}-${m.group(3)}';
  m = RegExp(r'^(\d{1,2})[/.-](\d{1,2})(?:[/.-](\d{2,4}))?$').firstMatch(t);
  if (m == null) return null;
  final dia = int.parse(m.group(1)!);
  final mes = int.parse(m.group(2)!);
  var ano = m.group(3) == null ? int.parse(hoje.substring(0, 4)) : int.parse(m.group(3)!);
  if (ano < 100) ano += 2000;
  if (mes < 1 || mes > 12 || dia < 1 || dia > 31) return null;
  return '$ano-${doisDigitos(mes)}-${doisDigitos(dia)}';
}

List<String> _colunas(String linha, String separador) {
  final colunas = <String>[];
  final atual = StringBuffer();
  var entreAspas = false;
  for (var i = 0; i < linha.length; i++) {
    final c = linha[i];
    if (c == '"') {
      if (entreAspas && i + 1 < linha.length && linha[i + 1] == '"') {
        atual.write('"');
        i++;
      } else {
        entreAspas = !entreAspas;
      }
    } else if (c == separador && !entreAspas) {
      colunas.add(atual.toString().trim());
      atual.clear();
    } else {
      atual.write(c);
    }
  }
  colunas.add(atual.toString().trim());
  return colunas;
}

/// Tabela em texto: CSV com `;` ou `,`, ou células coladas de planilha
/// (separadas por tabulação). As colunas são descobertas pelo conteúdo:
/// a primeira que parece data, as que parecem valor, e o maior texto.
(List<_Bruto>, int) _lerTabela(String texto, String hoje) {
  final linhas = texto.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();
  if (linhas.isEmpty) return (const [], 0);

  final amostra = linhas.take(10).join('\n');
  final separador = amostra.contains('\t')
      ? '\t'
      : (';'.allMatches(amostra).length >= ','.allMatches(amostra).length ? ';' : ',');

  // Cabeçalho com "crédito"/"débito" separados: o débito entra negativo.
  final cabecalho = _colunas(linhas.first, separador).map(normalizar).toList();
  final colunaDebito = cabecalho.indexWhere((c) => c.contains('debito') || c.contains('saida'));
  final colunaCredito = cabecalho.indexWhere((c) => c.contains('credito') || c.contains('entrada'));

  final itens = <_Bruto>[];
  var ignoradas = 0;
  for (final linha in linhas) {
    final colunas = _colunas(linha, separador);
    String? data;
    int? valor;
    var descricao = '';
    for (var i = 0; i < colunas.length; i++) {
      final celula = colunas[i];
      if (celula.isEmpty) continue;
      final comoData = data == null ? _dataDe(celula, hoje) : null;
      if (comoData != null) {
        data = comoData;
        continue;
      }
      final comoValor = RegExp(r'[A-Za-zÀ-ÿ]{2,}').hasMatch(celula.replaceAll(RegExp(r'[Rr]\$'), '')) ? null : _valorComSinal(celula);
      if (comoValor != null) {
        // Com colunas de débito e crédito, a de débito manda o sinal. Sem
        // elas, vale o último valor não nulo da linha (o "saldo" costuma vir
        // depois e é descartado por estar numa coluna chamada saldo).
        if (i < cabecalho.length && cabecalho[i].contains('saldo')) continue;
        if (comoValor == 0) continue;
        valor ??= i == colunaDebito ? -comoValor.abs() : (i == colunaCredito ? comoValor.abs() : comoValor);
        continue;
      }
      if (celula.length > descricao.length) descricao = celula;
    }
    if (data == null || valor == null) {
      ignoradas++;
      continue;
    }
    itens.add((data, valor, descricao.isEmpty ? 'Sem descrição' : descricao, null));
  }
  return (itens, ignoradas);
}

/// Sugestão de categoria para um texto de extrato: primeiro as regras da
/// pessoa (a mais específica ganha), depois o que o histórico ensinou.
String? sugerirCategoria(
  String descricao,
  String tipo, {
  required List<Regra> regras,
  required Map<String, String> aprendido,
  required List<Categoria> categorias,
}) {
  final validas = {for (final c in categorias) if (!c.arquivada && c.tipo == tipo) c.id};
  // Extrato vem cheio de pontuação ("UBER *EATS"): compara só letras e
  // números, separados por um espaço.
  String simples(String t) => ' ${normalizar(t).replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim()} ';
  final texto = simples(descricao);
  final ordenadas = [...regras]..sort((a, b) => b.texto.length.compareTo(a.texto.length));
  for (final r in ordenadas) {
    if (r.texto.trim().isNotEmpty && texto.contains(simples(r.texto)) && validas.contains(r.categoriaId)) {
      return r.categoriaId;
    }
  }
  for (final palavra in texto.split(RegExp(r'[^a-z0-9]+'))) {
    final id = aprendido[palavra];
    if (id != null && validas.contains(id)) return id;
  }
  return null;
}

/// Lançamento já existente que parece ser o mesmo item do extrato: mesma
/// conta, mesmo valor e data a até três dias. Evita lançar em dobro o que
/// a pessoa já tinha anotado ou agendado.
Lancamento? acharCorrespondente(ItemEntrada item, Iterable<Lancamento> lancamentos, {Set<String> usados = const {}}) {
  Lancamento? melhor;
  var menorDistancia = 4;
  for (final l in lancamentos) {
    if (usados.contains(l.id) || l.situacao == 'cancelado') continue;
    if (l.valorCentavos != item.valorCentavos) continue;
    final naConta = item.tipo == 'entrada'
        ? (l.ehEntrada && l.contaId == item.contaId) || (l.ehTransferencia && l.contaDestinoId == item.contaId)
        : (!l.ehEntrada && l.contaId == item.contaId);
    if (!naConta) continue;
    final distancia = diaDaChave(l.dia).difference(diaDaChave(item.data)).inDays.abs();
    if (distancia < menorDistancia) {
      menorDistancia = distancia;
      melhor = l;
    }
  }
  return melhor;
}

/// Linhas devolvidas pela leitura de um PDF, postas no formato de tabela que
/// `lerExtrato` já entende (`dd/mm/aaaa`, descrição, valor com sinal). Assim o
/// PDF segue o mesmo caminho do CSV: a pessoa vê o que foi lido antes de
/// mandar para a caixa de entrada.
String tabelaDoDocumento(Iterable<Object?> linhas) {
  final saida = StringBuffer();
  for (final bruta in linhas) {
    if (bruta is! Map) continue;
    final data = bruta['data'];
    final descricao = bruta['descricao'];
    final valor = bruta['valorCentavos'];
    final tipo = bruta['tipo'];
    if (data is! String || data.length != 10 || descricao is! String || valor is! num || valor <= 0) continue;
    if (tipo != 'entrada' && tipo != 'saida') continue;
    final centavos = valor.round();
    final texto = '${centavos ~/ 100},${doisDigitos(centavos % 100)}';
    saida.writeln([
      '${data.substring(8, 10)}/${data.substring(5, 7)}/${data.substring(0, 4)}',
      descricao.replaceAll(RegExp(r'[\t\r\n]+'), ' ').trim(),
      tipo == 'saida' ? '-$texto' : texto,
    ].join('\t'));
  }
  return saida.toString();
}
