import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:funances/features/workspace/data/models/workspace_mapper.dart';
import '../../domain/models/workspace_model.dart';
import '../../domain/repositories/workspace_repository.dart';
import 'package:funances/core/exceptions/business_exception.dart';

class WorkspaceRepositoryImpl implements IWorkspaceRepository {
  final _firestore = FirebaseFirestore.instance;
  final String _collection = 'workspaces';

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
      final data = workspace
          .toJson();

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

      return workspace.copyWith(
        id: docRef.id,
      );
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
      final data = workspace.toJson();
      data.remove('id');
      data['createdAt'] = Timestamp.fromDate(workspace.createdAt);
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
