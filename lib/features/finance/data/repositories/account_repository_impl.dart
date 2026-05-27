import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/account_model.dart';
import '../../domain/repositories/account_repository.dart';

class AccountRepositoryImpl implements IAccountRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _getCollection(String workspaceId) {
    return _firestore.collection('workspaces').doc(workspaceId).collection('accounts');
  }

  @override
  Stream<List<AccountModel>> getAccounts(String workspaceId) {
    return _getCollection(workspaceId)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AccountModel.fromFirestore(doc)).toList();
    });
  }

  @override
  Future<void> createAccount(String workspaceId, AccountModel account) async {
    final data = account.toJson();
    data.remove('id');
    data['initial_balance_date'] = Timestamp.fromDate(account.initialBalanceDate);
    await _getCollection(workspaceId).add(data);
  }

  @override
  Future<void> updateAccount(String workspaceId, AccountModel account) async {
    final data = account.toJson();
    data.remove('id');
    data['initial_balance_date'] = Timestamp.fromDate(account.initialBalanceDate);
    await _getCollection(workspaceId).doc(account.id).update(data);
  }

  @override
  Future<void> deleteAccount(String workspaceId, String accountId) async {
    // Exclusão lógica conforme requisito
    await _getCollection(workspaceId).doc(accountId).update({'isDeleted': true});
  }

  @override
  Stream<AccountBalanceModel?> getLatestAccountBalance(String workspaceId, String accountId) {
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    return _getCollection(workspaceId)
        .doc(accountId)
        .collection('balance')
        .where(FieldPath.documentId, isLessThanOrEqualTo: today)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return AccountBalanceModel.fromFirestore(snapshot.docs.first);
    });
  }
}
