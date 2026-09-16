import 'package:funances/features/finance/domain/models/category_planning_model.dart';
import 'package:funances/features/finance/domain/repositories/finance_repository.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:uuid/uuid.dart';

/// O único jeito de definir o limite (ou a expectativa) de uma categoria.
///
/// Antes havia três caminhos gravando na mesma coleção `category_planning`
/// com regras diferentes: a tela simples `/planning`, que só sabia trabalhar
/// no mês corrente e sobrescrevia o valor no lugar; a 50-30-20, que versionava
/// por mês; e o onboarding, que gravava direto pelo repositório. Mudar o mesmo
/// limite em telas diferentes produzia documentos diferentes.
///
/// A regra é a da 50-30-20: definir um limite a partir de um mês encerra o
/// planejamento vigente (`endMonth` = mês anterior) e cria um novo
/// (`startMonth` = mês escolhido, `endMonth` aberto). O histórico dos meses
/// já fechados não muda de valor retroativamente.
///
/// Contrato do documento: `category`, `amount`, `startMonth` e `endMonth`.
/// `summarizedUntil`, `appliedAmount`, `appliedFrom` e `appliedUntil` são do
/// servidor — o cliente não grava nenhum deles.
class CategoryPlanningService {
  final String workspaceId;
  final IFinanceRepository repository;

  CategoryPlanningService({
    required this.workspaceId,
    required this.repository,
  });

  /// `endMonth` de um planejamento sem prazo.
  ///
  /// O servidor compara `startMonth <= mês <= endMonth` lexicograficamente e
  /// como número (`ano * 12 + mês`), então a sentinela precisa ser uma chave
  /// `YYYY-MM` válida e maior que qualquer mês real. É a mesma usada por
  /// `gamification.service.ts`.
  static const String openEndMonth = '9999-12';

  /// Chave `YYYY-MM` do mês anterior a [month].
  static String previousMonth(String month) {
    final parts = month.split('-');
    final year = int.parse(parts[0]);
    final index = int.parse(parts[1]);

    final previous = DateTime(year, index - 1);

    return '${previous.year}-${previous.month.toString().padLeft(2, '0')}';
  }

  /// Planejamentos vigentes no mês [month].
  Future<List<CategoryPlanningModel>> plannings({required String month}) {
    return repository.getCategoryPlannings(workspaceId, startMonth: month);
  }

  /// Define o limite (despesa) ou a expectativa (receita) de [category] a
  /// partir de [month].
  ///
  /// [amount] menor ou igual a zero apaga o limite: o vigente é encerrado e
  /// nenhum novo entra no lugar.
  ///
  /// Devolve `true` quando algo foi de fato gravado — a tela usa isso para não
  /// emitir evento de analytics num salvar que não mudou nada.
  Future<bool> setLimit({
    required CategoryModel category,
    required double amount,
    required String month,
    List<CategoryPlanningModel>? currentPlannings,
  }) async {
    final plannings = currentPlannings ?? await this.plannings(month: month);
    final current = plannings
        .where((planning) => planning.category.id == category.id)
        .firstOrNull;

    if (amount <= 0) {
      if (current == null) return false;

      await _close(current, month);
      return true;
    }

    if (current == null) {
      await _create(category: category, amount: amount, month: month);
      return true;
    }

    if (current.amount == amount && current.category.id == category.id) {
      return false;
    }

    // Já começa no mês editado: é o documento deste mês, não um vigente de um
    // mês anterior. Encerrá-lo criaria uma janela vazia e um documento órfão.
    if (current.startMonth == month) {
      await repository.updateCategoryPlanning(
        workspaceId,
        current.copyWith(
          amount: amount,
          category: category,
          endMonth: CategoryPlanningService.openEndMonth,
        ),
      );
      return true;
    }

    await _close(current, month);
    await _create(category: category, amount: amount, month: month);

    return true;
  }

  /// Aplica vários limites de uma vez, lendo os vigentes uma única vez.
  ///
  /// Devolve `true` se qualquer um deles mudou.
  Future<bool> setLimits({
    required List<({CategoryModel category, double amount})> limits,
    required String month,
  }) async {
    if (limits.isEmpty) return false;

    final plannings = await this.plannings(month: month);

    var changed = false;
    for (final limit in limits) {
      final wrote = await setLimit(
        category: limit.category,
        amount: limit.amount,
        month: month,
        currentPlannings: plannings,
      );
      changed = changed || wrote;
    }

    return changed;
  }

  /// Encerra o planejamento vigente no mês anterior a [month].
  ///
  /// Quando ele já começava em [month] a janela fica vazia de propósito
  /// (`endMonth` < `startMonth`): nenhuma consulta o encontra e o servidor
  /// para de projetá-lo, que é o efeito de "apagar" sem apagar o histórico.
  Future<void> _close(CategoryPlanningModel planning, String month) {
    return repository.updateCategoryPlanning(
      workspaceId,
      planning.copyWith(endMonth: previousMonth(month)),
    );
  }

  Future<void> _create({
    required CategoryModel category,
    required double amount,
    required String month,
  }) {
    return repository.addCategoryPlanning(
      workspaceId,
      CategoryPlanningModel(
        // O repositório grava com id automático do Firestore e descarta este;
        // ele existe só para o modelo ser válido em memória.
        id: const Uuid().v4(),
        category: category,
        amount: amount,
        startMonth: month,
        endMonth: openEndMonth,
      ),
    );
  }
}
