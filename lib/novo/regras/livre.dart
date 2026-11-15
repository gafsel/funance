import '../modelo/modelos.dart';
import 'formatos.dart';

/// O número central do app: quanto ainda dá para gastar neste mês sem furar
/// os compromissos nem as metas.
///
///   livre = renda do mês − compromissos − parcela das metas − já gasto
///
/// - renda: entradas do mês (o realizado quando já entrou, o previsto senão);
/// - compromissos: saídas com data marcada (previstas) e as que vêm de série
///   (aluguel, assinatura, parcela), pagas ou não;
/// - já gasto: saídas avulsas efetivadas.
///
/// Transferência não conta: o dinheiro só mudou de conta.
class LivreParaGastar {
  const LivreParaGastar({
    required this.rendaCentavos,
    required this.compromissosCentavos,
    required this.metasCentavos,
    required this.gastoCentavos,
    required this.diasRestantes,
  });

  final int rendaCentavos;
  final int compromissosCentavos;
  final int metasCentavos;
  final int gastoCentavos;

  /// Contando hoje.
  final int diasRestantes;

  int get livreCentavos =>
      rendaCentavos - compromissosCentavos - metasCentavos - gastoCentavos;

  int get porDiaCentavos =>
      livreCentavos <= 0 ? 0 : livreCentavos ~/ (diasRestantes < 1 ? 1 : diasRestantes);

  /// A conta em uma frase, para quem quiser entender o número.
  String get explicacao {
    if (rendaCentavos == 0) {
      return 'Ainda não há renda lançada neste mês. Lance o que você espera receber para o número fazer sentido.';
    }
    final partes = <String>[
      'De ${reais(rendaCentavos)} de renda',
      if (compromissosCentavos > 0) '${reais(compromissosCentavos)} são contas do mês',
      if (metasCentavos > 0) '${reais(metasCentavos)} vão para as metas',
      if (gastoCentavos > 0) '${reais(gastoCentavos)} já foram gastos',
    ];
    return '${partes.join(', ')}.';
  }
}

LivreParaGastar calcularLivre({
  required String hoje,
  required Iterable<Lancamento> lancamentos,
  required Iterable<Meta> metas,
}) {
  final mes = hoje.substring(0, 7);
  var renda = 0;
  var compromissos = 0;
  var gasto = 0;

  for (final l in lancamentos) {
    if (l.situacao == 'cancelado' || l.ehTransferencia) continue;
    // Efetivado conta no mês em que aconteceu; previsto, no do vencimento.
    final noMes = l.efetivado ? l.dia.startsWith(mes) : l.data.startsWith(mes);
    if (!noMes) continue;

    if (l.ehEntrada) {
      renda += l.valorCentavos;
    } else if (!l.efetivado || l.serieId != null) {
      compromissos += l.valorCentavos;
    } else {
      gasto += l.valorCentavos;
    }
  }

  final parcelaDasMetas = metas
      .where((m) => m.emAberto)
      .fold<int>(0, (soma, m) => soma + (m.parcelaMensalCentavos ?? 0));

  return LivreParaGastar(
    rendaCentavos: renda,
    compromissosCentavos: compromissos,
    metasCentavos: parcelaDasMetas,
    gastoCentavos: gasto,
    diasRestantes: diasNoMes(mes) - int.parse(hoje.substring(8, 10)) + 1,
  );
}

/// Saldo de uma conta no fim de `hoje`: saldo inicial, mais os meses
/// anteriores (resumos do servidor), mais o que já aconteceu neste mês.
int saldoDaConta({
  required Conta conta,
  required String hoje,
  required Iterable<ResumoMes> resumos,
  required Iterable<Lancamento> lancamentosDoMes,
}) {
  final mes = hoje.substring(0, 7);
  final inicial = conta.saldoInicialData;
  var saldo = inicial == null || inicial.compareTo(hoje) <= 0 ? conta.saldoInicialCentavos : 0;

  for (final r in resumos) {
    if (r.mes.compareTo(mes) < 0) saldo += r.deltaPorConta[conta.id] ?? 0;
  }
  for (final l in lancamentosDoMes) {
    final dia = l.dataEfetiva;
    if (!l.efetivado || dia == null || l.realizadoCentavos == null) continue;
    if (!dia.startsWith(mes) || dia.compareTo(hoje) > 0) continue;
    final valor = l.realizadoCentavos!;
    if (l.contaId == conta.id) saldo += l.ehEntrada ? valor : -valor;
    if (l.ehTransferencia && l.contaDestinoId == conta.id) saldo += valor;
  }
  return saldo;
}
