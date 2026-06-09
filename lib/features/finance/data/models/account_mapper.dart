import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';

extension AccountFirestoreX on DocumentSnapshot {
  AccountModel toAccountModel() {
    final data = this.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('Account data is null');

    return AccountModel.fromJson({
      ...data,
      'id': id,
      if (data['initialBalanceDate'] is Timestamp)
        'initialBalanceDate': (data['initialBalanceDate'] as Timestamp).toDate().toIso8601String(),
      // Mapeamento de metadata legado para campos diretos se necessário, 
      // mas o fromJson já deve cuidar se usarmos @JsonKey
    });
  }
}

extension AccountBalanceFirestoreX on DocumentSnapshot {
  AccountBalanceModel toAccountBalanceModel() {
    final data = this.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('AccountBalance data is null');

    return AccountBalanceModel.fromJson({
      ...data,
      'id': id,
      if (data['updatedAt'] is Timestamp)
        'updatedAt': (data['updatedAt'] as Timestamp).toDate().toIso8601String(),
    });
  }
}
