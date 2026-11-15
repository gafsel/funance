import '../modelo/modelos.dart';
import 'faturas.dart';
import 'formatos.dart';

/// Um degrau do caminho: o que é, por que vem nesta ordem e o que falta.
class Degrau {
  const Degrau({
    required this.id,
    required this.titulo,
    required this.porque,
    required this.feito,
    required this.situacao,
    required this.proximoPasso,
    this.fracao,
  });

  final String id;
  final String titulo;

  /// Por que este degrau vem antes do próximo.
  final String porque;
  final bool feito;

  /// Onde a pessoa está neste degrau, com número quando há.
  final String situacao;

  /// Uma ação concreta, pequena, para andar.
  final String proximoPasso;
  final double? fracao;
}

/// O que o caminho precisa enxergar do espaço.
class DadosDoCaminho {
  const DadosDoCaminho({
    required this.hoje,
    required this.ehEmpresa,
    required this.contas,
    required this.saldos,
    required this.resumos,
    required this.faturas,
    required this.metas,
    required this.fechamentos,
    required this.lancamentosDoMes,
    this.categoriaProLaboreIds = const {},
    this.previstoProximos30Centavos = 0,
  });

  final String hoje;
  final bool ehEmpresa;
  final List<Conta> contas;
  final Map<String, int> saldos;
  final List<ResumoMes> resumos;
  final List<Fatura> faturas;
  final List<Meta> metas;
  final List<Fechamento> fechamentos;
  final List<Lancamento> lancamentosDoMes;
  final Set<String> categoriaProLaboreIds;

  /// Saldo previsto no ponto mais baixo dos próximos 30 dias (empresa).
  final int previstoProximos30Centavos;
}

List<ResumoMes> _ultimosMesesCompletos(DadosDoCaminho d, int quantos) {
  final mes = d.hoje.substring(0, 7);
  final anteriores = d.resumos.where((r) => r.mes.compareTo(mes) < 0 && (r.entradasCentavos > 0 || r.saidasCentavos > 0)).toList()
    ..sort((a, b) => b.mes.compareTo(a.mes));
  return anteriores.take(quantos).toList();
}

int _mediaDeSaidas(DadosDoCaminho d) {
  final meses = _ultimosMesesCompletos(d, 3);
  if (meses.isEmpty) return 0;
  return meses.fold<int>(0, (s, r) => s + r.saidasCentavos) ~/ meses.length;
}

/// Os degraus, em ordem. O degrau atual é o primeiro que não está feito.
List<Degrau> calcularCaminho(DadosDoCaminho d) => d.ehEmpresa ? _empresa(d) : _pessoal(d);

Degrau? degrauAtual(List<Degrau> caminho) => caminho.where((g) => !g.feito).firstOrNull;

List<Degrau> _pessoal(DadosDoCaminho d) {
  final mes = d.hoje.substring(0, 7);
  final ativos = d.contas.where((c) => !c.arquivada).toList();
  final doMes = d.lancamentosDoMes.where((l) => l.efetivado && l.dia.startsWith(mes)).toList();
  final temRenda = doMes.any((l) => l.ehEntrada);
  final saidasDoMes = doMes.where((l) => l.ehSaida).length;
  final mesAnteriorFechado = d.fechamentos.any((f) => f.fechado && f.mes.compareTo(mes) < 0);
  final enxerga = ativos.isNotEmpty && (mesAnteriorFechado || (temRenda && saidasDoMes >= 10));

  final ultimo = _ultimosMesesCompletos(d, 1).firstOrNull;
  final sobra = ultimo != null && ultimo.resultadoCentavos >= 0;

  final dividas = ativos.where((c) => c.tipo == 'divida' && (d.saldos[c.id] ?? 0) < 0).toList();
  final devendo = dividas.fold<int>(0, (s, c) => s - (d.saldos[c.id] ?? 0));
  final faturasCaras = faturasEmDividaCara(situacoesDasFaturas(d.faturas, d.hoje));
  final faturasVencidas = faturasCaras.where((s) => s.atrasada).toList();
  final faturasEmParte = faturasCaras.where((s) => s.emParte).toList();
  final semDividaCara = dividas.isEmpty && faturasCaras.isEmpty;

  final media = _mediaDeSaidas(d);
  final guardado = ativos.where((c) => c.tipo == 'investimento').fold<int>(0, (s, c) => s + (d.saldos[c.id] ?? 0));
  final alvoDaReserva = media * 3;
  final temReserva = media > 0 && guardado >= alvoDaReserva;

  final metasComParcela = d.metas.where((m) => m.emAberto && (m.parcelaMensalCentavos ?? 0) > 0).length;

  return [
    Degrau(
      id: 'enxergar',
      titulo: 'Enxergar o seu dinheiro',
      porque: 'Antes de mudar qualquer coisa, é preciso saber para onde o dinheiro vai.',
      feito: enxerga,
      situacao: ativos.isEmpty
          ? 'Ainda não há nenhuma conta cadastrada.'
          : (enxerga
              ? 'Você já tem um mês de lançamentos para olhar.'
              : '$saidasDoMes ${saidasDoMes == 1 ? 'gasto lançado' : 'gastos lançados'} neste mês${temRenda ? '' : ', e a renda ainda não foi lançada'}.'),
      proximoPasso: !temRenda ? 'Lance o que você recebeu neste mês.' : 'Lance os gastos conforme acontecem, até o fim do mês.',
      fracao: enxerga ? 1 : (saidasDoMes / 10).clamp(0, 1).toDouble(),
    ),
    Degrau(
      id: 'sobrar',
      titulo: 'Gastar menos do que ganha',
      porque: 'Sem sobra no fim do mês, não há com o que pagar dívida nem guardar.',
      feito: sobra,
      situacao: ultimo == null
          ? 'Falta um mês completo para comparar.'
          : (sobra
              ? 'Em ${nomeDoMes(ultimo.mes)} sobraram ${reais(ultimo.resultadoCentavos)}.'
              : 'Em ${nomeDoMes(ultimo.mes)} faltaram ${reais(-ultimo.resultadoCentavos)}.'),
      proximoPasso: 'Olhe as três maiores categorias do mês e escolha uma para reduzir.',
    ),
    Degrau(
      id: 'divida',
      titulo: 'Sair da dívida cara',
      porque: 'Juros de cartão e de empréstimo crescem mais rápido do que qualquer investimento rende.',
      feito: semDividaCara,
      situacao: semDividaCara
          ? 'Nenhuma dívida em aberto nem fatura atrasada.'
          : _frase([
              if (dividas.isNotEmpty) '${reais(devendo)} em ${dividas.length == 1 ? 'uma dívida' : '${dividas.length} dívidas'}',
              if (faturasVencidas.length == 1) 'uma fatura atrasada',
              if (faturasVencidas.length > 1) '${faturasVencidas.length} faturas atrasadas',
              if (faturasEmParte.length == 1) 'uma fatura paga em parte',
              if (faturasEmParte.length > 1) '${faturasEmParte.length} faturas pagas em parte',
            ]),
      proximoPasso: faturasVencidas.isNotEmpty
          ? 'Pague a fatura atrasada antes de qualquer outra coisa.'
          : faturasEmParte.isNotEmpty
              ? 'Complete o pagamento da fatura: o rotativo do cartão é a dívida mais cara que existe.'
              : 'Crie uma meta de quitar a dívida com os juros mais altos.',
    ),
    Degrau(
      id: 'reserva',
      titulo: 'Montar a reserva',
      porque: 'Três meses de gastos guardados evitam que um imprevisto vire dívida de novo.',
      feito: temReserva,
      situacao: media == 0
          ? 'Falta um mês completo para saber quanto é a sua reserva.'
          : '${reais(guardado)} guardados de ${reais(alvoDaReserva)} (três meses de gastos).',
      proximoPasso: 'Crie uma meta de reserva ligada a uma conta de investimento.',
      fracao: alvoDaReserva == 0 ? 0 : (guardado / alvoDaReserva).clamp(0, 1).toDouble(),
    ),
    Degrau(
      id: 'metas',
      titulo: 'Realizar as suas metas',
      porque: 'Com as contas em dia e a reserva pronta, o que sobra já pode ter destino.',
      feito: metasComParcela > 0 && temReserva && semDividaCara,
      situacao: metasComParcela == 0
          ? 'Nenhuma meta com valor mensal definido.'
          : '$metasComParcela ${metasComParcela == 1 ? 'meta em andamento' : 'metas em andamento'}.',
      proximoPasso: 'Escolha uma meta, um prazo e quanto separar por mês.',
    ),
  ];
}

List<Degrau> _empresa(DadosDoCaminho d) {
  final mes = d.hoje.substring(0, 7);
  final ativos = d.contas.where((c) => !c.arquivada).toList();
  final doMes = d.lancamentosDoMes.where((l) => l.efetivado && l.dia.startsWith(mes)).length;
  final separado = ativos.any((c) => c.ehDeUso) && doMes >= 10;

  final caixa = ativos.where((c) => c.ehDeUso).fold<int>(0, (s, c) => s + (d.saldos[c.id] ?? 0));
  final agendados = d.lancamentosDoMes.where((l) => l.previsto).length;
  final previsivel = agendados >= 3 && d.previstoProximos30Centavos >= 0;

  final media = _mediaDeSaidas(d);
  final giro = media > 0 && caixa >= media;

  final tres = _ultimosMesesCompletos(d, 3);
  final proLabore = d.categoriaProLaboreIds;
  final mesesComProLabore = tres.where((r) => proLabore.any((id) => (r.categorias[id]?.$2 ?? 0) > 0)).length;
  final estavel = tres.length == 3 && mesesComProLabore == 3;

  final lucro = tres.length == 3 && tres.every((r) => r.resultadoCentavos > 0);

  return [
    Degrau(
      id: 'separar',
      titulo: 'Separar o caixa da empresa',
      porque: 'Enquanto o dinheiro da empresa e o seu se misturam, nenhum número é confiável.',
      feito: separado,
      situacao: ativos.where((c) => c.ehDeUso).isEmpty
          ? 'A empresa ainda não tem uma conta só dela aqui.'
          : '$doMes ${doMes == 1 ? 'lançamento' : 'lançamentos'} da empresa neste mês.',
      proximoPasso: 'Lance tudo o que entra e sai da conta da empresa, e nada do que é pessoal.',
      fracao: separado ? 1 : (doMes / 10).clamp(0, 1).toDouble(),
    ),
    Degrau(
      id: 'previsivel',
      titulo: 'Tornar o caixa previsível',
      porque: 'Saber hoje o que vence nos próximos 30 dias é o que evita o susto.',
      feito: previsivel,
      situacao: agendados < 3
          ? 'Poucos compromissos agendados: o app ainda não consegue prever o caixa.'
          : (d.previstoProximos30Centavos >= 0
              ? 'O caixa previsto fica positivo nos próximos 30 dias.'
              : 'O caixa previsto chega a ${reais(d.previstoProximos30Centavos)} nos próximos 30 dias.'),
      proximoPasso: 'Agende o que você já sabe que vai pagar e receber neste mês.',
    ),
    Degrau(
      id: 'giro',
      titulo: 'Formar capital de giro',
      porque: 'Um mês de despesas em caixa deixa a empresa atravessar um cliente que atrasa.',
      feito: giro,
      situacao: media == 0
          ? 'Falta um mês completo para saber quanto é um mês de despesas.'
          : '${reais(caixa)} em caixa de ${reais(media)} (um mês de despesas).',
      proximoPasso: 'Antes de retirar lucro, deixe em caixa o equivalente a um mês de despesas.',
      fracao: media == 0 ? 0 : (caixa / media).clamp(0, 1).toDouble(),
    ),
    Degrau(
      id: 'prolabore',
      titulo: 'Pagar um pró-labore estável',
      porque: 'Retirada fixa, em dia certo, separa o seu salário do resultado da empresa.',
      feito: estavel,
      situacao: tres.length < 3
          ? 'Faltam três meses completos para avaliar.'
          : 'Pró-labore pago em $mesesComProLabore dos últimos 3 meses.',
      proximoPasso: 'Defina um valor de pró-labore e agende a retirada todo mês.',
    ),
    Degrau(
      id: 'lucro',
      titulo: 'Dar lucro de forma consistente',
      porque: 'Lucro repetido, depois do pró-labore, é o que permite crescer ou distribuir.',
      feito: lucro,
      situacao: tres.length < 3
          ? 'Faltam três meses completos para avaliar.'
          : '${tres.where((r) => r.resultadoCentavos > 0).length} dos últimos 3 meses fecharam com lucro.',
      proximoPasso: 'Veja o resultado por centro de custo e corte o que não dá retorno.',
    ),
  ];
}

/// Junta as partes com "e", com maiúscula no começo e ponto no fim.
String _frase(List<String> partes) {
  final texto = partes.join(' e ');
  return texto.isEmpty ? '' : '${texto[0].toUpperCase()}${texto.substring(1)}.';
}
