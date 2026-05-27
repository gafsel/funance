import '../models/invite_model.dart';

abstract class IInviteRepository {
  Future<void> sendInvite(InviteModel invite);
  Future<List<InviteModel>> getPendingInvites(String email);
  Future<void> respondToInvite(String inviteId, InviteStatus status);
}
