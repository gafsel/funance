import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/features/workspace/domain/models/workspace_model.dart';

part 'workspace_view_model.freezed.dart';

@freezed
sealed class WorkspaceState with _$WorkspaceState {
  const factory WorkspaceState({
    WorkspaceModel? currentWorkspace,
    @Default([]) List<WorkspaceModel> availableWorkspaces,
    @Default(false) bool isLoading,
    @Default(false) bool initialLoadDone,
  }) = _WorkspaceState;
}

/// Recorte de gamificação do workspace corrente.
///
/// O doc do workspace é observado em tempo real, então XP, nível, badges e
/// streak mudam a toda hora. As telas que celebram esses eventos observam só
/// este recorte (via `select`), e os serviços observam só o id — assim um
/// ganho de XP não recria FinanceService, AccountService & cia. nem reassina
/// os streams do Firestore.
@freezed
sealed class WorkspaceGamification with _$WorkspaceGamification {
  const factory WorkspaceGamification({
    String? workspaceId,
    @Default(0) int xp,
    @Default(1) int level,

    /// Semanas seguidas com as três missões da semana concluídas. É o que o
    /// fogo ao lado do título conta.
    @Default(0) int weeklyStreaks,

    /// Semanas seguidas dentro do planejamento. O placar do servidor começou
    /// a publicar isto junto com as missões; ainda não tem lugar na tela, mas
    /// entra no recorte para não ser descartado na leitura.
    @Default(0) int planStreak,
    @Default({}) Map<String, String> unlockedBadges,
  }) = _WorkspaceGamification;
}

extension WorkspaceGamificationExtension on WorkspaceModel {
  WorkspaceGamification get gamification => WorkspaceGamification(
    workspaceId: id,
    xp: xp,
    level: level,
    weeklyStreaks: weeklyStreaks.missions,
    planStreak: weeklyStreaks.plan,
    unlockedBadges: unlockedBadges,
  );
}
