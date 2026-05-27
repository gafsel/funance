import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/workspace_model.dart';
import '../../domain/repositories/workspace_repository.dart';

class WorkspaceRepositoryImpl implements IWorkspaceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'workspaces';

  @override
  Future<List<WorkspaceModel>> getUserWorkspaces(String userUid) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('members', arrayContains: userUid)
        .get();

    return snapshot.docs.map((doc) => WorkspaceModel.fromFirestore(doc)).toList();
  }

  @override
  Future<WorkspaceModel> createWorkspace(WorkspaceModel workspace) async {
    final docRef = _firestore.collection(_collection).doc(workspace.id.isEmpty ? null : workspace.id);
    final data = workspace.toJson();
    data.remove('id'); // ID is the doc path
    
    // Convert to Timestamp for Firestore
    data['createdAt'] = Timestamp.fromDate(workspace.createdAt);
    
    await docRef.set(data);
    return WorkspaceModel.fromJson({
      ...workspace.toJson(),
      'id': docRef.id,
    });
  }

  @override
  Future<void> updateWorkspace(WorkspaceModel workspace) async {
    final data = workspace.toJson();
    data.remove('id');
    data['createdAt'] = Timestamp.fromDate(workspace.createdAt);
    await _firestore.collection(_collection).doc(workspace.id).update(data);
  }

  @override
  Future<void> deleteWorkspace(String workspaceId) async {
    await _firestore.collection(_collection).doc(workspaceId).delete();
  }
}
