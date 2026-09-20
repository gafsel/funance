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
    // F1.8: o resumo da próxima fatura vem do servidor com Timestamps
    // aninhados; `fromJson` só entende ISO.
    if (data['nextInvoice'] is Map)
      'nextInvoice': _normalizeNextInvoice(
        data['nextInvoice']! as Map<Object?, Object?>,
      ),
    // Mapeamento de metadata legado para campos diretos se necessário,
    // mas o fromJson já deve cuidar se usarmos @JsonKey
  };
}

/// Converte os `Timestamp` de `nextInvoice` em ISO, preservando o instante.
///
/// Uma conta gravada antes de F1.8 não tem o campo, e uma gravada por uma
/// versão anterior do servidor pode não ter todas as datas: nesse caso o resumo
/// é DESCARTADO (`null`) em vez de chegar pela metade. A tela mostra
/// "calculando", que é honesto — um ciclo sem borda mostraria a fatura errada.
Map<String, dynamic>? _normalizeNextInvoice(Map<Object?, Object?> raw) {
  const dateFields = ['dueDate', 'closingDate', 'cycleStart', 'cycleEnd'];

  final normalized = <String, dynamic>{};
  for (final entry in raw.entries) {
    final key = entry.key.toString();
    final value = entry.value;
    normalized[key] = value is Timestamp
        ? value.toDate().toLocal().toIso8601String()
        : value;
  }

  for (final field in dateFields) {
    if (normalized[field] is! String) return null;
  }

  return normalized;
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
