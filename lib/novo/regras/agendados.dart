import '../modelo/modelos.dart';
import 'formatos.dart';
import 'leitura_frase.dart';

const _vazias = {'de', 'da', 'do', 'das', 'dos', 'para', 'pro', 'pra', 'com', 'em', 'no', 'na', 'conta', 'pagamento', 'paguei', 'parcela'};

Set<String> _palavras(String texto) => {
      for (final p in normalizar(texto).split(RegExp(r'[^a-z0-9]+')))
        if (p.length >= 3 && !_vazias.contains(p)) p,
    };

/// O agendado que um lançamento novo parece estar pagando, para o app
/// propor marcá-lo como pago em vez de criar outro.
///
/// Só vale para o que já aconteceu e não se repete (uma compra parcelada ou
/// uma série nova não "paga" um agendado). O agendado tem de ser do mesmo
/// tipo e vencer perto: até 20 dias depois da data do lançamento (pagou
/// adiantado) ou até 45 antes (pagou atrasado). Daí, precisa de mais de um
/// sinal: valor igual com data próxima, ou valor parecido com a mesma
/// categoria ou uma palavra em comum na descrição.
Lancamento? agendadoQueCorresponde(Leitura l, Iterable<Lancamento> previstos, {Set<String> usados = const {}}) {
  if (!l.efetivado || l.recorrente || l.parcelas != null || l.valorCentavos <= 0) return null;
  final dia = diaDaChave(l.data);
  final palavras = _palavras(l.descricao);

  Lancamento? melhor;
  var melhorNota = 0;
  var melhorDistancia = 1 << 20;
  for (final p in previstos) {
    if (!p.previsto || usados.contains(p.id) || p.tipo != l.tipo) continue;
    final previsto = p.previstoCentavos ?? 0;
    if (previsto <= 0) continue;
    // Positivo: o agendado vence depois da data do lançamento.
    final dias = diaDaChave(p.data).difference(dia).inDays;
    if (dias > 20 || dias < -45) continue;
    if (l.tipo == 'transferencia' && p.contaDestinoId != l.contaDestinoId) continue;

    final diferenca = (l.valorCentavos - previsto).abs() * 100 / previsto;
    final notaDoValor = diferenca == 0 ? 3 : (diferenca <= 10 ? 2 : (diferenca <= 25 ? 1 : 0));
    if (notaDoValor == 0) continue;
    final mesmaCategoria = l.categoriaId != null && l.categoriaId == p.categoriaId;
    final mesmaPalavra = palavras.intersection(_palavras(p.descricao)).isNotEmpty;
    final perto = dias.abs() <= 7;

    final bate = switch (notaDoValor) {
      3 => mesmaCategoria || mesmaPalavra || perto,
      2 => mesmaCategoria || mesmaPalavra,
      _ => mesmaCategoria && mesmaPalavra,
    };
    if (!bate) continue;

    final nota = notaDoValor * 2 + (mesmaCategoria ? 2 : 0) + (mesmaPalavra ? 2 : 0) + (p.contaId == l.contaId ? 1 : 0);
    if (nota > melhorNota || (nota == melhorNota && dias.abs() < melhorDistancia)) {
      melhor = p;
      melhorNota = nota;
      melhorDistancia = dias.abs();
    }
  }
  return melhor;
}

/// Um agendado para cada leitura que tiver um, na ordem, sem repetir.
Map<Leitura, Lancamento> agendadosDasLeituras(Iterable<Leitura> leituras, Iterable<Lancamento> previstos) {
  final usados = <String>{};
  final pares = <Leitura, Lancamento>{};
  for (final l in leituras) {
    final achado = agendadoQueCorresponde(l, previstos, usados: usados);
    if (achado != null) {
      pares[l] = achado;
      usados.add(achado.id);
    }
  }
  return pares;
}
