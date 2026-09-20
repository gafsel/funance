part of 'finance_view_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Modelos de tela do PLANEJAMENTO: a tela simples por categoria e o 50-30-20.
//
// São `part` da mesma biblioteca (`finance_view_models.dart`) de propósito: o
// freezed gera um único `.freezed.dart` por biblioteca, e separar em
// bibliotecas independentes trocaria um arquivo de 522 linhas por três mais um
// gerador rodando três vezes. O que este corte resolve é a LEITURA — quem vem
// mexer no 50-30-20 abria um arquivo que também descrevia o formulário de
// lançamento inteiro.
// ─────────────────────────────────────────────────────────────────────────────

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
