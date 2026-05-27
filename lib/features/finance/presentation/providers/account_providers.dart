import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/workspace/presentation/providers/workspace_providers.dart';
import 'package:funances/features/finance/data/repositories/account_repository_impl.dart';
import 'package:funances/features/finance/domain/repositories/account_repository.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/repositories/finance_repository.dart';
import 'package:funances/features/finance/data/repositories/finance_repository_impl.dart';

final accountRepositoryProvider = Provider<IAccountRepository>((ref) {
  return AccountRepositoryImpl();
});

final financeRepositoryProvider = Provider<IFinanceRepository>((ref) {
  return FinanceRepositoryImpl();
});

final accountsProvider = StreamProvider<List<AccountModel>>((ref) {
  final repository = ref.watch(accountRepositoryProvider);
  final workspace = ref.watch(workspaceNotifierProvider).currentWorkspace;

  if (workspace == null) {
    return Stream.value([]);
  }

  return repository.getAccounts(workspace.id);
});

final accountsByTypeProvider = Provider<AsyncValue<Map<AccountType, List<AccountModel>>>>((ref) {
  final accountsAsync = ref.watch(accountsProvider);
  
  return accountsAsync.whenData((accounts) {
    final Map<AccountType, List<AccountModel>> grouped = {
      for (var type in AccountType.values) type: [],
    };
    
    for (var account in accounts) {
      grouped[account.type]?.add(account);
    }
    
    return grouped;
  });
});

class AccountNotifier extends StateNotifier<AsyncValue<void>> {
  final IAccountRepository _repository;
  final String? _workspaceId;

  AccountNotifier(this._repository, this._workspaceId) : super(const AsyncValue.data(null));

  Future<void> createAccount(AccountModel account) async {
    if (_workspaceId == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.createAccount(_workspaceId, account));
  }

  Future<void> updateAccount(AccountModel account) async {
    if (_workspaceId == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.updateAccount(_workspaceId, account));
  }

  Future<void> deleteAccount(String accountId) async {
    if (_workspaceId == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.deleteAccount(_workspaceId, accountId));
  }
}

final accountNotifierProvider = StateNotifierProvider<AccountNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(accountRepositoryProvider);
  final workspaceId = ref.watch(workspaceNotifierProvider).currentWorkspace?.id;
  return AccountNotifier(repository, workspaceId);
});

final latestAccountBalanceProvider = StreamProvider.family<AccountBalanceModel, String>((ref, accountId) {
  final repository = ref.watch(accountRepositoryProvider);
  final workspaceId = ref.watch(workspaceNotifierProvider).currentWorkspace?.id;

  if (workspaceId == null) {
    return Stream.value(AccountBalanceModel.zero());
  }

  return repository.getLatestAccountBalance(workspaceId, accountId)
      .map((balance) => balance ?? AccountBalanceModel.zero());
});
