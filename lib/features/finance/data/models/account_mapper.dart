import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:flutter/foundation.dart';

extension AccountFirestoreX on DocumentSnapshot {
  AccountModel toAccountModel() {
    final data = this.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('Account data is null');

    return AccountModel.fromJson(accountJsonFromFirestore(data, id));
  }
}

/// Documento cru do Firestore no JSON que `AccountModel.fromJson` entende.
///
/// Separado da extensão para poder ser testado sem um `DocumentSnapshot`: o
/// que precisa de cobertura é a conversão dos `Timestamp`, não o SDK.
@visibleForTesting
Map<String, dynamic> accountJsonFromFirestore(
  Map<String, dynamic> data,
  String id,
) {
  return {
    ...data,
    'id': id,
    if (data['initialBalanceDate'] is Timestamp)
      'initialBalanceDate': (data['initialBalanceDate']! as Timestamp)
          .toDate()
          .toIso8601String(),
    // `nextInvoice` NÃO é normalizado aqui: quem cuida dele é
    // `nextInvoiceFromJson`, no próprio modelo. A regra precisa valer também
    // para a cópia embutida em `automatic_transactions.suggestedAccount`, que
    // não passa por este mapper.
    // Mapeamento de metadata legado para campos diretos se necessário,
    // mas o fromJson já deve cuidar se usarmos @JsonKey
  };
}

extension AccountBalanceFirestoreX on DocumentSnapshot {
  AccountBalanceModel toAccountBalanceModel() {
    final data = this.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('AccountBalance data is null');

    return AccountBalanceModel.fromJson({
      ...data,
      'id': id,
      if (data['updatedAt'] is Timestamp)
        'updatedAt': (data['updatedAt'] as Timestamp)
            .toDate()
            .toIso8601String(),
    });
  }
}
