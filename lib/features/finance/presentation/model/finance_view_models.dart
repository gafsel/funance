import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:uuid/uuid.dart';

part 'finance_view_models.freezed.dart';

@freezed
sealed class CategoryPlanningArgs with _$CategoryPlanningArgs {
  factory CategoryPlanningArgs({
    required CategoryType type,

    /// Categoria que o usuário veio definir (F3.2: o nudge manda para cá
    /// com a categoria do gasto que acabou de sair do plano). Ela sobe para
    /// o topo da lista e nasce destacada — chegar numa lista de trinta
    /// categorias e ter que procurar a sua seria desfazer o convite.
    String? highlightCategoryId,

    /// Valor sugerido para [highlightCategoryId], já preenchido. `null`
    /// quando não há histórico para sugerir.
    double? suggestedAmount,
  }) = _CategoryPlanningArgs;
}

@freezed
sealed class CategoryPlanningFormItem with _$CategoryPlanningFormItem {
  factory CategoryPlanningFormItem({
    required CategoryModel category,
    @Default(0.0) double amount,
    String? planningId,
    @Default(false) bool isDirty,
  }) = _CategoryPlanningFormItem;
}

@freezed
sealed class CategoryPlanningState with _$CategoryPlanningState {
  factory CategoryPlanningState({
    @Default([]) List<CategoryPlanningFormItem> items,
    @Default(true) bool isLoading,
    String? highlightCategoryId,
  }) = _CategoryPlanningState;
}

@freezed
sealed class CategoryPlanning503020Item with _$CategoryPlanning503020Item {
  const CategoryPlanning503020Item._();

  factory CategoryPlanning503020Item({
    required CategoryModel category,
    @Default(0.0) double generalAmount,
    @Default(0.0) double specificAmount,
    @Default(0.0) double actualAmount,
    String? planningId,
    @Default(false) bool isDirty,
  }) = _CategoryPlanning503020Item;

  double get effectiveAmount =>
      generalAmount > 0 ? generalAmount : specificAmount;
}

@freezed
sealed class CategoryPlanning503020State with _$CategoryPlanning503020State {
  factory CategoryPlanning503020State({
    required DateTime date,
    @Default([]) List<CategoryPlanning503020Item> items,
    @Default(0.0) double totalIncomes,
    @Default(0.0) double totalActualIncomes,
    @Default(true) bool isLoading,
    @Default(false) bool isSubmitting,

    /// Falha da leitura do mês. O `listen` do notifier não tinha `onError`: a
    /// exceção do stream sumia e a tela ficava com as pools vazias, dizendo
    /// que não havia categoria em nenhuma delas.
    Object? error,
  }) = _CategoryPlanning503020State;
}

@freezed
sealed class Planning503020DistributionGroup
    with _$Planning503020DistributionGroup {
  const factory Planning503020DistributionGroup({
    @Default(0.0) double plannedAmount,
    @Default(0.0) double actualAmount,
    @Default(0.0) double idealPercentage,
  }) = _Planning503020DistributionGroup;
}

@freezed
sealed class Planning503020Distribution with _$Planning503020Distribution {
  const factory Planning503020Distribution({
    required Planning503020DistributionGroup essential,
    required Planning503020DistributionGroup comfort,
    required Planning503020DistributionGroup investment,
    @Default(0.0) double totalIncome,
    @Default(0.0) double totalActualIncome,
  }) = _Planning503020Distribution;
}

/// O lançamento tem duas telas antes de salvar: escolher a categoria e
/// preencher o formulário. Transferências não têm categoria escolhível (o
/// servidor deriva a categoria virtual das contas), então começam no
/// formulário.
enum TransactionWizardStep { category, form }

@freezed
sealed class TransactionWizardArgs with _$TransactionWizardArgs {
  factory TransactionWizardArgs({
    required OrderType type,
    String? accountIdSource,
  }) = _TransactionWizardArgs;
}

@freezed
sealed class TransactionWizardState with _$TransactionWizardState {
  const factory TransactionWizardState({
    required OrderType type,
    CategoryModel? selectedCategory,
    @Default(TransactionWizardStep.category) TransactionWizardStep step,
    String? accountIdSource,
  }) = _TransactionWizardState;
}

/// Chave do formulário de pagamento de uma parcela.
///
/// [paidOn] entra na chave porque é ele que distingue "quitar esta parcela"
/// (data do vencimento) de "registrei hoje e isto era o agendamento" (hoje).
@freezed
sealed class TransactionPaymentArgs with _$TransactionPaymentArgs {
  const factory TransactionPaymentArgs({
    required InstallmentModel installment,
    DateTime? paidOn,
  }) = _TransactionPaymentArgs;
}

@freezed
sealed class TransactionCreationArgs with _$TransactionCreationArgs {
  factory TransactionCreationArgs({
    required OrderType type,
    InstallmentStatus? status,
    InstallmentType? installmentType,
    CategoryModel? category,
    String? accountIdSource,
    String? accountIdTarget,
    String? description,
    DateTime? date,
    double? amount,
  }) = _TransactionCreationArgs;
}

enum TransactionFormType { order, installment }

enum TransactionAmountType { total, installment }

/// Como uma transferência vai aparecer nos relatórios.
///
/// `FinanceService._processVirtualCategory` (e o `SummaryService` no
/// servidor) derivam a categoria virtual dos tipos das contas envolvidas. O
/// formulário não troca a categoria escondido: só avisa o usuário em qual
/// pool a transferência vai cair.
enum TransferAccounting { investment, debt }

@freezed
sealed class TransactionFormState with _$TransactionFormState {
  const TransactionFormState._();

  const factory TransactionFormState({
    String? installmentId,
    String? orderId,
    required TransactionFormType formType,
    required OrderType type,
    required InstallmentType installmentType,
    @Default(TransactionAmountType.total) TransactionAmountType amountType,
    @Default("") String description,
    @Default(0.0) double amount,
    int? intallmentNumber,
    int? installmentCount,
    required DateTime dueDate,
    @Default(InstallmentStatus.pending) InstallmentStatus status,
    DateTime? paidDate,
    double? paidAmount,
    CategoryModel? category,
    String? accountIdSource,
    String? accountIdTarget,
    ReplicationCascade? replicateCascade,
    @Default(false) bool isInvoice,
    // Status da parcela como está persistida, capturado ao abrir o formulário.
    // `status` acompanha a edição do usuário, então só este campo responde
    // "como estava antes deste save". Nulo quando não há parcela persistida.
    InstallmentStatus? originalStatus,
    // A parcela como está persistida. É ela que responde "o que mudou neste
    // save" — `status`/`amount`/`dueDate` do estado já são os valores novos.
    InstallmentModel? original,
    // Pool em que a transferência vai cair, para o aviso no formulário.
    TransferAccounting? transferAccounting,
    // Verdadeiro enquanto o formulário procura a conta padrão da categoria.
    // Enquanto isso o campo de conta não abre sozinho: abrir o seletor e
    // depois preencher o default por baixo seria pior que esperar.
    @Default(false) bool resolvingAccount,
    // Agendamentos pendentes da categoria que este lançamento pode estar
    // quitando. Sem esta busca, registrar um gasto que já estava agendado
    // cria uma order nova e deixa a parcela pendente para trás: o planejado
    // conta duas vezes no 50-30-20 e a parcela vira uma missão atrasada que
    // nunca fecha.
    @Default([]) List<InstallmentModel> pendingMatches,
    // Verdadeiro enquanto a busca corre. O formulário reserva o espaço do
    // banner enquanto isso: deixar a oferta aparecer depois empurraria os
    // campos para baixo bem quando o usuário já está tocando no valor.
    @Default(false) bool loadingMatches,
    // O usuário disse que é lançamento novo. A marca fica no estado para o
    // nudge de F3.2 saber que a pergunta já foi feita e recusada.
    @Default(false) bool dismissedMatch,
    // Agendamento escolhido: a tela passa a editar esta parcela em vez de
    // criar uma order.
    InstallmentModel? matchedInstallment,
  }) = _TransactionFormState;

  bool get creation => formType == TransactionFormType.order && orderId == null;

  /// Id do agendamento que este lançamento está quitando, quando há um.
  String? get matchedInstallmentId => matchedInstallment?.id;

  /// Há agendamento para oferecer e o usuário ainda não recusou a oferta.
  bool get hasPendingMatches => !dismissedMatch && pendingMatches.isNotEmpty;

  /// A busca por agendamentos está correndo e ainda pode virar oferta.
  ///
  /// Depois de recusada, a oferta não volta nesta categoria: uma resposta
  /// atrasada não pode reabrir o espaço que o usuário acabou de fechar.
  bool get searchingMatches => !dismissedMatch && loadingMatches;

  /// Agendamento cujo valor bate com o que o usuário já digitou, quando há
  /// um só candidato.
  ///
  /// Quem paga a conta de luz de R$ 187,40 digita o valor antes de olhar a
  /// oferta: entre três pendentes da categoria, o de mesmo valor é quase
  /// certamente o que ele está quitando. A tolerância de 1% do valor
  /// pendente (com piso de um centavo) absorve juros e arredondamento.
  ///
  /// Empate não destaca ninguém: duas parcelas de R$ 100 na mesma categoria
  /// não dizem qual das duas é esta, e apontar uma seria um chute com cara
  /// de resposta.
  String? get likelyMatchId {
    if (amount <= 0 || pendingMatches.isEmpty) return null;

    double? closest;
    String? closestId;
    var tied = false;

    for (final match in pendingMatches) {
      final tolerance = match.amount * 0.01;
      final distance = (match.amount - amount).abs();

      if (distance > (tolerance < 0.01 ? 0.01 : tolerance)) continue;

      if (closest == null || distance < closest) {
        closest = distance;
        closestId = match.id;
        tied = false;
      } else if (distance == closest) {
        tied = true;
      }
    }

    return tied ? null : closestId;
  }

  /// Há um valor preenchido. Não tem relação com planejamento: distingue o
  /// lançamento com valor (campos de pagamento fazem sentido) do que ainda
  /// está zerado.
  bool get hasAmount => amount > 0.0;

  /// A parcela tem irmãs — só então faz sentido perguntar sobre replicação.
  bool get hasSiblings => switch (installmentType) {
    InstallmentType.single => false,
    InstallmentType.recurring => true,
    InstallmentType.installment => (installmentCount ?? 1) > 1,
  };

  /// Algum campo replicável mudou em relação à parcela persistida.
  ///
  /// Status, data e valor de pagamento ficam de fora de propósito: quitar uma
  /// parcela é um evento dela, não da série.
  bool get replicableFieldsChanged {
    final persisted = original;
    if (persisted == null) {
      return false;
    }

    return amount != persisted.amount ||
        dueDate != persisted.dueDate ||
        description != persisted.description ||
        category?.id != persisted.category?.id ||
        accountIdSource != persisted.accountIdSource ||
        accountIdTarget != persisted.accountIdTarget;
  }

  /// Formulário de um lançamento novo.
  ///
  /// Sem status explícito vale `paid`: quem abre o formulário sem dizer nada
  /// está registrando algo que já aconteceu ("acabei de gastar"). Agendar é a
  /// escolha consciente, feita no ponto de entrada. O default anterior era
  /// `pending`, e a consolidação de uma transação bancária — que por
  /// definição já aconteceu — nascia como agendamento.
  factory TransactionFormState.creation({
    required OrderType type,
    InstallmentStatus? status,

    /// Avulso, parcelado ou recorrente. Vem de fora só quando o ponto de
    /// entrada já sabe a resposta — hoje, o nudge de gasto não planejado,
    /// que abre o formulário em "toda vez" porque foi isso que o usuário
    /// acabou de escolher.
    InstallmentType? installmentType,
    CategoryModel? category,
    String? accountIdSource,
    String? accountIdTarget,
    String? description,
    DateTime? date,
    double? amount,
  }) {
    final effectiveStatus = status ?? InstallmentStatus.paid;
    final isPaid =
        effectiveStatus == InstallmentStatus.paid ||
        effectiveStatus == InstallmentStatus.settled;

    return TransactionFormState(
      formType: TransactionFormType.order,
      type: type,
      category: category,
      dueDate: date ?? DateTime.now(),
      paidDate: isPaid ? date ?? DateTime.now() : null,
      status: effectiveStatus,
      installmentType: installmentType ?? InstallmentType.single,
      accountIdSource: accountIdSource,
      accountIdTarget: accountIdTarget,
      description: description ?? "",
      amount: amount ?? 0.0,
      paidAmount: isPaid ? amount ?? 0.0 : null,
    );
  }

  factory TransactionFormState.updateOrder(OrderModel order) {
    return TransactionFormState(
      formType: TransactionFormType.order,
      orderId: order.id,
      type: order.type,
      category: order.category,
      dueDate: order.firstDueDate,
      installmentType: order.installmentType,
      installmentCount: order.installmentCount,
      accountIdTarget: order.accountIdTarget,
      accountIdSource: order.accountIdSource,
      amount: order.amount,
      description: order.description,
      isInvoice: order.isInvoice,
    );
  }

  /// Formulário de uma parcela existente.
  ///
  /// [paidOn] força a data de pagamento. Serve ao casamento com agendamento:
  /// o usuário está registrando o que gastou HOJE, então a parcela vencida no
  /// mês passado é quitada com a data de hoje, não com o vencimento dela.
  /// Sem [paidOn] vale a regra do fluxo de pagamento comum — quitar uma
  /// parcela vencida assume a data do vencimento.
  factory TransactionFormState.updateInstallment(
    InstallmentModel installment, {
    InstallmentStatus? status,
    DateTime? paidOn,
  }) {
    final effectiveStatus = status ?? installment.status;

    DateTime? paidDate = installment.paidDate;
    double? paidAmount = installment.paidAmount;

    if (status == InstallmentStatus.paid ||
        status == InstallmentStatus.settled) {
      paidAmount = installment.amount;
      paidDate =
          paidOn ??
          (installment.dueDate.isAfter(DateTime.now())
              ? DateTime.now()
              : installment.dueDate);
    } else if (status == InstallmentStatus.pending) {
      paidAmount = null;
      paidDate = null;
    }

    return TransactionFormState(
      formType: TransactionFormType.installment,
      originalStatus: installment.status,
      original: installment,
      installmentId: installment.id,
      orderId: installment.orderId,
      type: installment.type,
      category: installment.category,
      dueDate: installment.dueDate,
      installmentType: installment.installmentType,
      installmentCount: installment.installmentCount,
      intallmentNumber: installment.installmentNumber,
      accountIdTarget: installment.accountIdTarget,
      accountIdSource: installment.accountIdSource,
      amount: installment.amount,
      status: effectiveStatus,
      description: installment.description,
      paidAmount: paidAmount,
      paidDate: paidDate,
      replicateCascade: ReplicationCascade.none,
      isInvoice: installment.isInvoice,
    );
  }

  OrderModel asOrderModel() {
    double finalAmount = amount;
    if (installmentType == InstallmentType.installment &&
        amountType == TransactionAmountType.installment &&
        installmentCount != null) {
      finalAmount = amount * installmentCount!;
    }

    return OrderModel(
      id: orderId ?? Uuid().v4(),
      amount: finalAmount,
      description: description,
      dueDay: dueDate.day,
      startMonth: dueDate.formated("yyyy-MM"),
      installmentType: installmentType,
      installmentCount: installmentCount,
      status: OrderStatus.active,
      installmentCreationStatus: status,
      type: type,
      accounts: {
        if (accountIdSource != null &&
            (type == OrderType.expense || type == OrderType.transfer))
          accountIdSource!: AccountImpact.debt,
        if (accountIdSource != null && type == OrderType.income)
          accountIdSource!: AccountImpact.credit,
        if (accountIdTarget != null && type == OrderType.transfer)
          accountIdTarget!: AccountImpact.credit,
      },
      category: category,
      isInvoice: isInvoice,
    );
  }

  InstallmentModel asInstallmentModel() {
    return InstallmentModel(
      id: installmentId!,
      orderId: orderId!,
      amount: amount,
      description: description,
      dueDate: dueDate,
      status: status,
      type: type,
      installmentType: installmentType,
      category: category,
      accounts: {
        if ((type == OrderType.expense || type == OrderType.transfer))
          accountIdSource!: AccountImpact.debt,
        if (type == OrderType.income) accountIdSource!: AccountImpact.credit,
        if (type == OrderType.transfer) accountIdTarget!: AccountImpact.credit,
      },
      paidDate: paidDate,
      paidAmount: paidAmount,
      installmentCount: installmentCount,
      installmentNumber: intallmentNumber,
      replicationCascade: replicateCascade,
      isInvoice: isInvoice,
    );
  }
}

@freezed
sealed class TransactionTotals with _$TransactionTotals {
  const factory TransactionTotals({
    @Default(0.0) double plannedIncomes,
    @Default(0.0) double realizedIncomes,
    @Default(0.0) double plannedExpenses,
    @Default(0.0) double realizedExpenses,
    @Default(0.0) double plannedTransfers,
    @Default(0.0) double realizedTransfers,
    @Default(0.0) double plannedInvoices,
    @Default(0.0) double realizedInvoices,
    @Default(0.0) double plannedVirtualDebtExpense,
    @Default(0.0) double realizedVirtualDebtExpense,
    @Default(0.0) double plannedVirtualDebtIncome,
    @Default(0.0) double realizedVirtualDebtIncome,
    @Default(0.0) double plannedVirtualInvestmentExpense,
    @Default(0.0) double realizedVirtualInvestmentExpense,
    @Default(0.0) double plannedVirtualInvestmentIncome,
    @Default(0.0) double realizedVirtualInvestmentIncome,
  }) = _TransactionTotals;

  const TransactionTotals._();

  double get plannedBalance => plannedIncomes - plannedExpenses;

  double get realizedBalance => realizedIncomes - realizedExpenses;
}

@freezed
sealed class TransactionQuery with _$TransactionQuery {
  factory TransactionQuery({
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    OrderType? type,
    String? description,
    double? minAmount,
    double? maxAmount,
    InstallmentStatus? status,
    @Default(true) bool descending,
  }) = _TransactionQuery;
}
