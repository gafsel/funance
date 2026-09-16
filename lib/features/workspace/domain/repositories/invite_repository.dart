import '../models/invite_model.dart';

abstract class IInviteRepository {
  Future<void> sendInvite(InviteModel invite);

  /// Convites pendentes endereçados a [email] — a caixa de entrada de quem
  /// foi convidado.
  Future<List<InviteModel>> getPendingInvites(String email);

  /// Convites pendentes emitidos por um workspace — a lista de "aguardando
  /// resposta" na tela de membros.
  Stream<List<InviteModel>> watchWorkspacePendingInvites(String workspaceId);

  Future<void> respondToInvite(String inviteId, InviteStatus status);

  /// Renova um convite pendente.
  ///
  /// Não há envio de e-mail no projeto: o convite aparece para o destinatário
  /// quando ele entra no app. "Reenviar" então é atualizar `createdAt`, para
  /// o convite voltar ao topo e a data exibida ser a da renovação.
  Future<void> resendInvite(String inviteId);

  /// Apaga um convite ainda pendente.
  Future<void> cancelInvite(String inviteId);
}
