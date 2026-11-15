import 'formatos.dart';

/// Organização financeira: a cada três meses o app convida a pessoa a rever
/// a renda, os gastos fixos e os limites das categorias de estilo de vida.

/// De quanto em quanto tempo o convite volta.
const mesesEntreOrganizacoes = 3;

/// Está na hora de convidar? Nunca fez, ou a última foi há três meses ou
/// mais. Adiar empurra o convite por trinta dias.
bool horaDeOrganizar({required String hoje, String? feitaEm, String? adiadaEm}) {
  if (adiadaEm != null && somarDias(adiadaEm, 30).compareTo(hoje) > 0) return false;
  if (feitaEm == null) return true;
  return somarMeses(feitaEm.substring(0, 7), mesesEntreOrganizacoes).compareTo(hoje.substring(0, 7)) <= 0;
}

class SugestaoDeLimites {
  const SugestaoDeLimites({required this.tetoCentavos, required this.limites, this.aviso});

  /// Quanto o estilo de vida inteiro pode somar por mês.
  final int tetoCentavos;

  /// Limite sugerido por categoria, em centavos.
  final Map<String, int> limites;

  /// Quando a conta não fecha (os fixos e as metas tomam tudo).
  final String? aviso;
}

/// Limites para as categorias de estilo de vida.
///
/// O teto do grupo é o menor entre a parte da renda que a referência reserva
/// para ele e o que sobra depois dos fixos e das metas: não adianta a
/// referência dar 30% se o que sobra é 15%. O teto é repartido na proporção
/// do que cada categoria costuma gastar, em dezenas de reais, sem passar do
/// teto. Categoria sem histórico fica sem limite.
SugestaoDeLimites sugerirLimites({
  required int rendaCentavos,
  required int fixosCentavos,
  required int metasCentavos,
  required int percentualDoEstilo,
  required Map<String, int> mediaPorCategoria,
}) {
  final pelaReferencia = rendaCentavos * percentualDoEstilo ~/ 100;
  final peloQueSobra = rendaCentavos - fixosCentavos - metasCentavos;
  final teto = pelaReferencia < peloQueSobra ? pelaReferencia : peloQueSobra;
  if (rendaCentavos <= 0) {
    return const SugestaoDeLimites(tetoCentavos: 0, limites: {}, aviso: 'Informe a renda do mês para o app sugerir os limites.');
  }
  if (teto <= 0) {
    return SugestaoDeLimites(
      tetoCentavos: 0,
      limites: const {},
      aviso: 'Os gastos fixos e as metas já tomam toda a renda (${reais(fixosCentavos + metasCentavos, sempre: true)} de ${reais(rendaCentavos, sempre: true)}). '
          'Antes de limitar o resto, vale rever um fixo ou pausar uma meta.',
    );
  }
  final comHistorico = {for (final e in mediaPorCategoria.entries) if (e.value > 0) e.key: e.value};
  final soma = comHistorico.values.fold<int>(0, (s, v) => s + v);
  if (soma == 0) return SugestaoDeLimites(tetoCentavos: teto, limites: const {});
  // Quem já gasta menos que o teto não precisa ser empurrado para cima.
  final fator = soma <= teto ? 1.0 : teto / soma;
  return SugestaoDeLimites(
    tetoCentavos: teto,
    limites: {
      for (final e in comHistorico.entries)
        // Para baixo, em dezenas de reais; no mínimo dez reais.
        e.key: (((e.value * fator) ~/ 1000) * 1000).clamp(1000, teto),
    },
  );
}
