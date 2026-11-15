/// Modelo de dados do Funances 2 no app. Espelha
/// `functions/src/features/nucleo/domain/models/modelo.ts`: dinheiro em
/// centavos inteiros, datas de calendário como texto `AAAA-MM-DD`.
library;

typedef Mapa = Map<String, dynamic>;

String? _texto(Object? v) => v is String && v.isNotEmpty ? v : null;
int? _inteiro(Object? v) => v is int ? v : (v is double && v == v.roundToDouble() ? v.toInt() : null);

class Espaco {
  const Espaco({required this.id, required this.nome, required this.tipo});
  final String id;
  final String nome;

  /// `pessoal` ou `empresa`.
  final String tipo;

  bool get ehEmpresa => tipo == 'empresa';

  factory Espaco.deMapa(String id, Mapa m) => Espaco(
        id: id,
        nome: _texto(m['nome']) ?? 'Sem nome',
        tipo: m['tipo'] == 'empresa' ? 'empresa' : 'pessoal',
      );
}

class Conta {
  const Conta({
    required this.id,
    required this.nome,
    required this.tipo,
    this.saldoInicialCentavos = 0,
    this.saldoInicialData,
    this.arquivada = false,
    this.limiteCentavos,
    this.diaFechamento,
    this.diaVencimento,
    this.banco,
  });

  final String id;
  final String nome;

  /// `corrente`, `dinheiro`, `cartao`, `investimento` ou `divida`.
  final String tipo;
  final int saldoInicialCentavos;
  final String? saldoInicialData;
  final bool arquivada;
  final int? limiteCentavos;
  final int? diaFechamento;
  final int? diaVencimento;
  final String? banco;

  bool get ehCartao => tipo == 'cartao';

  /// Contas de onde o dinheiro do dia a dia sai e entra.
  bool get ehDeUso => tipo == 'corrente' || tipo == 'dinheiro';

  factory Conta.deMapa(String id, Mapa m) => Conta(
        id: id,
        nome: _texto(m['nome']) ?? 'Sem nome',
        tipo: _texto(m['tipo']) ?? 'corrente',
        saldoInicialCentavos: _inteiro(m['saldoInicialCentavos']) ?? 0,
        saldoInicialData: _texto(m['saldoInicialData']),
        arquivada: m['arquivada'] == true,
        limiteCentavos: _inteiro(m['limiteCentavos']),
        diaFechamento: _inteiro(m['diaFechamento']),
        diaVencimento: _inteiro(m['diaVencimento']),
        banco: _texto(m['banco']),
      );
}

class Categoria {
  const Categoria({
    required this.id,
    required this.nome,
    required this.tipo,
    this.arquivada = false,
    this.limiteMensalCentavos,
  });

  final String id;
  final String nome;

  /// `entrada` ou `saida`.
  final String tipo;
  final bool arquivada;
  final int? limiteMensalCentavos;

  factory Categoria.deMapa(String id, Mapa m) => Categoria(
        id: id,
        nome: _texto(m['nome']) ?? 'Sem nome',
        tipo: m['tipo'] == 'entrada' ? 'entrada' : 'saida',
        arquivada: m['arquivada'] == true,
        limiteMensalCentavos: _inteiro(m['limiteMensalCentavos']),
      );
}

class Lancamento {
  const Lancamento({
    required this.id,
    required this.tipo,
    required this.descricao,
    required this.data,
    required this.situacao,
    required this.contaId,
    this.previstoCentavos,
    this.realizadoCentavos,
    this.dataEfetiva,
    this.contaDestinoId,
    this.categoriaId,
    this.serieId,
    this.parcelaNumero,
    this.parcelaTotal,
    this.contraparteId,
    this.pagaFaturaId,
    this.origem = 'manual',
    this.loteId,
    this.autorId,
    this.vinculoId,
  });

  final String id;

  /// `entrada`, `saida` ou `transferencia`.
  final String tipo;
  final String descricao;
  final int? previstoCentavos;
  final int? realizadoCentavos;

  /// Data prevista (vencimento).
  final String data;
  final String? dataEfetiva;

  /// `previsto`, `efetivado` ou `cancelado`.
  final String situacao;
  final String contaId;
  final String? contaDestinoId;
  final String? categoriaId;
  final String? serieId;
  final int? parcelaNumero;
  final int? parcelaTotal;
  final String? contraparteId;
  final String? pagaFaturaId;
  final String origem;
  final String? loteId;
  final String? autorId;

  /// Liga os dois lados de um pró-labore: a saída na empresa e a entrada no
  /// espaço pessoal têm o mesmo vínculo e são desfeitas juntas.
  final String? vinculoId;

  bool get efetivado => situacao == 'efetivado';
  bool get previsto => situacao == 'previsto';
  bool get ehEntrada => tipo == 'entrada';
  bool get ehSaida => tipo == 'saida';
  bool get ehTransferencia => tipo == 'transferencia';

  /// O valor que representa o lançamento hoje: o realizado, se houver.
  int get valorCentavos => realizadoCentavos ?? previstoCentavos ?? 0;

  /// O dia em que ele aparece na linha do tempo.
  String get dia => dataEfetiva ?? data;

  factory Lancamento.deMapa(String id, Mapa m) {
    final parcela = m['parcela'];
    return Lancamento(
      id: id,
      tipo: _texto(m['tipo']) ?? 'saida',
      descricao: m['descricao'] is String ? m['descricao'] as String : '',
      previstoCentavos: _inteiro(m['previstoCentavos']),
      realizadoCentavos: _inteiro(m['realizadoCentavos']),
      data: _texto(m['data']) ?? '0000-00-00',
      dataEfetiva: _texto(m['dataEfetiva']),
      situacao: _texto(m['situacao']) ?? 'previsto',
      contaId: _texto(m['contaId']) ?? '',
      contaDestinoId: _texto(m['contaDestinoId']),
      categoriaId: _texto(m['categoriaId']),
      serieId: _texto(m['serieId']),
      parcelaNumero: parcela is Map ? _inteiro(parcela['numero']) : null,
      parcelaTotal: parcela is Map ? _inteiro(parcela['total']) : null,
      contraparteId: _texto(m['contraparteId']),
      pagaFaturaId: _texto(m['pagaFaturaId']),
      origem: _texto(m['origem']) ?? 'manual',
      loteId: _texto(m['loteId']),
      autorId: _texto(m['autorId']),
      vinculoId: _texto(m['vinculoId']),
    );
  }

  Mapa paraMapa() => {
        'tipo': tipo,
        'descricao': descricao,
        'previstoCentavos': previstoCentavos,
        'realizadoCentavos': realizadoCentavos,
        'data': data,
        'dataEfetiva': dataEfetiva,
        'situacao': situacao,
        'contaId': contaId,
        'contaDestinoId': contaDestinoId,
        'categoriaId': categoriaId,
        'serieId': serieId,
        'parcela': parcelaNumero != null && parcelaTotal != null
            ? {'numero': parcelaNumero, 'total': parcelaTotal}
            : null,
        'contraparteId': contraparteId,
        'pagaFaturaId': pagaFaturaId,
        'origem': origem,
        'loteId': loteId,
        'autorId': autorId,
        'vinculoId': vinculoId,
      };

  Lancamento copiar({
    String? id,
    String? tipo,
    String? descricao,
    int? Function()? previstoCentavos,
    int? Function()? realizadoCentavos,
    String? data,
    String? Function()? dataEfetiva,
    String? situacao,
    String? contaId,
    String? Function()? contaDestinoId,
    String? Function()? categoriaId,
    String? Function()? serieId,
    int? parcelaNumero,
    int? parcelaTotal,
    String? Function()? pagaFaturaId,
    String? origem,
    String? Function()? loteId,
    String? autorId,
    String? Function()? contraparteId,
  }) =>
      Lancamento(
        id: id ?? this.id,
        tipo: tipo ?? this.tipo,
        descricao: descricao ?? this.descricao,
        previstoCentavos:
            previstoCentavos != null ? previstoCentavos() : this.previstoCentavos,
        realizadoCentavos: realizadoCentavos != null
            ? realizadoCentavos()
            : this.realizadoCentavos,
        data: data ?? this.data,
        dataEfetiva: dataEfetiva != null ? dataEfetiva() : this.dataEfetiva,
        situacao: situacao ?? this.situacao,
        contaId: contaId ?? this.contaId,
        contaDestinoId:
            contaDestinoId != null ? contaDestinoId() : this.contaDestinoId,
        categoriaId: categoriaId != null ? categoriaId() : this.categoriaId,
        serieId: serieId != null ? serieId() : this.serieId,
        parcelaNumero: parcelaNumero ?? this.parcelaNumero,
        parcelaTotal: parcelaTotal ?? this.parcelaTotal,
        contraparteId: contraparteId != null ? contraparteId() : this.contraparteId,
        vinculoId: vinculoId,
        pagaFaturaId: pagaFaturaId != null ? pagaFaturaId() : this.pagaFaturaId,
        origem: origem ?? this.origem,
        loteId: loteId != null ? loteId() : this.loteId,
        autorId: autorId ?? this.autorId,
      );
}

class Fatura {
  const Fatura({
    required this.id,
    required this.contaId,
    required this.vencimento,
    required this.fechamento,
    required this.inicio,
    required this.fim,
    this.totalCentavos = 0,
    this.pagoCentavos = 0,
  });

  final String id;
  final String contaId;
  final String vencimento;
  final String fechamento;
  final String inicio;
  final String fim;
  final int totalCentavos;
  final int pagoCentavos;

  int get abertoCentavos => totalCentavos - pagoCentavos;
  bool get quitada => totalCentavos > 0 && abertoCentavos <= 0;

  factory Fatura.deMapa(String id, Mapa m) => Fatura(
        id: id,
        contaId: _texto(m['contaId']) ?? '',
        vencimento: _texto(m['vencimento']) ?? '',
        fechamento: _texto(m['fechamento']) ?? '',
        inicio: _texto(m['inicio']) ?? '',
        fim: _texto(m['fim']) ?? '',
        totalCentavos: _inteiro(m['totalCentavos']) ?? 0,
        pagoCentavos: _inteiro(m['pagoCentavos']) ?? 0,
      );
}

class Meta {
  const Meta({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.alvoCentavos,
    required this.inicio,
    required this.prazo,
    this.parcelaMensalCentavos,
    this.contaId,
    this.categoriaId,
    this.adiamentos = 0,
    this.arquivada = false,
    this.resultado,
  });

  final String id;
  final String nome;

  /// `juntar`, `quitar`, `reduzirCartao` ou `reduzirGasto`.
  final String tipo;
  final int alvoCentavos;
  final String inicio;
  final String prazo;
  final int? parcelaMensalCentavos;
  final String? contaId;
  final String? categoriaId;
  final int adiamentos;
  final bool arquivada;
  final String? resultado;

  bool get emAberto => !arquivada && resultado == null;

  factory Meta.deMapa(String id, Mapa m) => Meta(
        id: id,
        nome: _texto(m['nome']) ?? 'Sem nome',
        tipo: _texto(m['tipo']) ?? 'juntar',
        alvoCentavos: _inteiro(m['alvoCentavos']) ?? 0,
        inicio: _texto(m['inicio']) ?? '0000-00-00',
        prazo: _texto(m['prazo']) ?? '9999-12-31',
        parcelaMensalCentavos: _inteiro(m['parcelaMensalCentavos']),
        contaId: _texto(m['contaId']),
        categoriaId: _texto(m['categoriaId']),
        adiamentos: _inteiro(m['adiamentos']) ?? 0,
        arquivada: m['arquivada'] == true,
        resultado: _texto(m['resultado']),
      );
}

/// `resumos/{AAAA-MM}`, calculado pelo servidor.
class ResumoMes {
  const ResumoMes({
    required this.mes,
    required this.deltaPorConta,
    required this.categorias,
    this.entradasCentavos = 0,
    this.saidasCentavos = 0,
  });
  final String mes;

  /// Total realizado no mês, sem transferências.
  final int entradasCentavos;
  final int saidasCentavos;

  int get resultadoCentavos => entradasCentavos - saidasCentavos;
  final Map<String, int> deltaPorConta;

  /// Por categoria: (previsto, realizado).
  final Map<String, (int, int)> categorias;

  factory ResumoMes.deMapa(String mes, Mapa m) {
    final contas = <String, int>{};
    final brutoContas = m['contas'];
    if (brutoContas is Map) {
      brutoContas.forEach((id, v) {
        if (v is Map) contas['$id'] = _inteiro(v['deltaCentavos']) ?? 0;
      });
    }
    final categorias = <String, (int, int)>{};
    final brutoCategorias = m['categorias'];
    if (brutoCategorias is Map) {
      brutoCategorias.forEach((id, v) {
        if (v is Map) {
          categorias['$id'] = (
            _inteiro(v['previstoCentavos']) ?? 0,
            _inteiro(v['realizadoCentavos']) ?? 0,
          );
        }
      });
    }
    int realizado(String lado) {
      final v = m[lado];
      return v is Map ? (_inteiro(v['realizadoCentavos']) ?? 0) : 0;
    }

    return ResumoMes(
      mes: mes,
      deltaPorConta: contas,
      categorias: categorias,
      entradasCentavos: realizado('entradas'),
      saidasCentavos: realizado('saidas'),
    );
  }
}

/// Item da caixa de entrada: veio de fora (extrato, planilha, notificação)
/// e espera a confirmação da pessoa. Nada daqui entra no saldo sozinho.
class ItemEntrada {
  const ItemEntrada({
    required this.id,
    required this.descricao,
    required this.valorCentavos,
    required this.data,
    required this.tipo,
    this.contaId,
    this.categoriaId,
    this.origem = 'extrato',
    this.situacao = 'pendente',
    this.loteId,
    this.lancamentoId,
  });

  final String id;
  final String descricao;
  final int valorCentavos;
  final String data;

  /// `entrada`, `saida` ou `transferencia`.
  final String tipo;
  final String? contaId;
  final String? categoriaId;
  final String origem;

  /// `pendente`, `confirmado` ou `ignorado`.
  final String situacao;
  final String? loteId;

  /// Lançamento que este item virou, ou ao qual foi ligado.
  final String? lancamentoId;

  factory ItemEntrada.deMapa(String id, Mapa m) {
    final sugestao = m['sugestao'];
    return ItemEntrada(
      id: id,
      descricao: m['descricao'] is String ? m['descricao'] as String : '',
      valorCentavos: _inteiro(m['valorCentavos']) ?? 0,
      data: _texto(m['data']) ?? '0000-00-00',
      tipo: _texto(m['tipo']) ?? 'saida',
      contaId: sugestao is Map ? _texto(sugestao['contaId']) : null,
      categoriaId: sugestao is Map ? _texto(sugestao['categoriaId']) : null,
      origem: _texto(m['origem']) ?? 'extrato',
      situacao: _texto(m['situacao']) ?? 'pendente',
      loteId: _texto(m['loteId']),
      lancamentoId: _texto(m['lancamentoId']),
    );
  }

  Mapa paraMapa() => {
        'descricao': descricao,
        'valorCentavos': valorCentavos,
        'data': data,
        'tipo': tipo,
        'origem': origem,
        'situacao': situacao,
        'sugestao': {'contaId': contaId, 'categoriaId': categoriaId},
        'loteId': loteId,
        'lancamentoId': lancamentoId,
        'bruto': null,
      };
}

/// Regra de classificação: texto reconhecido → categoria.
class Regra {
  const Regra({required this.id, required this.texto, required this.categoriaId, this.contaId});
  final String id;
  final String texto;
  final String categoriaId;
  final String? contaId;

  factory Regra.deMapa(String id, Mapa m) => Regra(
        id: id,
        texto: _texto(m['texto']) ?? '',
        categoriaId: _texto(m['categoriaId']) ?? '',
        contaId: _texto(m['contaId']),
      );
}

/// `fechamentos/{AAAA-MM}`.
class Fechamento {
  const Fechamento({required this.mes, required this.situacao, this.extratoCentavos = const {}});
  final String mes;

  /// `aberto`, `fechado` ou `historico`.
  final String situacao;

  /// Saldo de extrato informado, por conta.
  final Map<String, int> extratoCentavos;

  bool get fechado => situacao == 'fechado';

  factory Fechamento.deMapa(String id, Mapa m) {
    final extrato = <String, int>{};
    final bruto = m['extratoCentavos'];
    if (bruto is Map) {
      bruto.forEach((conta, valor) {
        final v = _inteiro(valor);
        if (v != null) extrato['$conta'] = v;
      });
    }
    return Fechamento(mes: _texto(m['mes']) ?? id, situacao: _texto(m['situacao']) ?? 'aberto', extratoCentavos: extrato);
  }
}

/// Cliente ou fornecedor. O cadastro nasce dos lançamentos: é criado na
/// hora de lançar, não numa tela de cadastro.
class Contraparte {
  const Contraparte({required this.id, required this.nome, required this.tipo});
  final String id;
  final String nome;

  /// `cliente` ou `fornecedor`.
  final String tipo;

  factory Contraparte.deMapa(String id, Mapa m) => Contraparte(
        id: id,
        nome: _texto(m['nome']) ?? 'Sem nome',
        tipo: m['tipo'] == 'fornecedor' ? 'fornecedor' : 'cliente',
      );
}
