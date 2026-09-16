import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/analytics/analytics_service.dart';
import 'package:funances/core/exceptions/business_exception.dart';
import 'package:funances/features/user/domain/models/user_model.dart';
import 'package:funances/features/workspace/domain/models/invite_model.dart';
import 'package:funances/features/workspace/domain/repositories/invite_repository.dart';
import 'package:funances/features/workspace/domain/services/workspace_service.dart';
import 'package:funances/features/workspace/presentation/model/workspace_members_view_models.dart';

/// Membros do workspace e convites ainda sem resposta.
///
/// A lista de membros vem de uma callable (o cliente não lê `users/{uid}` de
/// outra pessoa) e por isso é recarregada sob demanda; os convites vêm de um
/// stream do Firestore, porque o aceite chega de fora e a tela precisa
/// perceber sozinha.
class WorkspaceMembersNotifier extends StateNotifier<WorkspaceMembersState> {
  final WorkspaceService workspaceService;
  final IInviteRepository inviteRepository;
  final AnalyticsService analytics;
  final String workspaceId;

  /// Dono do workspace: o criador, que é `members[0]`. Mesma definição do
  /// `assertWorkspaceOwner` no backend e da rule `isWorkspaceOwner`.
  final String? ownerId;

  /// Usuário logado, para não oferecer "remover" a si mesmo.
  final String? currentUserId;

  StreamSubscription<List<InviteModel>>? _invitesSubscription;

  WorkspaceMembersNotifier({
    required this.workspaceService,
    required this.inviteRepository,
    required this.analytics,
    required this.workspaceId,
    required this.ownerId,
    required this.currentUserId,
  }) : super(const WorkspaceMembersState()) {
    unawaited(loadMembers());
    _watchInvites();
  }

  bool get isOwner => ownerId != null && ownerId == currentUserId;

  Future<void> loadMembers() async {
    state = state.copyWith(isLoading: true, errorLoading: false);

    try {
      final members = await workspaceService.getWorkspaceMembers(workspaceId);

      if (!mounted) return;
      state = state.copyWith(members: members, isLoading: false);
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, errorLoading: true);
    }
  }

  void _watchInvites() {
    _invitesSubscription?.cancel();
    _invitesSubscription = inviteRepository
        .watchWorkspacePendingInvites(workspaceId)
        .listen(
          (invites) {
            if (!mounted) return;
            state = state.copyWith(
              pendingInvites: invites,
              invitesLoaded: true,
            );
          },
          onError: (Object _) {
            if (!mounted) return;
            state = state.copyWith(invitesLoaded: true, errorInvites: true);
          },
        );
  }

  /// Remove um membro. Devolve `null` em caso de sucesso e a mensagem do
  /// servidor quando ele recusa (não é dono, tentou remover a si mesmo).
  Future<String?> removeMember(UserModel member) async {
    state = state.copyWith(busyMemberId: member.id);

    try {
      await workspaceService.removeWorkspaceMember(workspaceId, member.id);

      // Analytics não pode derrubar a remoção, que já aconteceu no servidor.
      try {
        await analytics.logMemberRemoved();
      } catch (_) {}

      if (!mounted) return null;
      state = state.copyWith(
        members: state.members.where((m) => m.id != member.id).toList(),
        busyMemberId: null,
      );

      return null;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(busyMemberId: null);
      }

      return _messageOf(e);
    }
  }

  Future<String?> resendInvite(InviteModel invite) async {
    state = state.copyWith(busyInviteId: invite.id);

    try {
      await inviteRepository.resendInvite(invite.id);
      return null;
    } catch (e) {
      return _messageOf(e);
    } finally {
      if (mounted) {
        state = state.copyWith(busyInviteId: null);
      }
    }
  }

  Future<String?> cancelInvite(InviteModel invite) async {
    state = state.copyWith(busyInviteId: invite.id);

    try {
      await inviteRepository.cancelInvite(invite.id);
      return null;
    } catch (e) {
      return _messageOf(e);
    } finally {
      if (mounted) {
        state = state.copyWith(busyInviteId: null);
      }
    }
  }

  /// Texto que o servidor mandou, quando existe ("apenas o dono pode...",
  /// "não pode remover a si mesmo"). Nulo faz a tela usar o próprio texto
  /// genérico, porque erro interno não é mensagem para o usuário.
  static String? _messageOf(Object error) {
    if (error is! BusinessException) return null;

    final message = error.message?.trim();

    return message == null || message.isEmpty ? null : message;
  }

  @override
  void dispose() {
    _invitesSubscription?.cancel();
    super.dispose();
  }
}
