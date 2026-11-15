import '../modelo/modelos.dart';
import 'formatos.dart';

/// Quanto de uma meta já foi alcançado e o que falta por mês.
class ProgressoDaMeta {
  const ProgressoDaMeta({
    required this.atualCentavos,
    required this.alvoCentavos,
    required this.mesesRestantes,
    required this.parcelaNecessariaCentavos,
    this.menorEhMelhor = false,
  });

  final int atualCentavos;
  final int alvoCentavos;
  final int mesesRestantes;

  /// Quanto guardar (ou pagar) por mês para chegar no prazo.
  final int parcelaNecessariaCentavos;

  /// Metas de reduzir gasto: o alvo é um teto, não um destino.
  final bool menorEhMelhor;

  double get fracao => alvoCentavos <= 0 ? 0 : (atualCentavos / alvoCentavos).clamp(0, 1).toDouble();
  bool get atingida => menorEhMelhor ? atualCentavos <= alvoCentavos : atualCentavos >= alvoCentavos;
  int get faltaCentavos => (alvoCentavos - atualCentavos).clamp(0, alvoCentavos);
}

/// Meses inteiros de `hoje` até o prazo, contando o mês corrente.
int mesesAte(String hoje, String prazo) {
  if (prazo.compareTo(hoje) <= 0) return 0;
  final a = int.parse(hoje.substring(0, 4)) * 12 + int.parse(hoje.substring(5, 7));
  final b = int.parse(prazo.substring(0, 4)) * 12 + int.parse(prazo.substring(5, 7));
  return (b - a).clamp(1, 1200);
}

ProgressoDaMeta progressoDaMeta(
  Meta meta, {
  required String hoje,
  required Map<String, Conta> contas,
  required Map<String, int> saldos,
  required Iterable<ResumoMes> resumos,
}) {
  final mesInicio = meta.inicio.substring(0, 7);
  final mesPrazo = meta.prazo.substring(0, 7);
  final meses = mesesAte(hoje, meta.prazo);
  var atual = 0;
  var menorEhMelhor = false;

  int movimentoDesdeOInicio(String contaId) => resumos
      .where((r) => r.mes.compareTo(mesInicio) >= 0 && r.mes.compareTo(hoje.substring(0, 7)) <= 0)
      .fold<int>(0, (s, r) => s + (r.deltaPorConta[contaId] ?? 0));

  final conta = contas[meta.contaId];
  switch (meta.tipo) {
    case 'reduzirGasto':
      menorEhMelhor = true;
      atual = resumos
          .where((r) => r.mes.compareTo(mesInicio) >= 0 && r.mes.compareTo(mesPrazo) <= 0)
          .fold<int>(0, (s, r) => s + (r.categorias[meta.categoriaId]?.$2 ?? 0));
    case 'reduzirCartao':
      menorEhMelhor = true;
      atual = conta == null ? 0 : -movimentoDesdeOInicio(conta.id);
    case 'quitar':
      // Dívida diminui quando o saldo (negativo) sobe.
      atual = conta == null ? 0 : movimentoDesdeOInicio(conta.id).clamp(0, 9007199254740991);
    default:
      // Juntar: com conta de investimento ligada, o progresso é o saldo
      // real dela. Em conta de uso, o que foi acumulado desde o início.
      if (conta != null) {
        atual = conta.tipo == 'investimento'
            ? (saldos[conta.id] ?? 0).clamp(0, 9007199254740991)
            : movimentoDesdeOInicio(conta.id).clamp(0, 9007199254740991);
      }
  }

  final falta = menorEhMelhor ? 0 : (meta.alvoCentavos - atual).clamp(0, meta.alvoCentavos);
  return ProgressoDaMeta(
    atualCentavos: atual,
    alvoCentavos: meta.alvoCentavos,
    mesesRestantes: meses,
    parcelaNecessariaCentavos: meses == 0 ? falta : (falta / meses).ceil(),
    menorEhMelhor: menorEhMelhor,
  );
}

/// Situação da meta em uma frase.
String situacaoDaMeta(Meta meta, ProgressoDaMeta p, String hoje) {
  if (p.menorEhMelhor) {
    return p.atingida
        ? 'Dentro do teto: ${reais(p.atualCentavos)} de ${reais(p.alvoCentavos)}.'
        : 'Passou do teto em ${reais(p.atualCentavos - p.alvoCentavos)}.';
  }
  if (p.atingida) return 'Meta alcançada.';
  if (p.mesesRestantes == 0) return 'O prazo passou e faltam ${reais(p.faltaCentavos)}. Vale adiar ou rever o valor.';
  final parcela = meta.parcelaMensalCentavos ?? 0;
  if (parcela == 0) {
    return 'Faltam ${reais(p.faltaCentavos)}. Guardando ${reais(p.parcelaNecessariaCentavos)} por mês você chega no prazo.';
  }
  if (parcela >= p.parcelaNecessariaCentavos) return 'No ritmo: ${reais(parcela)} por mês bastam para chegar no prazo.';
  return 'Com ${reais(parcela)} por mês não chega no prazo; seriam ${reais(p.parcelaNecessariaCentavos)}.';
}
