import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:funances/features/workspace/data/models/workspace_mapper.dart';
import 'package:funances/features/user/domain/models/user_model.dart';
import 'package:funances/features/workspace/domain/models/workspace_model.dart';
import 'package:funances/features/workspace/domain/repositories/workspace_repository.dart';
import 'package:funances/core/exceptions/business_exception.dart';

class WorkspaceRepositoryImpl implements IWorkspaceRepository {
  final _firestore = FirebaseFirestore.instance;
  final _functions = FirebaseFunctions.instance;
  final String _collection = 'workspaces';

  @override
  Future<List<UserModel>> getWorkspaceMembers(String workspaceId) async {
    try {
      final result = await _functions.httpsCallable('getWorkspaceMembers').call(
        {'workspaceId': workspaceId},
      );

      final List<dynamic> membersData = result.data as List<dynamic>;

      return membersData.map((data) {
        return UserModel.fromJson(Map<String, dynamic>.from(data as Map));
      }).toList();
    } catch (e, s) {
      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<List<WorkspaceModel>> getUserWorkspaces(String userUid) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('members', arrayContains: userUid)
          .get();

      return snapshot.docs.map((doc) => doc.toWorkspaceModel()).toList();
    } catch (e, s) {
      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<WorkspaceModel> createWorkspace(WorkspaceModel workspace) async {
    try {
      final data = workspace.toJson();

      data.remove('id'); // ID is the doc path

      // Convert to Timestamp for Firestore
      data['createdAt'] = Timestamp.now();

      DocumentReference docRef;
      if (workspace.id.isEmpty) {
        docRef = await _firestore.collection(_collection).add(data);
      } else {
        docRef = _firestore.collection(_collection).doc(workspace.id);

        await docRef.set(data);
      }

      return workspace.copyWith(id: docRef.id);
    } catch (e, s) {
      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<WorkspaceModel?> getWorkspace(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) return null;
      return doc.toWorkspaceModel();
    } catch (e, s) {
      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> updateWorkspace(WorkspaceModel workspace) async {
    try {
      // Grava apenas os campos editáveis pelo usuário. Campos de gamificação
      // (xp, level, unlockedBadges, weeklyStreaks, lastLevelUpAt) e members
      // são mantidos pelo servidor; incluí-los aqui causaria lost update.
      final json = workspace.toJson();
      final data = <String, dynamic>{
        'name': json['name'],
        'type': json['type'],
        'lastOnboardingStep': json['lastOnboardingStep'],
        'onboardingCompleted': json['onboardingCompleted'],
      };
      await _firestore.collection(_collection).doc(workspace.id).update(data);
    } catch (e, s) {
      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }

  @override
  Stream<WorkspaceModel?> watchWorkspace(String id) {
    return _firestore
        .collection(_collection)
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? doc.toWorkspaceModel() : null);
  }

  @override
  Future<void> deleteWorkspace(String workspaceId) async {
    try {
      await _firestore.collection(_collection).doc(workspaceId).delete();
    } catch (e, s) {
      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }
}
