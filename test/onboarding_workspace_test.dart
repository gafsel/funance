import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/firestore/offline_write.dart';
import 'package:funances/features/auth/domain/repositories/auth_repository.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/repositories/account_repository.dart';
import 'package:funances/features/finance/domain/repositories/finance_repository.dart';
import 'package:funances/features/goal/domain/repositories/goal_repository.dart';
import 'package:funances/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:funances/features/onboarding/domain/services/onboarding_service.dart';
import 'package:funances/features/onboarding/presentation/controller/onboarding_notifier.dart';
import 'package:funances/features/arena/domain/models/arena_state.dart';
import 'package:funances/features/user/domain/models/user_model.dart';
import 'package:funances/features/user/domain/repositories/user_repository.dart';
import 'package:funances/features/user/domain/services/user_service.dart';
import 'package:funances/features/workspace/domain/models/workspace_model.dart';
import 'package:funances/features/workspace/domain/repositories/category_repository.dart';
import 'package:funances/features/workspace/domain/repositories/invite_repository.dart';
import 'package:funances/features/workspace/domain/repositories/workspace_repository.dart';
import 'package:funances/features/workspace/domain/services/category_service.dart';
import 'package:funances/features/workspace/presentation/controller/workspace_notifier.dart';

import 'support/fake_analytics.dart';

/// F3.8 (QA) — o workspace nascia ao ENTRAR no passo do nome, ou seja, antes
/// de o usuário digitar qualquer coisa: o documento ia para o Firestore com
/// `name: ""` e só era corrigido um passo depois. Quem desistisse ali deixava
/// um workspace sem nome para trás. Agora ele nasce ao SAIR do passo.

mixin _NaoUsado {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} não usado no teste');
}

class _FakeWorkspaceRepository with _NaoUsado implements IWorkspaceRepository {
  final List<WorkspaceModel> criados = [];
  final List<WorkspaceModel> atualizados = [];

  @override
  Future<Written<WorkspaceModel>> createWorkspace(
    WorkspaceModel workspace,
  ) async {
    criados.add(workspace);
    return (value: workspace, outcome: WriteOutcome.confirmed);
  }

  @override
  Future<WriteOutcome> updateWorkspace(WorkspaceModel workspace) async {
    atualizados.add(workspace);
    return WriteOutcome.confirmed;
  }

  @override
  Future<List<WorkspaceModel>> getUserWorkspaces(String userUid) async => [];

  @override
  Stream<WorkspaceModel?> watchWorkspace(String id) => const Stream.empty();
}

class _FakeAccountRepository with _NaoUsado implements IAccountRepository {
  @override
  Stream<List<AccountModel>> getAccounts(
    String workspaceId, {
    AccountType? type,
  }) => Stream.value(const []);
}

class _NaoUsadoAuth with _NaoUsado implements IAuthRepository {}

class _NaoUsadoCategoria with _NaoUsado implements ICategoryRepository {}

class _NaoUsadoFinance with _NaoUsado implements IFinanceRepository {}

class _NaoUsadoConvite with _NaoUsado implements IInviteRepository {}

class _NaoUsadoMeta with _NaoUsado implements IGoalRepository {}

class _NaoUsadoOnboarding with _NaoUsado implements OnboardingRepository {}

/// Guarda o que foi escrito em `users/{uid}` — é onde o avatar do onboarding
/// tem de aparecer.
class _FakeUserRepository with _NaoUsado implements IUserRepository {
  final List<(String, Map<String, dynamic>)> escritas = [];

  @override
  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    escritas.add((id, data));
  }
}

({
  OnboardingNotifier notifier,
  _FakeWorkspaceRepository workspaces,
  _FakeUserRepository users,
})
_montar({String? avatarAtual}) {
  final workspaces = _FakeWorkspaceRepository();
  final accounts = _FakeAccountRepository();
  final users = _FakeUserRepository();

  final service = OnboardingService(
    user: UserModel(
      id: 'u1',
      email: 'a@b.c',
      avatar: avatarAtual,
      createdAt: DateTime(2026),
    ),
    accountRepository: accounts,
    categoryRepository: _NaoUsadoCategoria(),
    financeRepository: _NaoUsadoFinance(),
    authRepository: _NaoUsadoAuth(),
    onboardingRepository: _NaoUsadoOnboarding(),
    workspaceRepository: workspaces,
    inviteRepository: _NaoUsadoConvite(),
    goalRepository: _NaoUsadoMeta(),
  );

  return (
    notifier: OnboardingNotifier(
      onboardingService: service,
      accountRepository: accounts,
      workspaceNotifier: WorkspaceNotifier(workspaces),
      categoryService: CategoryService(
        workspaceId: 'w1',
        repository: _NaoUsadoCategoria(),
      ),
      userService: UserService(users),
      analytics: FakeAnalyticsService(),
      today: DateTime(2026, 3, 10),
    ),
    workspaces: workspaces,
    users: users,
  );
}

void main() {
  test('o documento NÃO nasce ao entrar no passo do nome', () async {
    final (:notifier, :workspaces, :users) = _montar();

    // type → name: o usuário ainda não digitou nada.
    notifier.setWorkspaceType(WorkspaceType.personal);
    await Future<void>.delayed(Duration.zero);

    expect(notifier.state.currentStep, OnboardingSteps.name);
    expect(workspaces.criados, isEmpty);
    // E nada de `update()` num documento que não existe.
    expect(workspaces.atualizados, isEmpty);
  });

  test('nasce ao sair do passo, com o nome digitado', () async {
    final (:notifier, :workspaces, :users) = _montar();

    notifier.setWorkspaceType(WorkspaceType.personal);
    await Future<void>.delayed(Duration.zero);

    notifier.setWorkspaceName('Casa');
    await notifier.nextStep();

    expect(workspaces.criados, hasLength(1));
    expect(workspaces.criados.single.name, 'Casa');
    expect(workspaces.criados.single.type, WorkspaceType.personal);
    expect(notifier.state.currentStep, OnboardingSteps.accounts);
    expect(notifier.state.workspaceCreated, isTrue);
  });

  test('o passo seguinte atualiza o mesmo documento, sem criar outro', () async {
    final (:notifier, :workspaces, :users) = _montar();

    notifier.setWorkspaceType(WorkspaceType.personal);
    await Future<void>.delayed(Duration.zero);
    notifier.setWorkspaceName('Casa');
    await notifier.nextStep();

    final id = workspaces.criados.single.id;

    // accounts → planning (sem contas, o fluxo pula para invites).
    await notifier.nextStep();

    expect(workspaces.criados, hasLength(1));
    expect(workspaces.atualizados, isNotEmpty);
    expect(workspaces.atualizados.every((w) => w.id == id), isTrue);
  });

  test('o avatar pré-selecionado é o cavaleiro para quem nunca escolheu', () {
    final (:notifier, :workspaces, :users) = _montar();

    expect(notifier.state.avatar, HeroSkin.knight);
  });

  test('quem já tem avatar reabre o onboarding com ele marcado', () {
    final (:notifier, :workspaces, :users) = _montar(avatarAtual: 'healer');

    expect(notifier.state.avatar, HeroSkin.healer);

    // E um segundo cofre não reinicia a escolha do herói.
    notifier.startNew();
    expect(notifier.state.avatar, HeroSkin.healer);
  });

  test('a escolha do avatar vai para users/{uid} ao sair do passo', () async {
    final (:notifier, :workspaces, :users) = _montar();

    notifier.setWorkspaceType(WorkspaceType.personal);
    await Future<void>.delayed(Duration.zero);

    notifier.setAvatar(HeroSkin.ranger);
    notifier.setWorkspaceName('Casa');

    // Escolher não escreve: o usuário experimenta os oito antes de decidir.
    expect(users.escritas, isEmpty);

    await notifier.nextStep();

    expect(users.escritas, hasLength(1));
    expect(users.escritas.single.$1, 'u1');
    expect(users.escritas.single.$2, {'avatar': 'ranger'});
  });

  test('quem pula o seletor sai com o padrão gravado', () async {
    final (:notifier, :workspaces, :users) = _montar();

    notifier.setWorkspaceType(WorkspaceType.personal);
    await Future<void>.delayed(Duration.zero);
    notifier.setWorkspaceName('Casa');
    await notifier.nextStep();

    expect(users.escritas.single.$2, {'avatar': 'knight'});
  });
}
