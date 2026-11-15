import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import '../modelo/modelos.dart';
import '../regras/faturas.dart';
import '../regras/formatos.dart';
import '../regras/montar.dart';

/// Leitura e gravação de um espaço no Firestore. O app grava lançamentos,
/// contas e afins; saldos, resumos e totais de fatura são do servidor.
class Repositorio {
  Repositorio(this._db, this.espacoId);

  final FirebaseFirestore _db;
  final String espacoId;

  DocumentReference<Mapa> get _espaco => _db.collection('espacos').doc(espacoId);
  CollectionReference<Mapa> _col(String nome) => _espaco.collection(nome);

  Stream<List<T>> _lista<T>(Query<Mapa> consulta, T Function(String, Mapa) de) =>
      consulta.snapshots().map((s) => [for (final d in s.docs) de(d.id, d.data())]);

  Stream<List<Conta>> contas() => _lista(_col('contas'), Conta.deMapa);
  Stream<List<Membro>> membros() => _lista(_col('membros'), Membro.deMapa);
  Stream<List<Categoria>> categorias() => _lista(_col('categorias'), Categoria.deMapa);
  Stream<List<Meta>> metas() => _lista(_col('metas'), Meta.deMapa);
  Stream<List<Fatura>> faturas() => _lista(_col('faturas'), Fatura.deMapa);
  Stream<List<ResumoMes>> resumos() => _lista(_col('resumos'), ResumoMes.deMapa);

  /// Lançamentos que tocam o intervalo: previstos para ele ou acontecidos
  /// nele. São duas consultas porque um lançamento pode vencer num mês e ser
  /// pago em outro.
  Stream<List<Lancamento>> lancamentosEntre(String de, String ate) {
    Stream<List<Lancamento>> por(String campo) => _lista(
          _col('lancamentos')
              .where(campo, isGreaterThanOrEqualTo: de)
              .where(campo, isLessThanOrEqualTo: ate),
          Lancamento.deMapa,
        );
    return Rx.combineLatest2(por('data'), por('dataEfetiva'), (a, b) {
      final porId = {for (final l in a) l.id: l, for (final l in b) l.id: l};
      return porId.values.toList();
    });
  }

  Stream<List<Lancamento>> lancamentosDoMes(String mes) =>
      lancamentosEntre('$mes-01', diaNoMes(mes, 31));

  /// Os últimos lançamentos feitos, de qualquer mês. É de onde o leitor de
  /// frases aprende categorias e de onde sai a ordem das contas mais usadas.
  /// Tem limite: não cresce com o histórico.
  Stream<List<Lancamento>> ultimosFeitos({int limite = 150}) => _lista(
        _col('lancamentos').orderBy('dataEfetiva', descending: true).limit(limite),
        Lancamento.deMapa,
      );

  /// Grava de uma vez tudo o que as montagens pedem. Devolve o id do lote,
  /// que é o que o "desfazer" usa.
  Future<String> salvar(List<Montagem> montagens, {required String loteId, String? autorId}) async {
    final batch = _db.batch();
    final ids = <String>[];
    final series = <String>[];
    for (final m in montagens) {
      if (m.serieId != null && m.serie != null) {
        batch.set(_col('series').doc(m.serieId), m.serie!);
        series.add(m.serieId!);
      }
      for (final bruto in m.lancamentos) {
        final l = await _comFatura(bruto);
        batch.set(_col('lancamentos').doc(l.id), {...l.paraMapa(), 'loteId': loteId});
        ids.add(l.id);
      }
    }
    batch.set(_col('lotes').doc(loteId), {
      'origem': 'app',
      'lancamentos': ids,
      'series': series,
      'criadoEm': FieldValue.serverTimestamp(),
      'autorId': autorId,
      'desfeito': false,
    });
    await batch.commit();
    return loteId;
  }

  /// Desfaz um lote: apaga os lançamentos e as séries que ele criou.
  Future<void> desfazerLote(String loteId) async {
    final lote = await _col('lotes').doc(loteId).get();
    final dados = lote.data();
    if (dados == null) return;
    final batch = _db.batch();
    for (final id in (dados['lancamentos'] as List? ?? const [])) {
      batch.delete(_col('lancamentos').doc('$id'));
    }
    for (final id in (dados['series'] as List? ?? const [])) {
      batch.delete(_col('series').doc('$id'));
    }
    batch.update(lote.reference, {'desfeito': true});
    await batch.commit();
  }

  Future<void> gravar(Lancamento l) async =>
      _col('lancamentos').doc(l.id).set((await _comFatura(l)).paraMapa());

  /// Dinheiro mandado para um cartão é pagamento de fatura: sem isso, o
  /// complemento de um pagamento parcial viraria crédito no ciclo atual e a
  /// fatura antiga continuaria em aberto. Quem já diz que fatura paga fica
  /// como está.
  Future<Lancamento> _comFatura(Lancamento l) async {
    final destino = l.contaDestinoId;
    if (!l.ehTransferencia || !l.efetivado || destino == null || l.pagaFaturaId != null) return l;
    try {
      final conta = await _col('contas').doc(destino).get();
      if (conta.data()?['tipo'] != 'cartao') return l;
      final faturas = await _col('faturas').where('contaId', isEqualTo: destino).get();
      final paga = faturaQueOPagamentoQuita([for (final d in faturas.docs) Fatura.deMapa(d.id, d.data())], l.dia);
      return paga == null ? l : l.copiar(pagaFaturaId: () => paga.id);
    } catch (erro) {
      // Sem rede: grava como está; a fatura mostra o aviso para corrigir.
      debugPrint('Não deu para achar a fatura do pagamento ${l.id}: $erro');
      return l;
    }
  }

  /// Pagamentos registrados para uma fatura.
  Stream<List<Lancamento>> pagamentosDaFatura(String faturaId) => _lista(
        _col('lancamentos').where('pagaFaturaId', isEqualTo: faturaId),
        Lancamento.deMapa,
      ).map((todos) => todos.where((l) => l.efetivado).toList());

  Future<void> apagar(String lancamentoId) => _col('lancamentos').doc(lancamentoId).delete();

  /// Marca um previsto como efetivado.
  Future<void> efetivar(Lancamento l, {required String dia, int? valorCentavos, String? contaId}) =>
      gravar(l.copiar(
        situacao: 'efetivado',
        realizadoCentavos: () => valorCentavos ?? l.previstoCentavos ?? 0,
        dataEfetiva: () => dia,
        contaId: contaId,
      ));

  /// Volta um efetivado para previsto (o "desfazer" de `efetivar`).
  Future<void> desefetivar(Lancamento original) => gravar(original);

  /// Compras de uma fatura: o que aconteceu no cartão dentro da janela.
  Stream<List<Lancamento>> comprasDaFatura(Fatura f) => _lista(
        _col('lancamentos')
            .where('dataEfetiva', isGreaterThanOrEqualTo: f.inicio)
            .where('dataEfetiva', isLessThanOrEqualTo: f.fim),
        Lancamento.deMapa,
      ).map((todos) => todos
          .where((l) => l.efetivado && (l.contaId == f.contaId || l.contaDestinoId == f.contaId))
          .where((l) => l.pagaFaturaId == null)
          .toList());

  Future<void> gravarConta(String id, Mapa dados) => _col('contas').doc(id).set(dados, SetOptions(merge: true));

  Future<void> gravarCategoria(String id, Mapa dados) =>
      _col('categorias').doc(id).set(dados, SetOptions(merge: true));

  // ---- Caixa de entrada, regras e fechamento ------------------------------

  Stream<List<ItemEntrada>> entradaPendente() =>
      _lista(_col('entrada').where('situacao', isEqualTo: 'pendente').limit(200), ItemEntrada.deMapa);

  Stream<List<Regra>> regras() => _lista(_col('regras'), Regra.deMapa);
  Stream<List<Fechamento>> fechamentos() => _lista(_col('fechamentos'), Fechamento.deMapa);

  /// Põe os itens na caixa de entrada. Quem já está lá (pendente, confirmado
  /// ou ignorado) não é tocado: reimportar o mesmo extrato não duplica nem
  /// ressuscita nada. Devolve quantos entraram de fato.
  Future<({int novos, String loteId})> importar(List<ItemEntrada> itens, {required String loteId, String? autorId}) async {
    final existentes = <String>{};
    for (var i = 0; i < itens.length; i += 30) {
      final ids = [for (final item in itens.skip(i).take(30)) item.id];
      final achados = await _col('entrada').where(FieldPath.documentId, whereIn: ids).get();
      existentes.addAll(achados.docs.map((d) => d.id));
    }
    final novos = itens.where((i) => !existentes.contains(i.id)).toList();
    for (var i = 0; i < novos.length; i += 400) {
      final batch = _db.batch();
      for (final item in novos.skip(i).take(400)) {
        batch.set(_col('entrada').doc(item.id), {...item.paraMapa(), 'loteId': loteId});
      }
      await batch.commit();
    }
    if (novos.isNotEmpty) {
      await _col('lotes').doc(loteId).set({
        'origem': 'importacao',
        'lancamentos': <String>[],
        'series': <String>[],
        'entrada': [for (final i in novos) i.id],
        'criadoEm': FieldValue.serverTimestamp(),
        'autorId': autorId,
        'desfeito': false,
      });
    }
    return (novos: novos.length, loteId: loteId);
  }

  /// Desfaz uma importação: tira da caixa o que ainda está pendente.
  Future<void> desfazerImportacao(String loteId) async {
    final pendentes = await _col('entrada').where('loteId', isEqualTo: loteId).get();
    final batch = _db.batch();
    for (final d in pendentes.docs) {
      if (d.data()['situacao'] == 'pendente') batch.delete(d.reference);
    }
    batch.update(_col('lotes').doc(loteId), {'desfeito': true});
    await batch.commit();
  }

  /// Confirma um item criando o lançamento `novo`, ou ligando-o a um
  /// lançamento que já existia (`existente`, já com os campos atualizados).
  Future<void> confirmarItem(ItemEntrada item, {Lancamento? novo, Lancamento? existente}) {
    final batch = _db.batch();
    final lancamento = novo ?? existente!;
    batch.set(_col('lancamentos').doc(lancamento.id), lancamento.paraMapa());
    batch.update(_col('entrada').doc(item.id), {'situacao': 'confirmado', 'lancamentoId': lancamento.id});
    return batch.commit();
  }

  /// Desfaz `confirmarItem`: o item volta a pendente; o lançamento criado é
  /// apagado, ou o que já existia volta a ser como era (`anterior`).
  Future<void> desconfirmarItem(ItemEntrada item, {String? criadoId, Lancamento? anterior}) {
    final batch = _db.batch();
    if (criadoId != null) batch.delete(_col('lancamentos').doc(criadoId));
    if (anterior != null) batch.set(_col('lancamentos').doc(anterior.id), anterior.paraMapa());
    batch.update(_col('entrada').doc(item.id), {'situacao': 'pendente', 'lancamentoId': null});
    return batch.commit();
  }

  Future<void> marcarItem(String itemId, String situacao) =>
      _col('entrada').doc(itemId).update({'situacao': situacao});

  Future<void> salvarRegra(String id, {required String texto, required String categoriaId}) =>
      _col('regras').doc(id).set({'texto': texto, 'categoriaId': categoriaId, 'contaId': null});

  Future<void> apagarRegra(String id) => _col('regras').doc(id).delete();

  Future<void> salvarFechamento(String mes, {required Map<String, int> extratoCentavos, required bool fechado, String? autorId}) =>
      _col('fechamentos').doc(mes).set({
        'mes': mes,
        'situacao': fechado ? 'fechado' : 'aberto',
        'extratoCentavos': extratoCentavos,
        'fechadoPor': fechado ? autorId : null,
        'fechadoEm': fechado ? FieldValue.serverTimestamp() : null,
      });

  // ---- Metas, caminho e categorias ----------------------------------------

  Future<void> gravarMeta(String id, Mapa dados) => _col('metas').doc(id).set(dados, SetOptions(merge: true));

  /// Marcações do caminho: degraus concluídos, metas pausadas no mês,
  /// semanas revisadas. Cada uma é um documento com id próprio.
  Stream<Map<String, Mapa>> marcas() =>
      _col('caminho').snapshots().map((s) => {for (final d in s.docs) d.id: d.data()});

  Future<void> marcar(String id, Mapa dados) => _col('caminho').doc(id).set(dados, SetOptions(merge: true));

  Future<void> desmarcar(String id) => _col('caminho').doc(id).delete();

  // ---- Empresa -------------------------------------------------------------

  Stream<List<Contraparte>> contrapartes() => _lista(_col('contrapartes'), Contraparte.deMapa);

  Future<void> gravarContraparte(String id, {required String nome, required String tipo}) =>
      _col('contrapartes').doc(id).set({'nome': nome, 'tipo': tipo});

  /// O que está agendado e ainda não aconteceu, do passado até `ate`. O
  /// limite existe porque as séries recorrentes geram doze meses à frente:
  /// sem ele, esta consulta cresceria com o número de contas fixas.
  Stream<List<Lancamento>> previstos({required String ate, int limite = 400}) => _lista(
        _col('lancamentos').where('situacao', isEqualTo: 'previsto').where('data', isLessThanOrEqualTo: ate).orderBy('data').limit(limite),
        Lancamento.deMapa,
      );
}
