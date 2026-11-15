import '../modelo/modelos.dart';
import 'formatos.dart';
import 'leitura_frase.dart';

/// O que uma leitura confirmada vira no banco: um ou mais lançamentos e,
/// quando é parcelado ou recorrente, a série que os liga.
class Montagem {
  const Montagem({required this.lancamentos, this.serieId, this.serie});
  final List<Lancamento> lancamentos;
  final String? serieId;
  final Mapa? serie;
}

/// Quantos meses de uma recorrência nascem já lançados. O servidor estende
/// depois (`estenderSeries`), usando os mesmos ids.
const mesesDeRecorrencia = 12;

/// Reparte `total` em `partes` valores inteiros; o resto vai nas primeiras.
List<int> repartir(int total, int partes) {
  final base = total ~/ partes;
  final resto = total % partes;
  return [for (var i = 0; i < partes; i++) base + (i < resto ? 1 : 0)];
}

Montagem montar(
  Leitura leitura, {
  required Conta conta,
  required String Function() novoId,
  String? autorId,
  String origem = 'texto',
}) {
  final contaId = conta.id;
  Lancamento um({
    required String id,
    required int valor,
    required String data,
    required bool efetivado,
    String? serieId,
    int? numero,
    int? total,
    String? origemDoItem,
  }) =>
      Lancamento(
        id: id,
        tipo: leitura.tipo,
        descricao: leitura.descricao,
        previstoCentavos: efetivado ? null : valor,
        realizadoCentavos: efetivado ? valor : null,
        data: data,
        dataEfetiva: efetivado ? data : null,
        situacao: efetivado ? 'efetivado' : 'previsto',
        contaId: contaId,
        contaDestinoId: leitura.tipo == 'transferencia' ? leitura.contaDestinoId : null,
        categoriaId: leitura.tipo == 'transferencia' ? null : leitura.categoriaId,
        serieId: serieId,
        parcelaNumero: numero,
        parcelaTotal: total,
        contraparteId: leitura.contraparteId,
        origem: origemDoItem ?? origem,
        autorId: autorId,
      );

  Mapa serieBase(String forma) => {
        'forma': forma,
        'frequencia': 'mensal',
        'tipo': leitura.tipo,
        'descricao': leitura.descricao,
        'valorCentavos': leitura.valorCentavos,
        'diaVencimento': int.parse(leitura.data.substring(8, 10)),
        'inicioMes': leitura.data.substring(0, 7),
        'contaId': contaId,
        'contaDestinoId': leitura.tipo == 'transferencia' ? leitura.contaDestinoId : null,
        'categoriaId': leitura.tipo == 'transferencia' ? null : leitura.categoriaId,
        'ativa': true,
      };

  final dia = int.parse(leitura.data.substring(8, 10));
  final mesInicial = leitura.data.substring(0, 7);
  final parcelas = leitura.parcelas;

  if (parcelas != null && parcelas >= 2) {
    final serieId = novoId();
    final valores = repartir(leitura.valorCentavos, parcelas);
    return Montagem(
      serieId: serieId,
      serie: {...serieBase('parcelado'), 'parcelas': parcelas, 'geradoAte': null},
      lancamentos: [
        for (var i = 0; i < parcelas; i++)
          um(
            id: novoId(),
            valor: valores[i],
            data: diaNoMes(somarMeses(mesInicial, i), dia),
            // No cartão a compra parcelada já aconteceu: cada parcela cai na
            // fatura do seu mês. Fora dele, só a primeira foi paga.
            efetivado: conta.ehCartao ? leitura.efetivado : (i == 0 && leitura.efetivado),
            serieId: serieId,
            numero: i + 1,
            total: parcelas,
          ),
      ],
    );
  }

  if (leitura.recorrente) {
    final serieId = novoId();
    final datas = [
      for (var i = 0; i < mesesDeRecorrencia; i++) diaNoMes(somarMeses(mesInicial, i), dia),
    ];
    return Montagem(
      serieId: serieId,
      serie: {...serieBase('recorrente'), 'parcelas': null, 'geradoAte': datas.last},
      lancamentos: [
        for (var i = 0; i < datas.length; i++)
          um(
            id: '${serieId}_${datas[i].substring(0, 7)}',
            valor: leitura.valorCentavos,
            data: datas[i],
            efetivado: i == 0 && leitura.efetivado,
            serieId: serieId,
            origemDoItem: i == 0 ? null : 'serie',
          ),
      ],
    );
  }

  return Montagem(lancamentos: [
    um(id: novoId(), valor: leitura.valorCentavos, data: leitura.data, efetivado: leitura.efetivado),
  ]);
}

/// A consequência de salvar, em uma frase, para mostrar antes de confirmar.
String consequencia(Leitura l, {required Conta? conta, Conta? destino}) {
  final valor = reais(l.valorCentavos, sempre: true);
  final nome = conta?.nome ?? 'uma conta';
  if (l.tipo == 'transferencia') {
    return '$valor saem de $nome e entram em ${destino?.nome ?? 'outra conta'}. Não conta como gasto.';
  }
  if (l.parcelas != null) {
    final parcela = reais(l.valorCentavos ~/ l.parcelas!, sempre: true);
    return conta?.ehCartao == true
        ? '${l.parcelas} parcelas de $parcela, uma em cada fatura de $nome.'
        : '${l.parcelas} parcelas de $parcela em $nome, uma por mês.';
  }
  if (l.recorrente) {
    return 'Todo mês, $valor ${l.tipo == 'entrada' ? 'entram em' : 'saem de'} $nome. Fica agendado para os próximos meses.';
  }
  if (!l.efetivado) {
    return 'Fica agendado: $valor ${l.tipo == 'entrada' ? 'a receber em' : 'a pagar de'} $nome.';
  }
  if (l.tipo == 'entrada') return '$valor entram em $nome.';
  return conta?.ehCartao == true
      ? '$valor entram na fatura de $nome e contam como gasto deste mês.'
      : '$valor saem de $nome.';
}
