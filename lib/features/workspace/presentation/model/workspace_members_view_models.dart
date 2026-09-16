import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/features/user/domain/models/user_model.dart';
import 'package:funances/features/workspace/domain/models/invite_model.dart';

part 'workspace_members_view_models.freezed.dart';

@freezed
sealed class WorkspaceMembersState with _$WorkspaceMembersState {
  const factory WorkspaceMembersState({
    @Default([]) List<UserModel> members,
    @Default([]) List<InviteModel> pendingInvites,
    @Default(true) bool isLoading,
    // O stream de convites começa sem ter emitido nada; sem esta marca a tela
    // mostraria "nenhum convite pendente" antes da primeira resposta.
    @Default(false) bool invitesLoaded,
    @Default(false) bool errorLoading,
    @Default(false) bool errorInvites,
    // Id da linha com operação em curso, para desabilitar só ela.
    String? busyMemberId,
    String? busyInviteId,
  }) = _WorkspaceMembersState;
}
