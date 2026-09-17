import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/category_planning_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/models/reconciliation_model.dart';
import 'package:funances/features/goal/domain/models/goal_model.dart';
import 'package:funances/features/onboarding/domain/models/onboarding_models.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/core/money/money.dart';

/// Conversão do que a IA e os documentos devolvem.
///
/// Nenhum texto de usuário nasce aqui. Nome, descrição e categoria ausentes
/// viram string VAZIA, e quem escolhe a palavra ("Sem categoria", "Conta sem
/// nome") é a tela, no idioma de quem está lendo — ver
/// `core/presentation/display_names.dart`. Enquanto o padrão era escrito em
/// português neste arquivo, uma sugestão aceita no onboarding gravava
/// "Nova Conta" no Firestore de qualquer usuário, em qualquer idioma.
class FinanceMapper {
  static CategoryModel toCategory(dynamic json) {
    if (json == null || json is! Map) {
      return const CategoryModel(
        id: '',
        name: '',
        icon: 'category',
        color: '#9E9E9E',
      );
    }

    return CategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'category',
      color: json['color']?.toString() ?? '#9E9E9E',
      type: _toCategoryType(json['type']),
    );
  }

  static CategoryType _toCategoryType(dynamic value) {
    if (value == 'income') return CategoryType.income;
    return CategoryType.expense;
  }

  static AccountModel toAccount(
    dynamic json,
    DateTime initialBalanceDate,
    double deltaAmount,
  ) {
    if (json == null || json is! Map) {
      return AccountModel.checking(
        id: '',
        name: '',
        icon: 'help',
        color: '#9E9E9E',
        initialBalanceDate: DateTime.now(),
      );
    }

    final id = json['id']?.toString() ?? '';
    final name = json['name']?.toString() ?? '';
    final icon = json['icon']?.toString() ?? 'account_balance';
    final color = json['color']?.toString() ?? '#4A8C9C';
    final isDeleted = json['isDeleted'] == true;
    final currentBalance = _toDouble(json['currentBalance']);
    final initialBalance = currentBalance - deltaAmount;
    final runtimeType = json['runtimeType']?.toString() ?? 'checking';

    switch (runtimeType) {
      case 'investment':
        return AccountModel.investment(
          id: id,
          name: name,
          icon: icon,
          color: color,
          isDeleted: isDeleted,
          initialBalance: initialBalance,
          initialBalanceDate: initialBalanceDate,
          interestRate: _toDouble(json['interestRate']),
        );
      case 'creditCard':
        return AccountModel.creditCard(
          id: id,
          name: name,
          icon: icon,
          color: color,
          isDeleted: isDeleted,
          initialBalance: initialBalance,
          initialBalanceDate: initialBalanceDate,
          limit: _toDouble(json['limit']),
          dueDay: _toInt(json['dueDay'], 1),
          closingDay: _toInt(json['closingDay'], 1),
        );
      case 'debt':
        return AccountModel.debt(
          id: id,
          name: name,
          icon: icon,
          color: color,
          isDeleted: isDeleted,
          initialBalance: initialBalance,
          initialBalanceDate: initialBalanceDate,
          interestRate: _toDouble(json['interestRate']),
        );
      case 'checking':
      default:
        return AccountModel.checking(
          id: id,
          name: name,
          icon: icon,
          color: color,
          isDeleted: isDeleted,
          initialBalance: initialBalance,
          initialBalanceDate: initialBalanceDate,
        );
    }
  }

  static OrderModel toOrder(dynamic json) {
    if (json == null || json is! Map) {
      return OrderModel(
        id: '',
        amount: 0.0,
        description: '',
        dueDay: DateTime.now().day,
        startMonth:
            '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}',
        installmentType: InstallmentType.single,
        status: OrderStatus.active,
        type: OrderType.expense,
      );
    }

    final dueDateStr = json['dueDate']?.toString();
    final dueDate = dueDateStr != null
        ? DateTime.tryParse(dueDateStr) ?? DateTime.now()
        : DateTime.now();

    return OrderModel(
      id: json['id']?.toString() ?? '',
      amount: _toDouble(json['amount']),
      description: json['description']?.toString() ?? '',
      dueDay: _toInt(json['dueDay'], dueDate.day),
      startMonth:
          json['startMonth']?.toString() ??
          '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}',
      installmentCount: _toInt(json['installmentCount'], null),
      installmentType: _toInstallmentType(json['installmentType']),
      status: _toOrderStatus(json['status']),
      type: _toOrderType(json['type']),
      category: json['category'] != null ? toCategory(json['category']) : null,
      installmentCreationStatus: InstallmentStatus.settled,
    );
  }

  static AccountDocumentAnalysisResult toAnalysisResult(dynamic json) {
    if (json == null || json is! Map) {
      return AccountDocumentAnalysisResult(
        account: toAccount(null, DateTime.now(), 0),
        orders: [],
      );
    }

    final orders = (json['orders'] as List? ?? [])
        .map((e) => toOrder(e))
        .toList();

    final initialBalanceDate = orders.isEmpty
        ? DateTime.now()
        : orders
              .map((order) => order.firstDueDate)
              .reduce((d1, d2) => d1.isBefore(d2) ? d1 : d2)
              .subtract(Duration(days: 1));
    // O delta vira o `initialBalance` da conta — um número que será GRAVADO.
    // Somado em double, um extrato com dezenas de lançamentos entregava um
    // saldo inicial com resto de ponto flutuante, e a conta nascia com um
    // centavo que não veio de lançamento nenhum.
    final deltaAmount = Money.sumOf(
      orders,
      (order) => order.type == OrderType.expense ? -order.amount : order.amount,
    ).toDouble();

    return AccountDocumentAnalysisResult(
      account: toAccount(json['account'], initialBalanceDate, deltaAmount),
      orders: orders,
    );
  }

  static CategoryPlanningModel toCategoryPlanning(dynamic json) {
    if (json == null || json is! Map) {
      return CategoryPlanningModel(
        id: '',
        category: toCategory(null),
        amount: 0.0,
        startMonth:
            '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}',
        endMonth:
            '${DateTime.now().year + 1}-${DateTime.now().month.toString().padLeft(2, '0')}',
      );
    }

    return CategoryPlanningModel(
      id: json['id']?.toString() ?? '',
      category: toCategory(json['category']),
      amount: _toDouble(json['amount']),
      startMonth:
          json['startMonth']?.toString() ??
          '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}',
      endMonth:
          json['endMonth']?.toString() ??
          '${DateTime.now().year + 1}-${DateTime.now().month.toString().padLeft(2, '0')}',
    );
  }

  static GoalModel toGoal(dynamic json) {
    if (json == null || json is! Map) {
      return GoalModel.saveMoney(
        id: '',
        name: '',
        targetAmount: 0.0,
        currentAmount: 0.0,
        deadline: DateTime.now().add(const Duration(days: 365)),
        startDate: DateTime.now(),
        accountId: "",
      );
    }

    final deadlineMonths = _toInt(json['deadlineMonths'], 12);

    switch (_toGoalType(json['type'])) {
      case GoalType.saveMoney:
        return GoalModel.saveMoney(
          id: json['id']?.toString() ?? '',
          name: json['name']?.toString() ?? '',
          targetAmount: _toDouble(json['targetAmount']),
          currentAmount: _toDouble(json['currentAmount']),
          deadline: json['deadline'] != null
              ? _toDateTime(json['deadline'])
              : DateTime.now().add(Duration(days: deadlineMonths * 30)),
          accountId: json['accountId']?.toString() ?? "",
          startDate: _toDateTime(json['startDate']),
          isDeleted: json['isDeleted'] == true,
        );
      case GoalType.payDebt:
        return GoalModel.payDebt(
          id: json['id']?.toString() ?? '',
          name: json['name']?.toString() ?? '',
          targetAmount: _toDouble(json['targetAmount']),
          currentAmount: _toDouble(json['currentAmount']),
          deadline: json['deadline'] != null
              ? _toDateTime(json['deadline'])
              : DateTime.now().add(Duration(days: deadlineMonths * 30)),
          accountId: json['accountId']?.toString() ?? "",
          startDate: _toDateTime(json['startDate']),
          isDeleted: json['isDeleted'] == true,
        );
      case GoalType.reduceCreditCard:
        return GoalModel.reduceCreditCard(
          id: json['id']?.toString() ?? '',
          name: json['name']?.toString() ?? '',
          targetAmount: _toDouble(json['targetAmount']),
          currentAmount: _toDouble(json['currentAmount']),
          deadline: json['deadline'] != null
              ? _toDateTime(json['deadline'])
              : DateTime.now().add(Duration(days: deadlineMonths * 30)),
          accountId: json['accountId']?.toString() ?? "",
          startDate: _toDateTime(json['startDate']),
          isDeleted: json['isDeleted'] == true,
        );
      case GoalType.reduceExpense:
        return GoalModel.reduceExpense(
          id: json['id']?.toString() ?? '',
          name: json['name']?.toString() ?? '',
          targetAmount: _toDouble(json['targetAmount']),
          currentAmount: _toDouble(json['currentAmount']),
          deadline: json['deadline'] != null
              ? _toDateTime(json['deadline'])
              : DateTime.now().add(Duration(days: deadlineMonths * 30)),
          category: _toCategory(json['category']),
          startDate: _toDateTime(json['startDate']),
          isDeleted: json['isDeleted'] == true,
        );
    }
  }

  /// Categoria de uma META sugerida pela IA. Como o resto do arquivo: sem
  /// nome, devolve vazio — a tela diz "Sem categoria" no idioma de quem lê.
  static CategoryModel _toCategory(dynamic json) {
    if (json == null || json is! Map) {
      return const CategoryModel(
        id: '',
        name: '',
        icon: 'category',
        color: '',
      );
    }

    return CategoryModel(
      id: '',
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String? ?? 'category',
      color: json['color'] as String? ?? '',
      type: _toCategoryType(json['type']),
    );
  }

  static PlanningSuggestions toPlanningSuggestions(dynamic json) {
    if (json == null || json is! Map) {
      return PlanningSuggestions(plannings: [], goals: []);
    }

    return PlanningSuggestions(
      plannings: (json['plannings'] as List? ?? [])
          .map((e) => toCategoryPlanning(e))
          .toList(),
      goals: (json['goals'] as List? ?? []).map((e) => toGoal(e)).toList(),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static int _toInt(dynamic value, int? defaultValue) {
    if (value == null) return defaultValue ?? 0;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? (defaultValue ?? 0);
  }

  static DateTime _toDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static InstallmentType _toInstallmentType(dynamic value) {
    if (value == 'installment') return InstallmentType.installment;
    if (value == 'recurring') return InstallmentType.recurring;
    return InstallmentType.single;
  }

  static OrderStatus _toOrderStatus(dynamic value) {
    if (value == 'cancelled') return OrderStatus.cancelled;
    if (value == 'settled') return OrderStatus.settled;
    return OrderStatus.active;
  }

  static OrderType _toOrderType(dynamic value) {
    if (value == 'income') return OrderType.income;
    if (value == 'transfer') return OrderType.transfer;
    return OrderType.expense;
  }

  static GoalType _toGoalType(dynamic value) {
    if (value == 'reduce_expense') return GoalType.reduceExpense;
    if (value == 'reduce_credit_card') return GoalType.reduceCreditCard;
    if (value == 'pay_debt') return GoalType.payDebt;
    return GoalType.saveMoney;
  }
  static ReconciliationTransaction toReconciliationTransaction(dynamic json) {
    if (json == null || json is! Map) {
      return ReconciliationTransaction(
        description: '',
        amount: 0.0,
        date: DateTime.now(),
        type: OrderType.expense,
      );
    }

    return ReconciliationTransaction(
      description: json['description']?.toString() ?? '',
      amount: _toDouble(json['amount']),
      date: _toDateTime(json['date']),
      type: _toOrderType(json['type']),
      category: json['category'] != null ? toCategory(json['category']) : null,
    );
  }
}
