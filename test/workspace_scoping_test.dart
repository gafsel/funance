import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/firestore/offline_write.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/repositories/account_repository.dart';
import 'package:funances/features/finance/domain/services/account_service.dart';
import 'package:funances/features/goal/domain/models/goal_model.dart';
import 'package:funances/features/goal/domain/repositories/goal_repository.dart';
import 'package:funances/features/goal/domain/services/goal_service.dart';
import 'package:funances/features/user/domain/models/user_model.dart';
import 'package:funances/features/user/domain/repositories/user_repository.dart';
import 'package:funances/features/user/domain/services/user_service.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/domain/repositories/category_repository.dart';
import 'package:funances/features/workspace/domain/repositories/workspace_repository.dart';
import 'package:funances/features/workspace/domain/services/category_service.dart';

/// Os serviços "finos" existem por UMA razão: prender cada escrita e cada
/// leitura ao workspace corrente. O repositório aceita qualquer
/// `workspaceId`; é o serviço que garante que ele seja o certo.
///
/// Não é um teste de lógica — é um teste de VAZAMENTO. Um `workspaceId`
/// esquecido ou trocado aqui mostraria (ou gravaria) o dinheiro de uma
/// família no workspace de outra, e nenhum outro teste do app olhava para
/// isso.

mixin _NaoUsado {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} não usado no teste');
}

class _CategoriasEspia with _NaoUsado implements ICategoryRepository {
  final List<String> escopos = [];

  @override
  Stream<List<CategoryModel>> getCategories(String workspaceId) {
    escopos.add(workspaceId);
    return Stream.value(const []);
  }

  @override
  Future<Written<CategoryModel>> createCategory(
    String workspaceId,
    CategoryModel category,
  ) async {
    escopos.add(workspaceId);
    return (value: category, outcome: WriteOutcome.confirmed);
  }

  @override
  Future<WriteOutcome> updateCategory(
    String workspaceId,
    CategoryModel category,
  ) async {
    escopos.add(workspaceId);
    return WriteOutcome.confirmed;
  }

  @override
  Future<void> deleteCategory(String workspaceId, String categoryId) async {
    escopos.add(workspaceId);
  }

  @override
  Future<CategoryModel> getCategory(String workspaceId, String id) async {
    escopos.add(workspaceId);
    return CategoryModel(id: id, name: id, icon: 'x', color: '#000000');
  }
}

class _MetasEspia with _NaoUsado implements IGoalRepository {
  final List<String> escopos = [];

  @override
  Future<Written<GoalModel>> addGoal(String workspaceId, GoalModel goal) async {
    escopos.add(workspaceId);
    return (value: goal, outcome: WriteOutcome.confirmed);
  }

  @override
  Stream<List<GoalModel>> watchGoals(String workspaceId) {
    escopos.add(workspaceId);
    return Stream.value(const []);
  }

  @override
  Future<WriteOutcome> updateGoal(String workspaceId, GoalModel goal) async {
    escopos.add(workspaceId);
    return WriteOutcome.confirmed;
  }

  @override
  Future<void> deleteGoal(String workspaceId, String goalId) async {
    escopos.add(workspaceId);
  }
}

class _ContasEspia with _NaoUsado implements IAccountRepository {
  _ContasEspia([this.contas = const []]);

  final List<AccountModel> contas;
  final List<String> escopos = [];

  @override
  Stream<List<AccountModel>> getAccounts(
    String workspaceId, {
    AccountType? type,
  }) {
    escopos.add(workspaceId);
    return Stream.value(contas);
  }

  @override
  Future<Written<AccountModel>> createAccount(
    String workspaceId,
    AccountModel account,
  ) async {
    escopos.add(workspaceId);
    return (value: account, outcome: WriteOutcome.confirmed);
  }

  @override
  Future<WriteOutcome> updateAccount(
    String workspaceId,
    AccountModel account,
  ) async {
    escopos.add(workspaceId);
    return WriteOutcome.confirmed;
  }

  @override
  Future<void> deleteAccount(String workspaceId, String accountId) async {
    escopos.add(workspaceId);
  }

  @override
  Stream<AccountBalanceModel?> getLatestAccountBalanceBeforeDate(
    String workspaceId,
    String accountId,
    DateTime date,
  ) {
    escopos.add(workspaceId);
    return Stream.value(null);
  }
}

class _MembrosEspia with _NaoUsado implements IWorkspaceRepository {
  final List<String> escopos = [];

  @override
  Future<List<UserModel>> getWorkspaceMembers(String workspaceId) async {
    escopos.add(workspaceId);
    return const [];
  }
}

class _UsuariosEspia with _NaoUsado implements IUserRepository {
  final List<Map<String, dynamic>> atualizacoes = [];

  @override
  Future<UserModel?> getUserById(String id) async =>
      UserModel(id: id, email: '$id@b.com', createdAt: DateTime(2026, 1, 1));

  @override
  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    atualizacoes.add({'id': id, ...data});
  }
}

AccountModel _conta(String id) => AccountModel.checking(
  id: id,
  name: 'Conta $id',
  icon: 'account_balance',
  color: '#000000',
  initialBalanceDate: DateTime(2026, 1, 1),
);

GoalModel _meta() => GoalModel.saveMoney(
  id: 'g1',
  name: 'Reserva',
  targetAmount: 1000,
  currentAmount: 0,
  deadline: DateTime(2026, 12, 31),
  accountId: 'acc-1',
  startDate: DateTime(2026, 1, 1),
);

void main() {
  test('CategoryService prende todas as operações ao workspace', () async {
    final repo = _CategoriasEspia();
    final servico = CategoryService(workspaceId: 'ws-1', repository: repo);

    const categoria = CategoryModel(
      id: 'c1',
      name: 'Mercado',
      icon: 'x',
      color: '#000000',
    );

    await servico.getCategories().first;
    await servico.create(categoria);
    await servico.update(categoria);
    await servico.delete('c1');
    await servico.getCategory('c1');

    expect(repo.escopos, hasLength(5));
    expect(repo.escopos, everyElement('ws-1'));
  });

  test('GoalService idem — meta é dinheiro de um workspace só', () async {
    final repo = _MetasEspia();
    final servico = GoalService(workspaceId: 'ws-2', repository: repo);

    await servico.watchGoals().first;
    await servico.addGoal(_meta());
    await servico.updateGoal(_meta());
    await servico.deleteGoal('g1');

    expect(repo.escopos, hasLength(4));
    expect(repo.escopos, everyElement('ws-2'));
  });

  group('AccountService', () {
    test('prende as operações de conta ao workspace', () async {
      final contas = _ContasEspia();
      final membros = _MembrosEspia();
      final servico = AccountService(
        workspaceId: 'ws-3',
        repository: contas,
        workspaceRepository: membros,
      );

      await servico.getAccounts().first;
      await servico.create(_conta('a'));
      await servico.update(_conta('a'));
      await servico.delete('a');
      await servico.getWorkspaceMembers();

      expect(contas.escopos, everyElement('ws-3'));
      expect(membros.escopos, ['ws-3']);
    });

    test('saldo ausente vira ZERO, e não um stream de nulo', () async {
      // A tela mostra saldo; um `null` aqui viraria "—" ou uma exceção no
      // formatador. Conta recém-criada, sem nenhum lançamento, tem saldo
      // zero — é uma afirmação verdadeira, não a falta de uma.
      final servico = AccountService(
        workspaceId: 'ws',
        repository: _ContasEspia(),
        workspaceRepository: _MembrosEspia(),
      );

      final saldo = await servico.getLatestAccountBalance('acc-1').first;
      expect(saldo.balance, 0);

      final data = DateTime(2026, 3, 10);
      final naData = await servico.getAccountBalanceAtDate('acc-1', data).first;
      expect(naData.balance, 0);
    });

    test('getAccountsByType devolve TODOS os tipos, mesmo os vazios', () async {
      // A tela de contas desenha uma seção por tipo; um tipo ausente do mapa
      // seria uma seção que some em vez de aparecer vazia.
      final servico = AccountService(
        workspaceId: 'ws',
        repository: _ContasEspia([_conta('a')]),
        workspaceRepository: _MembrosEspia(),
      );

      final porTipo = await servico.getAccountsByType().first;

      expect(porTipo.keys, containsAll(AccountType.values));
      expect(porTipo[AccountType.checking], hasLength(1));
      expect(porTipo[AccountType.debt], isEmpty);
    });
  });

  group('UserService.updateProfile', () {
    test('só manda o que mudou', () async {
      final repo = _UsuariosEspia();

      await UserService(repo).updateProfile(id: 'u1', displayName: 'Gabriel');

      expect(repo.atualizacoes.single, {'id': 'u1', 'displayName': 'Gabriel'});
    });

    test('sem nenhum campo, não escreve nada', () async {
      // Uma escrita vazia gastaria uma operação e sujaria o `updatedAt` do
      // documento por nada.
      final repo = _UsuariosEspia();

      await UserService(repo).updateProfile(id: 'u1');

      expect(repo.atualizacoes, isEmpty);
    });

    test('lê o usuário pelo id', () async {
      final usuario = await UserService(_UsuariosEspia()).getUser('u1');
      expect(usuario?.id, 'u1');
    });
  });
}
