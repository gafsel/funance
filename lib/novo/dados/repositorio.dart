import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

import '../modelo/modelos.dart';
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

  /// Previstos vencidos e ainda não pagos, de qualquer mês anterior.
  Stream<List<Lancamento>> atrasados(String hoje) => _lista(
        _col('lancamentos').where('situacao', isEqualTo: 'previsto').where('data', isLessThan: hoje),
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
      for (final l in m.lancamentos) {
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

  Future<void> gravar(Lancamento l) => _col('lancamentos').doc(l.id).set(l.paraMapa());

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
}
