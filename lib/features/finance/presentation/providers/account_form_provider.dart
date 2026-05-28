import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:funances/features/workspace/presentation/providers/category_providers.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/presentation/providers/account_providers.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/models/planning_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/presentation/providers/workspace_providers.dart';
import 'package:uuid/uuid.dart';

enum AccountRegistrationMethod { document, manual }

class AccountFormState {
  final String name;
  final double initialBalance;
  final DateTime initialBalanceDate;
  final AccountType type;
  final String color;
  final String icon;
  final Map<String, dynamic> metadata;
  final File? selectedFile;
  final String? fileName;
  final AccountProcessingStatus processingStatus;
  final AccountRegistrationMethod registrationMethod;
  final List<OrderModel> detectedOrders;
  final List<PlanningModel> detectedPlannings;
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;

  AccountFormState({
    required this.name,
    required this.initialBalance,
    required this.initialBalanceDate,
    required this.type,
    required this.color,
    required this.icon,
    this.metadata = const {},
    this.selectedFile,
    this.fileName,
    this.processingStatus = AccountProcessingStatus.none,
    this.registrationMethod = AccountRegistrationMethod.document,
    this.detectedOrders = const [],
    this.detectedPlannings = const [],
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
  });

  factory AccountFormState.initial(AccountModel? account, AccountType? initialType) {
    return AccountFormState(
      name: account?.name ?? '',
      initialBalance: account?.initialBalance ?? 0.0,
      initialBalanceDate: account?.initialBalanceDate ?? DateTime.now(),
      type: account?.type ?? initialType ?? AccountType.checking,
      color: account?.color ?? '#4A8C9C',
      icon: account?.icon ?? 'account_balance',
      metadata: account?.metadata ?? {},
      fileName: account?.fileName,
      processingStatus: account?.processingStatus ?? AccountProcessingStatus.none,
      registrationMethod: account != null ? AccountRegistrationMethod.manual : AccountRegistrationMethod.document,
    );
  }

  AccountFormState copyWith({
    String? name,
    double? initialBalance,
    DateTime? initialBalanceDate,
    AccountType? type,
    String? color,
    String? icon,
    Map<String, dynamic>? metadata,
    File? selectedFile,
    String? fileName,
    AccountProcessingStatus? processingStatus,
    AccountRegistrationMethod? registrationMethod,
    List<OrderModel>? detectedOrders,
    List<PlanningModel>? detectedPlannings,
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
  }) {
    return AccountFormState(
      name: name ?? this.name,
      initialBalance: initialBalance ?? this.initialBalance,
      initialBalanceDate: initialBalanceDate ?? this.initialBalanceDate,
      type: type ?? this.type,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      metadata: metadata ?? this.metadata,
      selectedFile: selectedFile ?? this.selectedFile,
      fileName: fileName ?? this.fileName,
      processingStatus: processingStatus ?? this.processingStatus,
      registrationMethod: registrationMethod ?? this.registrationMethod,
      detectedOrders: detectedOrders ?? this.detectedOrders,
      detectedPlannings: detectedPlannings ?? this.detectedPlannings,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
    );
  }
}

class AccountFormNotifier extends StateNotifier<AccountFormState> {
  final Ref ref;
  final AccountModel? initialAccount;

  AccountFormNotifier(this.ref, this.initialAccount, AccountType? initialType)
      : super(AccountFormState.initial(initialAccount, initialType));

  void updateName(String value) => state = state.copyWith(name: value);
  void updateInitialBalance(double value) => state = state.copyWith(initialBalance: value);
  void updateInitialBalanceDate(DateTime value) => state = state.copyWith(initialBalanceDate: value);
  void updateType(AccountType value) => state = state.copyWith(type: value);
  void updateColor(String value) => state = state.copyWith(color: value);
  void updateIcon(String value) => state = state.copyWith(icon: value);
  void updateRegistrationMethod(AccountRegistrationMethod value) => state = state.copyWith(registrationMethod: value);
  
  Future<void> updateFile(File? file, String? name) async {
    state = state.copyWith(
      selectedFile: file,
      fileName: name,
      processingStatus: file != null ? AccountProcessingStatus.pending : AccountProcessingStatus.none,
      detectedOrders: [],
      detectedPlannings: [],
    );

    if (file != null && name != null) {
      state = state.copyWith(isLoading: true);
      try {
        final workspaceId = ref.read(onboardingNotifierProvider).createdWorkspaceId;
        final existingCategoryNames = <String>[];
        
        // 1. Upload para o Storage
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final storagePath = workspaceId.isNotEmpty 
            ? 'onboarding_attachments/$workspaceId/${timestamp}_$name'
            : 'onboarding_attachments/temp/${timestamp}_$name';
        
        final storageRef = FirebaseStorage.instance.ref().child(storagePath);
        await storageRef.putFile(file);

        if (workspaceId.isNotEmpty) {
          final categories = await ref.read(categoryRepositoryProvider).getCategories(workspaceId).first;
          existingCategoryNames.addAll(categories.map((c) => c.name));
        }

        // 2. Chamar análise passando o storagePath
        final analysis = await ref.read(onboardingServiceProvider).analyzeDocument(
          storagePath: storagePath,
          fileName: name,
          existingCategories: existingCategoryNames,
        );

        final accountData = analysis.accountData;

        final orders = analysis.orders.map((o) => OrderModel(
          id: const Uuid().v4(),
          description: o['description'] ?? '',
          totalAmount: (o['totalAmount'] as num?)?.toDouble() ?? 0.0,
          type: o['type'] == 'income' ? OrderType.income : OrderType.expense,
          status: OrderStatus.paid,
          category: CategoryModel(
            id: '',
            name: o['categoryName'] ?? 'Uncategorized',
            color: o['categoryColor'] ?? '#4A8C9C',
            icon: o['categoryIcon'] ?? 'category',
            type: o['type'] == 'income' ? CategoryType.income : CategoryType.expense,
          ),
          installmentsCount: 1,
          date: DateTime.tryParse(o['date'] ?? '') ?? DateTime.now(),
        )).toList();

        final plannings = analysis.plannings.map((p) => PlanningModel(
          id: const Uuid().v4(),
          category: CategoryModel(
            id: '',
            name: p['categoryName'] ?? 'Uncategorized',
            color: p['categoryColor'] ?? '#4A8C9C',
            icon: p['categoryIcon'] ?? 'category',
            type: CategoryType.expense, // Default to expense for planning
          ),
          amount: (p['amount'] as num?)?.toDouble() ?? 0.0,
          type: p['type'] == 'recurrent' ? PlanningType.recurrent : PlanningType.unique,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 30)),
          // metadata: {
          //   'accountId': accountData,
          // },
        )).toList();

        state = state.copyWith(
          name: accountData['name'] ?? state.name,
          type: AccountType.values.firstWhere(
            (t) => t.name == accountData['type'] || (accountData['type'] == 'creditCard' && t == AccountType.creditCard),
            orElse: () => state.type,
          ),
          color: accountData['color'] ?? state.color,
          icon: accountData['icon'] ?? state.icon,
          initialBalance: _parseSafeDouble(accountData['initialBalance']),
          metadata: accountData['metadata'] ?? state.metadata,
          detectedOrders: orders,
          detectedPlannings: plannings,
          processingStatus: AccountProcessingStatus.completed,
          isLoading: false,
        );
      } catch (e) {
        state = state.copyWith(
          isLoading: false,
          processingStatus: AccountProcessingStatus.failed,
          errorMessage: e.toString(),
        );
      }
    }
  }

  double _parseSafeDouble(dynamic value) {
    if (value == null) return 0.0;
    final d = (value is num) ? value.toDouble() : 0.0;
    return d.isFinite ? d : 0.0;
  }

  void updateMetadata(String key, dynamic value) {
    final newMetadata = Map<String, dynamic>.from(state.metadata);
    newMetadata[key] = value;
    state = state.copyWith(metadata: newMetadata);
  }

  Future<void> submit({Function(AccountModel, List<OrderModel>, List<PlanningModel>)? onSave}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final workspaceId = ref.read(workspaceNotifierProvider).currentWorkspace?.id;
    if (workspaceId == null && onSave == null) {
      state = state.copyWith(isLoading: false, errorMessage: 'Workspace not found');
      return;
    }

    final accountId = initialAccount?.id ?? const Uuid().v4();
    
    AccountModel account = AccountModel(
      id: accountId,
      name: state.name,
      icon: state.icon,
      color: state.color,
      type: state.type,
      initialBalance: state.initialBalance,
      initialBalanceDate: state.initialBalanceDate,
      metadata: state.metadata,
      fileName: state.fileName,
      processingStatus: state.processingStatus,
    );

    try {
      if (onSave != null) {
        onSave(account, state.detectedOrders, state.detectedPlannings);
      } else {
        // 1. Garantir que as categorias existam
        final categories = await ref.read(categoryRepositoryProvider).getCategories(workspaceId!).first;
        final Map<String, String> categoryMap = {
          for (final c in categories) c.name.toLowerCase(): c.id
        };

        // 2. Processar Orders
        final processedOrders = <OrderModel>[];
        for (final order in state.detectedOrders) {
          final categoryName = order.category.name.toLowerCase();
          String categoryId = categoryMap[categoryName] ?? '';

          if (categoryId.isEmpty) {
            final newCategoryId = const Uuid().v4();
            final newCategory = CategoryModel(
              id: newCategoryId,
              name: order.category.name,
              color: order.category.color,
              icon: order.category.icon,
              type: order.type == OrderType.income ? CategoryType.income : CategoryType.expense,
            );
            await ref.read(categoryRepositoryProvider).createCategory(workspaceId, newCategory);
            categoryMap[categoryName] = newCategoryId;
            categoryId = newCategoryId;
          }

          processedOrders.add(order.copyWith(
            category: order.category.copyWith(id: categoryId),
            metadata: {
              ...(order.metadata ?? {}),
              'accountId': accountId,
            },
          ));
        }

        // 3. Processar Plannings
        final processedPlannings = <PlanningModel>[];
        for (final planning in state.detectedPlannings) {
          final categoryName = planning.category.name.toLowerCase();
          String categoryId = categoryMap[categoryName] ?? '';

          if (categoryId.isEmpty) {
            final newCategoryId = const Uuid().v4();
            final newCategory = CategoryModel(
              id: newCategoryId,
              name: planning.category.name,
              color: planning.category.color,
              icon: planning.category.icon,
              type: CategoryType.expense,
            );
            await ref.read(categoryRepositoryProvider).createCategory(workspaceId, newCategory);
            categoryMap[categoryName] = newCategoryId;
            categoryId = newCategoryId;
          }

          processedPlannings.add(planning.copyWith(
            category: planning.category.copyWith(id: categoryId),
            metadata: {
              ...(planning.metadata ?? {}),
              'accountId': accountId,
            },
          ));
        }

        // 4. Salvar Conta
        if (initialAccount == null) {
          await ref.read(accountNotifierProvider.notifier).createAccount(account);
        } else {
          await ref.read(accountNotifierProvider.notifier).updateAccount(account);
        }

        // 5. Salvar Orders e Plannings
        for (final order in processedOrders) {
          await ref.read(financeRepositoryProvider).addOrder(workspaceId, order);
        }
        for (final planning in processedPlannings) {
          await ref.read(financeRepositoryProvider).addPlanning(workspaceId, planning);
        }
      }
      
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final accountFormProvider = StateNotifierProvider.family<AccountFormNotifier, AccountFormState, AccountFormArgs>((ref, args) {
  return AccountFormNotifier(ref, args.account, args.initialType);
});

class AccountFormArgs {
  final AccountModel? account;
  final AccountType? initialType;

  AccountFormArgs({this.account, this.initialType});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountFormArgs &&
          runtimeType == other.runtimeType &&
          account?.id == other.account?.id &&
          initialType == other.initialType;

  @override
  int get hashCode => (account?.id.hashCode ?? 0) ^ initialType.hashCode;
}
