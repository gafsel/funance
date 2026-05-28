import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/account_model.dart';
import '../../domain/repositories/account_repository.dart';
import '../../../onboarding/domain/models/onboarding_models.dart';
import 'package:funances/core/exceptions/business_exception.dart';
import '../models/account_mapper.dart';

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
      return snapshot.docs.map((doc) => doc.toAccountModel()).toList();
    });
  }

  @override
  Future<void> createAccount(String workspaceId, AccountModel account) async {
    try {
      final data = account.toJson();
      data.remove('id');
      data['initial_balance_date'] = Timestamp.fromDate(account.initialBalanceDate);
      await _getCollection(workspaceId).add(data);
    } catch (e, s) {
      throw BusinessException(ErrorCode.unknown, originalError: e, stackTrace: s);
    }
  }

  @override
  Future<void> updateAccount(String workspaceId, AccountModel account) async {
    try {
      final data = account.toJson();
      data.remove('id');
      data['initial_balance_date'] = Timestamp.fromDate(account.initialBalanceDate);
      await _getCollection(workspaceId).doc(account.id).update(data);
    } catch (e, s) {
      throw BusinessException(ErrorCode.unknown, originalError: e, stackTrace: s);
    }
  }

  @override
  Future<void> deleteAccount(String workspaceId, String accountId) async {
    try {
      // Exclusão lógica conforme requisito
      await _getCollection(workspaceId).doc(accountId).update({'isDeleted': true});
    } catch (e, s) {
      throw BusinessException(ErrorCode.unknown, originalError: e, stackTrace: s);
    }
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
      return snapshot.docs.first.toAccountBalanceModel();
    });
  }

  @override
  Future<String> uploadAccountFile(String workspaceId, String accountId, File file) async {
    try {
      // Por enquanto, apenas simula o upload retornando o nome do arquivo
      // Em produção, isso integraria com o Firebase Storage
      return file.path.split('/').last;
    } catch (e, s) {
      throw BusinessException(ErrorCode.unknown, originalError: e, stackTrace: s);
    }
  }

  @override
  Future<ExtractedFinanceData> getExtractedData(String workspaceId, String accountId) async {
    try {
      // Por enquanto, retorna dados mockados para não travar o fluxo
      // A integração real será via Cloud Functions chamando a IA
      return ExtractedFinanceData(
        transactions: [],
        planningSuggestions: [],
        initialBalance: 0.0,
      );
    } catch (e, s) {
      throw BusinessException(ErrorCode.unknown, originalError: e, stackTrace: s);
    }
  }
}
