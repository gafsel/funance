import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/invite_model.dart';
import '../../domain/repositories/invite_repository.dart';

class InviteRepositoryImpl implements IInviteRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'invites';

  @override
  Future<void> sendInvite(InviteModel invite) async {
    final data = invite.toJson();
    data.remove('id');
    data['createdAt'] = Timestamp.fromDate(invite.createdAt);
    data['status'] = invite.status.name;

    await _firestore.collection(_collection).add(data);
  }

  @override
  Future<List<InviteModel>> getPendingInvites(String email) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('receiverEmail', isEqualTo: email)
        .where('status', isEqualTo: InviteStatus.pending.name)
        .get();

    return snapshot.docs.map((doc) => InviteModel.fromFirestore(doc)).toList();
  }

  @override
  Future<void> respondToInvite(String inviteId, InviteStatus status) async {
    await _firestore.collection(_collection).doc(inviteId).update({
      'status': status.name,
    });
  }
}
