import '../modelo/modelos.dart';
import 'leitura_frase.dart';

/// Contas citadas numa frase, na ordem em que aparecem.
///
/// O problema que isto resolve: duas pessoas com conta e cartão no mesmo
/// banco. "nubank" pode ser quatro contas. A frase desempata por três pistas:
/// - o tipo: "cartão", "crédito" → cartão; "conta", "corrente" → conta;
/// - o titular: "meu", "minha" → quem está lançando; "da Bárbara" → ela;
///   "conjunta", "nossa" → conta de dois titulares;
/// - na falta de pista: o banco sozinho é a conta, não o cartão; e entre
///   contas iguais, a de quem está lançando.
///
/// Se nem assim sobrar uma só, a conta fica em aberto (`ambigua`) e a tela
/// pergunta. Adivinhar aqui é lançar na conta da outra pessoa.
({List<(int, Conta)> citadas, String resto, bool ambigua}) acharContas(String texto, ContextoDeLeitura ctx) {
  final palavras = texto.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  final limpas = [for (final p in palavras) p.replaceAll(RegExp(r'[^a-z0-9]'), '')];
  final ativas = ctx.contas.where((c) => !c.arquivada).toList();
  final consumidas = <int>{};

  List<String> partes(String? s) =>
      s == null ? const [] : normalizar(s).split(RegExp(r'[^a-z0-9]+')).where((p) => p.isNotEmpty).toList();

  // Menções: sequência exata do nome ou do apelido; senão, uma palavra-chave.
  final mencoes = <({int inicio, int fim, List<Conta> candidatas, List<Conta> amplas, bool exata})>[];
  List<Conta> porChave(String palavra) => [
        for (final conta in ativas)
          if ({...partes(conta.nome), ...partes(conta.apelido), ...partes(conta.banco)}.contains(palavra)) conta,
      ];
  var i = 0;
  while (i < limpas.length) {
    var tamanho = 0;
    var exatas = <Conta>[];
    for (final conta in ativas) {
      for (final sequencia in [partes(conta.apelido), partes(conta.nome)]) {
        if (sequencia.isEmpty || i + sequencia.length > limpas.length) continue;
        var bate = true;
        for (var k = 0; k < sequencia.length; k++) {
          if (limpas[i + k] != sequencia[k]) {
            bate = false;
            break;
          }
        }
        if (!bate) continue;
        if (sequencia.length > tamanho) {
          tamanho = sequencia.length;
          exatas = [conta];
        } else if (sequencia.length == tamanho && !exatas.contains(conta)) {
          exatas.add(conta);
        }
      }
    }
    if (tamanho > 0) {
      // As "amplas" são todas as contas do mesmo banco: valem quando a
      // frase diz um tipo que o nome exato não tem ("nubank crédito").
      final amplas = {...exatas, for (var k = i; k < i + tamanho; k++) ...porChave(limpas[k])}.toList();
      mencoes.add((inicio: i, fim: i + tamanho, candidatas: exatas, amplas: amplas, exata: true));
      i += tamanho;
      continue;
    }
    final palavra = limpas[i];
    if (palavra.length >= 3 && !_genericas.contains(palavra)) {
      final achadas = porChave(palavra);
      if (achadas.isNotEmpty) mencoes.add((inicio: i, fim: i + 1, candidatas: achadas, amplas: achadas, exata: false));
    }
    i++;
  }

  final nomes = {
    for (final m in ctx.membros)
      if (normalizar(m.primeiroNome).length >= 3) normalizar(m.primeiroNome): m.uid,
  };
  bool emMencao(int k) => mencoes.any((m) => k >= m.inicio && k < m.fim);

  /// Pistas de tipo e de titular numa janela de palavras.
  ({String? tipo, String? dono, bool conjunta, List<int> usadas}) pistas(Iterable<int> janela) {
    String? tipo;
    String? dono;
    var conjunta = false;
    final usadas = <int>[];
    for (final k in janela) {
      if (k < 0 || k >= limpas.length || emMencao(k)) continue;
      final p = limpas[k];
      if (_deCartao.contains(p)) {
        tipo = 'cartao';
        usadas.add(k);
      } else if (_deConta.contains(p)) {
        tipo ??= 'uso';
        usadas.add(k);
      } else if (_deInvestimento.contains(p)) {
        tipo ??= 'investimento';
        usadas.add(k);
      } else if (p == 'meu' || p == 'minha') {
        dono ??= ctx.euId;
        usadas.add(k);
      } else if (p == 'conjunta' || p == 'nossa' || p == 'nosso') {
        conjunta = true;
        usadas.add(k);
      } else if (nomes.containsKey(p) && k > 0 && _de.contains(limpas[k - 1])) {
        dono = nomes[p];
        usadas
          ..add(k)
          ..add(k - 1);
      }
    }
    return (tipo: tipo, dono: dono, conjunta: conjunta, usadas: usadas);
  }

  Conta? decidir(
    List<Conta> candidatas,
    bool exata,
    ({String? tipo, String? dono, bool conjunta, List<int> usadas}) p, {
    List<Conta>? amplas,
  }) {
    var c = candidatas;
    // O tipo dito na frase manda mais do que o nome exato.
    bool doTipo(Conta x) => switch (p.tipo) {
          'cartao' => x.ehCartao,
          'uso' => x.ehDeUso,
          'investimento' => x.tipo == 'investimento',
          _ => true,
        };
    if (p.tipo != null && amplas != null && !c.any(doTipo) && amplas.any(doTipo)) c = amplas;
    List<Conta> estreitar(bool Function(Conta) teste) {
      final f = c.where(teste).toList();
      return f.isEmpty ? c : f;
    }

    if (p.tipo == 'cartao') {
      c = estreitar((x) => x.ehCartao);
    } else if (p.tipo == 'uso') {
      c = estreitar((x) => x.ehDeUso);
    } else if (p.tipo == 'investimento') {
      c = estreitar((x) => x.tipo == 'investimento');
    } else if (!exata) {
      // Só o banco, sem dizer "cartão": é a conta.
      c = estreitar((x) => !x.ehCartao);
    }
    if (p.conjunta) c = estreitar((x) => x.conjunta);
    if (p.dono != null) {
      c = estreitar((x) => x.donos.contains(p.dono) && !x.conjunta);
      c = estreitar((x) => x.donos.contains(p.dono));
    } else if (c.length > 1 && ctx.euId != null && !p.conjunta) {
      final soMinhas = c.where((x) => x.donos.length == 1 && x.donos.single == ctx.euId).toList();
      final minhas = c.where((x) => x.donos.contains(ctx.euId)).toList();
      if (soMinhas.length == 1) {
        c = soMinhas;
      } else if (minhas.length == 1) {
        c = minhas;
      }
    }
    return c.length == 1 ? c.single : null;
  }

  final citadas = <(int, Conta)>[];
  var ambigua = false;
  for (var n = 0; n < mencoes.length; n++) {
    final m = mencoes[n];
    // Com uma menção só, a frase inteira dá pista; com duas (transferência),
    // cada uma olha só a sua vizinhança.
    final janela = mencoes.length == 1
        ? Iterable<int>.generate(limpas.length)
        : [for (var k = m.inicio - 4; k < m.inicio; k++) k, for (var k = m.fim; k < m.fim + 3; k++) k]
            .where((k) => !(n + 1 < mencoes.length && k >= mencoes[n + 1].inicio) && !(n > 0 && k < mencoes[n - 1].fim));
    final p = pistas(janela);
    final conta = decidir(m.candidatas, m.exata, p, amplas: m.amplas);
    consumidas
      ..addAll([for (var k = m.inicio; k < m.fim; k++) k])
      ..addAll(p.usadas);
    if (conta == null) {
      ambigua = true;
    } else if (!citadas.any((x) => x.$2.id == conta.id)) {
      citadas.add((m.inicio, conta));
    }
  }

  // Nenhuma conta citada pelo nome, mas a frase diz "cartão" ou "conta":
  // o titular e o tipo podem bastar ("no cartão da Bárbara").
  if (mencoes.isEmpty) {
    final p = pistas(Iterable<int>.generate(limpas.length));
    if (p.tipo != null || p.conjunta) {
      final conta = decidir(ativas, true, p);
      if (conta != null) {
        citadas.add((p.usadas.isEmpty ? 0 : p.usadas.reduce((a, b) => a < b ? a : b), conta));
        consumidas.addAll(p.usadas);
      } else if (p.tipo == 'cartao' || p.dono != null) {
        ambigua = true;
        consumidas.addAll(p.usadas);
      }
    }
  }

  final resto = [
    for (var k = 0; k < palavras.length; k++)
      if (!consumidas.contains(k)) palavras[k],
  ].join(' ');
  return (citadas: citadas, resto: ' $resto ', ambigua: ambigua);
}

const _genericas = {
  'cartao', 'conta', 'banco', 'credito', 'debito', 'corrente', 'conjunta', 'meu', 'minha', 'para', 'por', 'dia',
};
const _deCartao = {'cartao', 'credito'};
const _deConta = {'conta', 'corrente', 'debito'};
const _deInvestimento = {'poupanca', 'investimento', 'investimentos'};
const _de = {'da', 'do', 'de'};
