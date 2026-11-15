import '../modelo/modelos.dart';
import 'distribuicao.dart';
import 'faturas.dart';
import 'formatos.dart';

/// A "foto" do mês que abre o app: quanto do que entra já tem destino, o
/// que ainda dá para gastar em cada categoria com limite e o que está
/// atrasado ou para vencer.

/// Do dinheiro que entra no mês, quanto já tem destino. Olha o caixa: o que
/// sai das contas (pago ou a pagar) e as faturas que vencem no mês. A parte
/// das faturas é a que se consegue ajustar gastando menos no cartão.
class Comprometimento {
  const Comprometimento({required this.entraCentavos, required this.contasCentavos, required this.faturasCentavos});

  /// Entradas do mês: o recebido mais o que ainda se espera receber.
  final int entraCentavos;

  /// Saídas do mês fora do cartão, pagas ou agendadas.
  final int contasCentavos;

  /// Faturas com vencimento no mês, com o que veio da anterior.
  final int faturasCentavos;

  int get comprometidoCentavos => contasCentavos + faturasCentavos;
  int get sobraCentavos => entraCentavos - comprometidoCentavos;

  /// Parte do que entra que já tem destino, em pontos percentuais. Nulo sem
  /// entrada para comparar.
  int? get percentual => entraCentavos <= 0 ? null : (comprometidoCentavos * 100 / entraCentavos).round();
}

Comprometimento calcularComprometimento({
  required String mes,
  required Iterable<Lancamento> lancamentos,
  required Map<String, Conta> contas,
  required Iterable<SituacaoDaFatura> faturas,
}) {
  var entra = 0;
  var sai = 0;
  for (final l in lancamentos) {
    if (l.ehTransferencia || l.situacao == 'cancelado') continue;
    // Vale o mês em que o dinheiro se move: o do pagamento, se já houve.
    if (!l.dia.startsWith(mes)) continue;
    if (l.ehEntrada) {
      entra += l.valorCentavos;
    } else if (!(contas[l.contaId]?.ehCartao ?? false)) {
      // Compra no cartão não sai do caixa agora: ela está dentro da fatura.
      sai += l.valorCentavos;
    }
  }
  var devidoEmFaturas = 0;
  for (final s in faturas) {
    if (s.fatura.vencimento.startsWith(mes) && s.devidoCentavos > 0) devidoEmFaturas += s.devidoCentavos;
  }
  return Comprometimento(entraCentavos: entra, contasCentavos: sai, faturasCentavos: devidoEmFaturas);
}

/// Quanto ainda dá numa categoria com limite (ou no resto do estilo de vida).
class Resto {
  const Resto({required this.categoriaId, required this.limiteCentavos, required this.gastoCentavos});

  /// Nulo para a linha "o resto do estilo de vida".
  final String? categoriaId;
  final int limiteCentavos;
  final int gastoCentavos;

  int get restaCentavos => limiteCentavos - gastoCentavos;
  bool get passou => gastoCentavos > limiteCentavos;
  bool get perto => !passou && limiteCentavos > 0 && gastoCentavos * 5 >= limiteCentavos * 4;
  double get fracao => limiteCentavos <= 0 ? 1 : (gastoCentavos / limiteCentavos).clamp(0.0, 1.0);
}

/// As categorias de saída com limite definido, as mais críticas primeiro:
/// quem passou, depois quem está perto, depois o resto pela parte usada.
List<Resto> restosPorCategoria(ResumoMes? resumo, Iterable<Categoria> categorias) {
  final restos = [
    for (final c in categorias)
      if (c.tipo == 'saida' && !c.arquivada && (c.limiteMensalCentavos ?? 0) > 0)
        Resto(categoriaId: c.id, limiteCentavos: c.limiteMensalCentavos!, gastoCentavos: resumo?.categorias[c.id]?.$2 ?? 0),
  ];
  int peso(Resto r) => r.passou ? 0 : (r.perto ? 1 : 2);
  restos.sort((a, b) {
    final porPeso = peso(a).compareTo(peso(b));
    return porPeso != 0 ? porPeso : b.fracao.compareTo(a.fracao);
  });
  return restos;
}

/// O que sobra do teto do estilo de vida para as categorias SEM limite
/// próprio: o teto do grupo menos os limites já dados às outras. Nulo quando
/// não há teto conhecido ou nenhuma categoria sem limite.
Resto? restoDoEstiloDeVida(ResumoMes? resumo, Iterable<Categoria> categorias, int? tetoDoGrupoCentavos) {
  if (tetoDoGrupoCentavos == null || tetoDoGrupoCentavos <= 0) return null;
  final doGrupo = categorias.where((c) => c.tipo == 'saida' && !c.arquivada && grupoDa(c) == 'conforto').toList();
  final semLimite = doGrupo.where((c) => (c.limiteMensalCentavos ?? 0) <= 0).toList();
  if (semLimite.isEmpty) return null;
  final jaDistribuido = doGrupo.fold<int>(0, (s, c) => s + ((c.limiteMensalCentavos ?? 0) > 0 ? c.limiteMensalCentavos! : 0));
  final limite = tetoDoGrupoCentavos - jaDistribuido;
  return Resto(
    categoriaId: null,
    limiteCentavos: limite < 0 ? 0 : limite,
    gastoCentavos: semLimite.fold<int>(0, (s, c) => s + (resumo?.categorias[c.id]?.$2 ?? 0)),
  );
}

/// A situação em uma frase, só quando há algo a dizer: quem passou do
/// limite, quem está perto, ou o mês comprometido além do que entra.
String? fraseDaSituacao(List<Resto> restos, Resto? estilo, Comprometimento comprometimento, String Function(String) nomeDe) {
  String lista(Iterable<Resto> rs) => rs.map((r) => r.categoriaId == null ? 'O resto do estilo de vida' : nomeDe(r.categoriaId!)).join(', ');
  final todos = [...restos, ?estilo];
  final passaram = todos.where((r) => r.passou).toList();
  final perto = todos.where((r) => r.perto).toList();
  if (comprometimento.entraCentavos > 0 && comprometimento.sobraCentavos < 0) {
    return 'O mês já tem ${reais(-comprometimento.sobraCentavos)} a mais de destino do que entra.';
  }
  if (passaram.isNotEmpty) {
    return '${lista(passaram)} ${passaram.length == 1 ? 'passou' : 'passaram'} do limite.'
        '${perto.isEmpty ? '' : ' ${lista(perto)} ${perto.length == 1 ? 'está' : 'estão'} perto.'}';
  }
  if (perto.isNotEmpty) return '${lista(perto)} ${perto.length == 1 ? 'está' : 'estão'} perto do limite.';
  return null;
}

/// O que está atrasado e o que vence nos próximos sete dias.
class Pendencias {
  const Pendencias(this.atrasados, this.proximos);
  final List<Lancamento> atrasados;
  final List<Lancamento> proximos;

  static int _aPagar(List<Lancamento> ls) => ls.fold<int>(0, (s, l) => s + (l.ehEntrada ? 0 : l.valorCentavos));
  int get atrasadoCentavos => _aPagar(atrasados);
  int get proximoCentavos => _aPagar(proximos);
}

Pendencias calcularPendencias(Iterable<Lancamento> previstos, String hoje) {
  final limite = somarDias(hoje, 7);
  final abertos = previstos.where((l) => l.previsto).toList()..sort((a, b) => a.data.compareTo(b.data));
  return Pendencias(
    [for (final l in abertos) if (l.data.compareTo(hoje) < 0) l],
    [for (final l in abertos) if (l.data.compareTo(hoje) >= 0 && l.data.compareTo(limite) <= 0) l],
  );
}
