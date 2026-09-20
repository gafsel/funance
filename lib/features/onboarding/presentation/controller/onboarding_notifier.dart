import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/analytics/analytics_service.dart';
import 'package:funances/features/arena/domain/models/arena_state.dart';
import 'package:funances/features/finance/domain/models/category_planning_model.dart';
import 'package:funances/features/finance/domain/repositories/account_repository.dart';
import 'package:funances/features/onboarding/domain/models/onboarding_models.dart';
import 'package:funances/features/onboarding/presentation/model/onboarding_view_models.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/user/domain/services/user_service.dart';
import 'package:funances/features/workspace/domain/services/category_service.dart';
import 'package:funances/features/workspace/presentation/controller/workspace_notifier.dart';
import 'package:uuid/uuid.dart';

import '../../../goal/domain/models/goal_model.dart';
import '../../../workspace/domain/models/workspace_model.dart';
import '../../domain/services/onboarding_service.dart';

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final OnboardingService onboardingService;
  final IAccountRepository accountRepository;
  final WorkspaceNotifier workspaceNotifier;
  final CategoryService categoryService;

  /// Só para gravar o avatar: o documento do usuário é dele, não do
  /// workspace, e o onboarding é o primeiro lugar onde ele escolhe um herói.
  final UserService userService;

  final AnalyticsService analytics;

  /// Dia corrente, do relógio injetado. Os planejamentos sugeridos valem a
  /// partir do mês em que o onboarding acontece.
  final DateTime today;

  OnboardingNotifier({
    required this.onboardingService,
    required this.accountRepository,
    required this.workspaceNotifier,
    required this.categoryService,
    required this.userService,
    required this.analytics,
    required this.today,
  }) : super(
         OnboardingState(
           workspace: WorkspaceModel.empty(),
           avatar: HeroSkin.tryFromName(onboardingService.user.avatar),
         ),
       );

  void load(WorkspaceModel workspace) {
    if (state.workspace.id != workspace.id) {
      state = state.copyWith(
        workspace: workspace,
        currentStep: workspace.lastOnboardingStep ?? OnboardingSteps.accounts,
        // Retomar um onboarding é continuar de um documento que já existe.
        workspaceCreated: true,
      );
    }
  }

  /// Reinicia o fluxo do zero para a criação de um novo workspace,
  /// descartando o estado de um onboarding anterior (que pode já estar
  /// em `done` e deixaria a tela inerte).
  void startNew() {
    state = OnboardingState(
      workspace: WorkspaceModel.empty(),
      // O avatar NÃO é do workspace: quem cria o segundo cofre continua sendo
      // o mesmo herói do primeiro.
      avatar: HeroSkin.tryFromName(onboardingService.user.avatar),
    );
  }

  Future<void> nextStep() async {
    if (state.currentStep != OnboardingSteps.done) {
      var nextStep = OnboardingSteps.values[state.currentStep.index + 1];

      switch (nextStep) {
        case OnboardingSteps.planning:
          final accounts = await accountRepository
              .getAccounts(state.workspace.id)
              .first;
          if (accounts.isNotEmpty) {
            await _analyzePlanning();
          } else {
            nextStep = OnboardingSteps.invites;
          }
          break;
        case OnboardingSteps.invites:
          await _savePlanning();
          break;
        case OnboardingSteps.accounts:
          // O passo que fica para trás aqui é o do PERFIL — nome do cofre e
          // herói do usuário —, e é ao sair dele que a escolha do boneco vai
          // para `users/{uid}`.
          await _saveAvatar();

          // O workspace nasce ao SAIR do passo do nome, não ao entrar nele:
          // criado na entrada, ele ia para o Firestore com o nome VAZIO (o
          // usuário ainda não tinha digitado) e só era corrigido um passo
          // depois. Quem abandonasse ali deixava um workspace sem nome para
          // trás.
          if (!state.workspaceCreated) await _createWorkspace();
          break;
        case OnboardingSteps.success:
          await _sendInvites();
          break;
        case OnboardingSteps.done:
          break;
        default:
          break;
      }

      if (state.workspaceCreated) {
        await onboardingService.updateWorkspace(
          state.workspace.copyWith(lastOnboardingStep: nextStep),
        );
      }

      // Registra a etapa alcançada, inclusive a final, para fechar o funil.
      try {
        await analytics.logOnboardingStep(nextStep.name);
      } catch (_) {}

      if (nextStep == OnboardingSteps.done) {
        await workspaceNotifier.loadWorkspaces(
          onboardingService.user.id,
          state.workspace.id,
        );
      } else {
        state = state.copyWith(currentStep: nextStep);
      }
    }
  }

  void previousStep() {
    if (state.currentStep != OnboardingSteps.type) {
      state = state.copyWith(
        currentStep: OnboardingSteps.values[state.currentStep.index - 1],
      );
    }
  }

  void setWorkspaceType(WorkspaceType type) {
    state = state.copyWith(workspace: state.workspace.copyWith(type: type));

    nextStep();
  }

  void setWorkspaceName(String name) {
    state = state.copyWith(workspace: state.workspace.copyWith(name: name));
  }

  void setAvatar(HeroSkin avatar) => state = state.copyWith(avatar: avatar);

  /// Grava o avatar escolhido em `users/{uid}` — **se houve escolha**.
  ///
  /// Roda ao SAIR do passo do perfil, junto com a criação do workspace, e
  /// não a cada toque na grade: o usuário experimenta os oito bonecos antes
  /// de decidir, e cada experimentação seria uma escrita no Firestore.
  ///
  /// Quem passou direto não gera escrita nenhuma. A ausência do campo é uma
  /// informação — "este aqui não escolheu" —, e escrever `knight` no lugar
  /// dela apagaria justamente o que faz o segundo membro do cofre nascer
  /// mago em vez de um cavaleiro repetido.
  ///
  /// Uma falha aqui não derruba o onboarding. O avatar é enfeite; perder o
  /// cofre inteiro porque o boneco não salvou seria a troca errada.
  Future<void> _saveAvatar() async {
    final escolhido = state.avatar;
    if (escolhido == null) return;

    try {
      await userService.updateAvatar(
        id: onboardingService.user.id,
        avatar: escolhido.name,
      );
    } catch (_) {}
  }

  Future<void> _analyzePlanning() async {
    final suggestions = await onboardingService.analysePlanning(
      workspaceId: state.workspace.id,
    );

    state = state.copyWith(planningSuggestions: suggestions);
  }

  Future<void> removeOnboardingAccount(String accountId) async {
    await accountRepository.deleteAccount(state.workspace.id, accountId);
  }

  Future<void> removeGoal(GoalModel goal) async {
    state = state.copyWith(
      planningSuggestions: state.planningSuggestions?.copyWith(
        goals:
            state.planningSuggestions?.goals.where((g) => g != goal).toList() ??
            [],
      ),
    );
  }

  Future<void> removePlanning(CategoryPlanningModel planning) async {
    state = state.copyWith(
      planningSuggestions: state.planningSuggestions?.copyWith(
        plannings:
            state.planningSuggestions?.plannings
                .where((p) => p != planning)
                .toList() ??
            [],
      ),
    );
  }

  void addInviteEmail(String email) {
    if (state.inviteEmails.contains(email)) return;

    state = state.copyWith(inviteEmails: [...state.inviteEmails, email]);
  }

  void removeInviteEmail(String email) {
    state = state.copyWith(
      inviteEmails: state.inviteEmails.where((e) => e != email).toList(),
    );
  }

  Future<void> _sendInvites() async {
    await onboardingService.sendInvitations(
      workspace: state.workspace,
      inviteEmails: state.inviteEmails,
    );
  }

  Future<void> _savePlanning() async {
    // 1. Garantir que as categorias existam
    final categories = [...await categoryService.getCategories().first];

    // 2. Processar Orders
    final processedPeriodSummaries = <CategoryPlanningModel>[];
    for (final planning
        in state.planningSuggestions?.plannings ??
            const <CategoryPlanningModel>[]) {
      final category = await _findOrCreateCategory(
        categories,
        planning.category,
      );

      processedPeriodSummaries.add(planning.copyWith(category: category));
    }

    await onboardingService.savePlanning(
      state.workspace,
      (state.planningSuggestions ?? PlanningSuggestions()).copyWith(
        plannings: processedPeriodSummaries,
      ),
      today: today,
    );
  }

  Future<CategoryModel> _findOrCreateCategory(
    List<CategoryModel> categories,
    CategoryModel category,
  ) async {
    final CategoryModel? found = categories.where((c) {
      if (category.isVirtual && c.id == category.id) return true;

      return c.type == category.type &&
          c.name.toLowerCase() == category.name.toLowerCase();
    }).firstOrNull;

    if (found == null) {
      final newCategory = (await categoryService.create(
        category.copyWith(id: const Uuid().v4()),
      )).value;

      categories.add(newCategory);

      return newCategory;
    }

    return found;
  }

  Future<void> _createWorkspace() async {
    final workspace = await onboardingService.createWorkspace(
      type: state.workspace.type,
      name: state.workspace.name,
    );

    state = state.copyWith(workspace: workspace, workspaceCreated: true);

    await workspaceNotifier.loadWorkspaces(
      onboardingService.user.id,
      state.workspace.id,
      true,
    );
  }
}
