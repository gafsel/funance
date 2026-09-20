import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:funances/core/money/money.dart';
import 'package:funances/features/arena/domain/models/hud_state.dart';
import 'package:funances/features/arena/domain/repositories/hud_repository.dart';

/// Leitura dos dois documentos que só o servidor escreve.
///
/// Sem mapper gerado de propósito: são dois objetos pequenos, de forma fixa e
/// publicada (`functions/README.md`, "HUD mensal"), e um `fromJson` gerado
/// aqui traria de brinde um `toJson` que as rules recusam.
class HudRepositoryImpl implements IHudRepository {
  HudRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<ExpectedIncome?> watchExpectedIncome(String workspaceId) {
    return _firestore
        .doc('workspaces/$workspaceId')
        .snapshots()
        .map((doc) => parseExpectedIncome(doc.data()?['expectedIncome']));
  }

  @override
  Stream<List<HudMonthlyReport>> watchMonthlyReports(
    String workspaceId, {
    int limit = 6,
  }) {
    return _firestore
        .collection('workspaces/$workspaceId/monthly_reports')
        .orderBy(FieldPath.documentId, descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => parseMonthlyReport(doc.id, doc.data()))
              .nonNulls
              .toList(),
        );
  }
}

/// `expectedIncome` do documento do workspace.
///
/// Tolerante por fora e exigente por dentro: o campo pode simplesmente não
/// existir (é o normal num workspace que ainda não passou pelo cron), e nesse
/// caso a resposta é `null` — que o app lê como "ainda não sei". O que NÃO se
/// aceita é um objeto sem `cents`: uma previsão sem número não é previsão, e
/// deixá-la virar zero recriaria justamente o veredito que o contrato proíbe.
///
/// Público para ter teste sem Firestore.
ExpectedIncome? parseExpectedIncome(Object? raw) {
  if (raw is! Map) return null;

  final cents = raw['cents'];
  final monthKey = raw['monthKey'];
  if (cents is! num || monthKey is! String) return null;

  // Negativo não existe neste campo (um mês de estornos podia fechar com
  // receita negativa, e um denominador negativo inverteria o sinal das três
  // razões). Se aparecer, é dado quebrado: melhor "não sei" do que um sinal
  // trocado.
  if (cents < 0) return null;

  return ExpectedIncome(
    monthKey: monthKey,
    amount: Money.fromCents(cents.toInt()),
    source: raw['source'] == 'average'
        ? ExpectedIncomeSource.average
        : ExpectedIncomeSource.planned,
    updatedAt: DateTime.tryParse('${raw['updatedAt']}'),
  );
}

/// Um documento de `monthly_reports`. `null` quando ele não tem forma de
/// retrato — um documento que não sabe dizer quantos aldeões havia não
/// consegue contar nada no histórico.
///
/// Público para ter teste sem Firestore.
HudMonthlyReport? parseMonthlyReport(String id, Map<String, Object?>? data) {
  if (data == null) return null;

  final planned = data['villagersPlanned'];
  final alive = data['villagersAlive'];
  if (planned is! num || alive is! num) return null;

  final monthKey = data['monthKey'];

  return HudMonthlyReport(
    monthKey: monthKey is String ? monthKey : id,
    villagersPlanned: planned.toInt(),
    villagersAlive: alive.toInt(),
    villageAlive: data['villageAlive'] == true,
    xpAwarded: data['xpAwarded'] is num
        ? (data['xpAwarded']! as num).toInt()
        : 0,
  );
}
