import 'package:uuid/uuid.dart';
import '../../../finance/domain/models/account_model.dart';
import '../../../finance/domain/repositories/account_repository.dart';
import '../../../goal/domain/models/goal_model.dart';
import '../../../goal/domain/repositories/goal_repository.dart';
import '../../../workspace/domain/models/workspace_model.dart';
import '../../../workspace/domain/models/invite_model.dart';
import '../../../workspace/domain/repositories/workspace_repository.dart';
import '../../../workspace/domain/repositories/invite_repository.dart';
import '../../../finance/domain/models/order_model.dart';
import '../../../finance/domain/models/planning_model.dart';
import '../../../finance/domain/repositories/finance_repository.dart';
import '../../../workspace/domain/repositories/category_repository.dart';
import '../../../workspace/domain/models/category_model.dart';
import '../../domain/services/onboarding_service.dart';
import '../../domain/repositories/ai_repository.dart';

class OnboardingService implements IOnboardingService {
  final IWorkspaceRepository _workspaceRepository;
  final IAccountRepository _accountRepository;
  final IGoalRepository _goalRepository;
  final IInviteRepository _inviteRepository;
  final IAIRepository _aiRepository;
  final ICategoryRepository _categoryRepository;
  final IFinanceRepository _financeRepository;

  OnboardingService({
    required IWorkspaceRepository workspaceRepository,
    required IAccountRepository accountRepository,
    required IGoalRepository goalRepository,
    required IInviteRepository inviteRepository,
    required IAIRepository aiRepository,
    required ICategoryRepository categoryRepository,
    required IFinanceRepository financeRepository,
  })  : _workspaceRepository = workspaceRepository,
        _accountRepository = accountRepository,
        _goalRepository = goalRepository,
        _inviteRepository = inviteRepository,
        _aiRepository = aiRepository,
        _categoryRepository = categoryRepository,
        _financeRepository = financeRepository;

  @override
  Future<List<GoalModel>> analyzeAccounts({
    required WorkspaceType workspaceType,
    required List<OrderModel> transactions,
  }) async {
    return _aiRepository.analyzeAccounts(
      workspaceType: workspaceType,
      transactions: transactions,
    );
  }

  @override
  Future<WorkspaceModel> createWorkspace({
    required String userId,
    required String name,
    required WorkspaceType type,
  }) async {
    final workspace = WorkspaceModel(
      id: const Uuid().v4(),
      name: name,
      type: type,
      members: [userId],
      createdAt: DateTime.now(),
    );

    return await _workspaceRepository.createWorkspace(workspace);
  }

  @override
  Future<void> finalizeOnboarding({
    required String userId,
    required String workspaceId,
    required List<AccountModel> accounts,
    required List<GoalModel> goals,
    required List<String> inviteEmails,
    List<OrderModel> orders = const [],
    List<PlanningModel> plannings = const [],
  }) async {
    // 1. Salvar Contas
    for (final account in accounts) {
      await _accountRepository.createAccount(workspaceId, account);
    }

    // 2. Salvar Metas
    for (final goal in goals) {
      await _goalRepository.addGoal(workspaceId, goal);
    }

    // 3. Persistir Transações e Planejamentos (mapeando categorias)
    if (orders.isNotEmpty || plannings.isNotEmpty) {
      final categories = await _categoryRepository.getCategories(workspaceId).first;
      final Map<String, String> categoryMap = {
        for (final c in categories) c.name.toLowerCase(): c.id
      };

      for (final order in orders) {
        final categoryName = order.category.name.toLowerCase();
        final existingCategoryId = categoryMap[categoryName];
        CategoryModel finalCategory;

        if (existingCategoryId == null) {
          // Criar categoria se não existir
          final categoryIdToUse = const Uuid().v4();
          finalCategory = CategoryModel(
            id: categoryIdToUse,
            name: order.category.name,
            color: order.category.color,
            icon: order.category.icon,
            type: order.type == OrderType.income
                ? CategoryType.income
                : CategoryType.expense,
          );
          await _categoryRepository.createCategory(workspaceId, finalCategory);
          categoryMap[categoryName] = categoryIdToUse;
        } else {
          finalCategory = order.category.copyWith(id: existingCategoryId);
        }

        // Recuperar o accountId do metadata da order (preenchido no AccountFormNotifier)
        final String? accountId = order.metadata?['accountId'];

        await _financeRepository.addOrder(
          workspaceId,
          order.copyWith(
            category: finalCategory,
            metadata: {
              ...(order.metadata ?? {}),
              'accountId': accountId,
            }..removeWhere((key, value) => value == null),
          ),
        );
      }

      for (final planning in plannings) {
        final categoryName = planning.category.name.toLowerCase();
        final existingCategoryId = categoryMap[categoryName];
        CategoryModel finalCategory;

        if (existingCategoryId == null) {
          final categoryIdToUse = const Uuid().v4();
          finalCategory = CategoryModel(
            id: categoryIdToUse,
            name: planning.category.name,
            color: planning.category.color,
            icon: planning.category.icon,
            type: CategoryType.expense,
          );
          await _categoryRepository.createCategory(workspaceId, finalCategory);
          categoryMap[categoryName] = categoryIdToUse;
        } else {
          finalCategory = planning.category.copyWith(id: existingCategoryId);
        }

        // Tenta recuperar o accountId para associar ao planejamento, se disponível no metadata
        final String? accountId = planning.metadata?['accountId'];

        await _financeRepository.addPlanning(
          workspaceId,
          planning.copyWith(
            category: finalCategory,
            metadata: {
              ...(planning.metadata ?? {}),
              'accountId': accountId,
            }..removeWhere((key, value) => value == null),
          ),
        );
      }
    }

    // 4. Enviar Convites
    if (inviteEmails.isNotEmpty) {
      final workspace = await _workspaceRepository.getWorkspace(workspaceId);
      if (workspace != null) {
        for (final email in inviteEmails) {
          final invite = InviteModel(
            id: '',
            workspace: workspace,
            senderId: userId,
            senderName: userId,
            receiverEmail: email,
            status: InviteStatus.pending,
            createdAt: DateTime.now(),
          );
          await _inviteRepository.sendInvite(invite);
        }
      }
    }
  }

  @override
  Future<AnalysisResult> analyzeDocument({
    required String storagePath,
    required String fileName,
    required List<String> existingCategories,
  }) async {
    return _aiRepository.analyzeDocument(
      storagePath: storagePath,
      fileName: fileName,
      existingCategories: existingCategories,
    );
  }
}
