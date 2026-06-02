import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:funances/features/finance/domain/repositories/account_repository.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/account_model.dart';
import 'package:funances/core/exceptions/business_exception.dart';
import '../models/account_mapper.dart';
import '../models/finance_mapper.dart';

class AccountRepositoryImpl implements IAccountRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  CollectionReference _getCollection(String workspaceId) {
    return _firestore
        .collection('workspaces')
        .doc(workspaceId)
        .collection('accounts');
  }

  @override
  Stream<List<AccountModel>> getAccounts(
    String workspaceId, {
    AccountType? type,
  }) {
    var query = _getCollection(
      workspaceId,
    ).where('isDeleted', isEqualTo: false);

    if (type != null) {
      query = query.where("runtimeType", isEqualTo: type.name);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.toAccountModel()).toList();
    });
  }

  @override
  Future<AccountModel> createAccount(String workspaceId, AccountModel account) async {
    try {
      final data = account.toJson();
      data.remove('id');
      data['initial_balance_date'] = Timestamp.fromDate(
        account.initialBalanceDate,
      );
      final doc = await _getCollection(workspaceId).add(data);
      return account.copyWith(id: doc.id);
    } catch (e, s) {
      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> updateAccount(String workspaceId, AccountModel account) async {
    try {
      final data = account.toJson();
      data.remove('id');
      data['initial_balance_date'] = Timestamp.fromDate(
        account.initialBalanceDate,
      );
      await _getCollection(workspaceId).doc(account.id).update(data);
    } catch (e, s) {
      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> deleteAccount(String workspaceId, String accountId) async {
    try {
      // Exclusão lógica conforme requisito
      await _getCollection(
        workspaceId,
      ).doc(accountId).update({'isDeleted': true});
    } catch (e, s) {
      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }

  @override
  Stream<AccountBalanceModel?> getLatestAccountBalance(
    String workspaceId,
    String accountId,
  ) {
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
  Future<String> uploadAccountFile(
    String workspaceId,
    String accountId,
    File file,
  ) async {
    try {
      // Por enquanto, apenas simula o upload retornando o nome do arquivo
      // Em produção, isso integraria com o Firebase Storage
      return file.path.split('/').last;
    } catch (e, s) {
      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<AccountDocumentAnalysisResult> analyseDocument(
    String workspaceId,
    File file,
  ) async {
    try {
      String name = file.path.split("/").last;

      // 1. Upload para o Storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath =
          'workspaces/$workspaceId/account_analysis/${_auth.currentUser!.uid}_${timestamp}_$name';

      await _storage.ref().child(storagePath).putFile(file);

      final callable = _functions.httpsCallable(
        'analyzeAccountDocument',
        options: HttpsCallableOptions(timeout: const Duration(minutes: 5)),
      );

      final result = await callable.call({
        'workspaceId': workspaceId,
        'storagePath': storagePath,
      });

      return FinanceMapper.toAnalysisResult(result.data);
    } catch (e, s) {
      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }
}
