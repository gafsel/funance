import '../modelo/modelos.dart';
import 'faturas.dart';
import 'formatos.dart';
import 'importar.dart';
import 'leitura_frase.dart';

/// Conferência guiada: percorrer as contas e os cartões na ordem em que a
/// pessoa confere no banco, achar o dia em que um saldo deixa de bater e
/// comparar uma fatura item a item.

/// As contas que entram na conferência, na ordem de conferir: primeiro as
/// de quem está usando, depois as conjuntas, depois as dos outros; dentro de
/// cada grupo, por banco; dentro do banco, o cartão antes da conta (o
/// pagamento da fatura sai da conta, então a fatura é conferida primeiro).
List<Conta> roteiroDaConferencia(Iterable<Conta> contas, String? euId) {
  const tipos = {'cartao', 'corrente', 'dinheiro', 'investimento'};
  int titular(Conta c) => c.donos.isEmpty || c.conjunta ? 1 : (c.donos.contains(euId) ? 0 : 2);
  final lista = contas.where((c) => !c.arquivada && tipos.contains(c.tipo)).toList();
  lista.sort((a, b) {
    final porTitular = titular(a).compareTo(titular(b));
    if (porTitular != 0) return porTitular;
    // Dentro de "dos outros", cada pessoa junta.
    final porDono = (a.donos.isEmpty ? '' : a.donos.first).compareTo(b.donos.isEmpty ? '' : b.donos.first);
    if (titular(a) == 2 && porDono != 0) return porDono;
    final porBanco = (a.banco ?? '~').compareTo(b.banco ?? '~');
    if (porBanco != 0) return porBanco;
    final porTipo = (a.ehCartao ? 0 : 1).compareTo(b.ehCartao ? 0 : 1);
    return porTipo != 0 ? porTipo : a.nome.compareTo(b.nome);
  });
  return lista;
}

/// As faturas de um cartão que entram na conferência, da mais antiga para
/// a mais nova: as que já fecharam e ainda não foram pagas, e a que está
/// aberta. Entre o fechamento de uma fatura e o pagamento dela as duas
/// precisam ser olhadas: a fechada para acertar o valor do pagamento, a
/// aberta porque as compras novas já caem nela.
List<SituacaoDaFatura> faturasParaConferir(Map<String, SituacaoDaFatura> situacoes, String cartaoId) {
  final doCartao = situacoes.values.where((s) => s.fatura.contaId == cartaoId).toList()
    ..sort((a, b) => a.fatura.vencimento.compareTo(b.fatura.vencimento));
  final lista = [
    ...doCartao.where((s) => s.pendente && s.aPagarCentavos > 0),
    // A aberta de agora: a primeira que ainda não fechou.
    ?doCartao.where((s) => s.aberta).firstOrNull,
  ];
  if (lista.isNotEmpty) return lista;
  final destaque = faturaEmDestaque(situacoes, cartaoId);
  return [?destaque];
}

/// Há quantos dias a conta foi conferida; nulo se nunca foi.
int? diasSemConferir(Conta conta, String hoje) =>
    conta.conferidoAte == null ? null : diaDaChave(hoje).difference(diaDaChave(conta.conferidoAte!)).inDays;

/// O saldo com que a conta fechou cada dia, de [desde] até [hoje], andando
/// para trás a partir do saldo de hoje. [movimentoPorDia] é o quanto a
/// conta variou em cada dia (positivo entrou, negativo saiu).
Map<String, int> saldosNoFimDeCadaDia({
  required int saldoHoje,
  required String hoje,
  required String desde,
  required Map<String, int> movimentoPorDia,
}) {
  final saldos = <String, int>{};
  var saldo = saldoHoje;
  for (var dia = hoje; dia.compareTo(desde) >= 0; dia = somarDias(dia, -1)) {
    saldos[dia] = saldo;
    saldo -= movimentoPorDia[dia] ?? 0;
  }
  return saldos;
}

/// O dia a perguntar em seguida na busca da diferença: o do meio entre o
/// último dia em que o saldo bate e o primeiro em que não bate. Nulo quando
/// os dois são vizinhos: a diferença está no dia que não bate.
String? diaDoMeio(String bate, String naoBate) {
  final distancia = diaDaChave(naoBate).difference(diaDaChave(bate)).inDays;
  return distancia <= 1 ? null : somarDias(bate, distancia ~/ 2);
}

/// O resultado de comparar as compras de uma fatura no app com a fatura do
/// banco, item a item.
class ComparacaoDeFatura {
  const ComparacaoDeFatura({required this.iguais, required this.valorDiferente, required this.soNoBanco, required this.soNoApp});

  /// Batem em valor.
  final List<(Lancamento, ItemImportado)> iguais;

  /// É a mesma compra, mas o valor difere (centavos de parcela, na maioria).
  final List<(Lancamento, ItemImportado)> valorDiferente;
  final List<ItemImportado> soNoBanco;
  final List<Lancamento> soNoApp;

  bool get bate => valorDiferente.isEmpty && soNoBanco.isEmpty && soNoApp.isEmpty;
}

int _naFatura(Lancamento l) => l.ehEntrada ? -l.valorCentavos : l.valorCentavos;
int _doBanco(ItemImportado i) => i.tipo == 'entrada' ? -i.valorCentavos : i.valorCentavos;

Set<String> _palavras(String texto) => {
      for (final p in normalizar(texto).split(RegExp(r'[^a-z0-9]+')))
        if (p.length >= 3 && int.tryParse(p) == null) p,
    };

/// Compara as compras do app com as linhas da fatura do banco.
///
/// Primeiro casa o que tem o mesmo valor; depois, entre o que sobrou, o que
/// tem valor quase igual (até R$ 1,00 ou 2% de diferença). A data só decide
/// em compra à vista, e com folga de quatro dias: parcela aparece na fatura
/// do banco com a data da compra original, não a do mês.
ComparacaoDeFatura compararFatura(List<Lancamento> compras, List<ItemImportado> doBanco) {
  final restamDoApp = [...compras];
  final restamDoBanco = [...doBanco];
  final iguais = <(Lancamento, ItemImportado)>[];
  final diferentes = <(Lancamento, ItemImportado)>[];

  int distancia(Lancamento l, ItemImportado i) => diaDaChave(l.dia).difference(diaDaChave(i.data)).inDays.abs();
  bool datasCombinam(Lancamento l, ItemImportado i) => l.parcelaNumero != null || l.serieId != null || distancia(l, i) <= 4;
  // Menor é melhor: palavra em comum pesa mais que a data próxima.
  int nota(Lancamento l, ItemImportado i) =>
      (_palavras(l.descricao).intersection(_palavras(i.descricao)).isEmpty ? 1000 : 0) + distancia(l, i).clamp(0, 999);

  void casar(bool Function(Lancamento, ItemImportado) serve, List<(Lancamento, ItemImportado)> destino) {
    for (final item in [...restamDoBanco]) {
      Lancamento? melhor;
      for (final l in restamDoApp) {
        if (!serve(l, item) || !datasCombinam(l, item)) continue;
        if (melhor == null || nota(l, item) < nota(melhor, item)) melhor = l;
      }
      if (melhor == null) continue;
      destino.add((melhor, item));
      restamDoApp.remove(melhor);
      restamDoBanco.remove(item);
    }
  }

  casar((l, i) => _naFatura(l) == _doBanco(i), iguais);
  casar((l, i) {
    final a = _naFatura(l), b = _doBanco(i);
    if (a.sign != b.sign) return false;
    final diferenca = (a - b).abs();
    return diferenca <= 100 || diferenca * 50 <= a.abs();
  }, diferentes);

  return ComparacaoDeFatura(iguais: iguais, valorDiferente: diferentes, soNoBanco: restamDoBanco, soNoApp: restamDoApp);
}
