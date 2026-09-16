import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:funances/features/finance/domain/repositories/account_repository.dart';
import '../../domain/models/reconciliation_model.dart';
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
  Future<AccountModel> createAccount(
    String workspaceId,
    AccountModel account,
  ) async {
    try {
      final data = account.toJson();
      data.remove('id');
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
  Future<AccountModel> getAccount(String workspaceId, String accountId) async {
    try {
      final doc = await _getCollection(workspaceId).doc(accountId).get();
      if (!doc.exists) {
        throw BusinessException(
          ErrorCode.unknown,
          message: 'Account not found',
        );
      }
      return doc.toAccountModel();
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
    return _getCollection(workspaceId)
        .doc(accountId)
        .collection('balance')
        .orderBy(FieldPath.documentId, descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return snapshot.docs.first.toAccountBalanceModel();
        });
  }

  @override
  Stream<AccountBalanceModel?> getLatestAccountBalanceBeforeDate(
    String workspaceId,
    String accountId,
    DateTime date,
  ) {
    final dateId = date.toIso8601String().split('T')[0];
    return _getCollection(workspaceId)
        .doc(accountId)
        .collection('balance')
        .where(FieldPath.documentId, isLessThanOrEqualTo: dateId)
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
      final String name = file.path.split("/").last;

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
    } on FirebaseFunctionsException catch (e, s) {
      throw _fromCallable(e, s);
    } catch (e, s) {
      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<List<ReconciliationTransaction>> analyzeReconciliationDocument(
    String workspaceId,
    File file, {
    String? uploadId,
  }) async {
    try {
      final String name = file.path.split("/").last;

      // 1. Upload para o Storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath =
          'workspaces/$workspaceId/reconciliation/${_auth.currentUser!.uid}_${timestamp}_$name';

      await _storage.ref().child(storagePath).putData(file.readAsBytesSync());

      final callable = _functions.httpsCallable(
        'analyzeReconciliationDocument',
        options: HttpsCallableOptions(timeout: const Duration(minutes: 5)),
      );

      final result = await callable.call({
        'workspaceId': workspaceId,
        'storagePath': storagePath,
        'uploadId': ?uploadId,
      });

      final data = Map<String, dynamic>.from(result.data as Map);
      final rawTransactions = data['transactions'];
      final transactions = rawTransactions is List ? rawTransactions : const [];
      return transactions
          .map((t) => FinanceMapper.toReconciliationTransaction(t))
          .toList();
    } on FirebaseFunctionsException catch (e, s) {
      log("Failed to analyze reconciliation document", error: e, stackTrace: s);

      throw _fromCallable(e, s);
    } catch (e, s) {
      log("Failed to analyze reconciliation document", error: e, stackTrace: s);

      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }

  /// Converte a falha do callable preservando código e mensagem do servidor.
  ///
  /// Colapsar tudo em `BusinessException(ErrorCode.unknown)` sem `message`
  /// fazia a tela mostrar "ErrorCode.unknown" no lugar do texto que o servidor
  /// tinha acabado de escrever ("arquivo maior que 10 MB", "cota diária
  /// esgotada"). Quem decide qual mensagem chega ao usuário é
  /// `callableErrorMessage`, que lê o erro original.
  static BusinessException _fromCallable(
    FirebaseFunctionsException error,
    StackTrace stackTrace,
  ) => BusinessException(
    ErrorCode.unknown,
    message: error.message,
    originalError: error,
    stackTrace: stackTrace,
  );
}
