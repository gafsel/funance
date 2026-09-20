import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/services/category_planning_service.dart';
import 'package:funances/features/finance/domain/services/period_summary_service.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/core/money/money.dart';

/// O convite que aparece depois de um gasto fora do plano.
class UnplannedNudge {
  const UnplannedNudge({
    required this.category,
    required this.amount,
    required this.dueDate,
    this.accountId,
    this.suggestedLimit,
  });

  final CategoryModel category;

  /// Valor do gasto que disparou o convite — pré-preenche a recorrência.
  final double amount;

  /// Vencimento do gasto: é dele que sai o dia da recorrência.
  final DateTime dueDate;

  final String? accountId;

  /// Média dos últimos três meses da categoria, arredondada para cima em
  /// R$ 10. `null` quando não há histórico — aí a tela de limite abre sem
  /// sugestão, em vez de sugerir um número inventado.
  final double? suggestedLimit;
}

/// Guarda quais categorias já receberam o convite hoje.
///
/// Um convite por categoria por dia: quem registra três idas ao mercado numa
/// tarde não pode ser perguntado três vezes sobre a mesma categoria.
abstract class IUnplannedNudgeStore {
  Future<bool> wasShownToday(
    String workspaceId,
    String categoryId,
    DateTime today,
  );

  Future<void> markShown(String workspaceId, String categoryId, DateTime today);
}

/// Decide se o nudge de gasto não planejado deve aparecer.
///
/// F3.2: gastar fora do plano é o momento em que o planejamento faz mais
/// sentido e é justamente quando o app não dizia nada. O convite só aparece
/// quando ele tem o que oferecer: gasto novo, já realizado, que não estava
/// agendado e numa categoria sem limite no mês. Fora disso, silêncio — um
/// convite repetido vira ruído e ensina o usuário a fechar sem ler.
class UnplannedNudgeService {
  UnplannedNudgeService({
    required this.workspaceId,
    required this.planningService,
    required this.summaryService,
    required this.store,
  });

  final String workspaceId;
  final CategoryPlanningService planningService;
  final PeriodSummaryService summaryService;
  final IUnplannedNudgeStore store;

  /// Quantos meses anteriores entram na média da sugestão.
  static const int suggestionMonths = 3;

  /// `null` quando não há convite a fazer.
  Future<UnplannedNudge?> evaluate({
    required CategoryModel? category,
    required OrderType type,
    required InstallmentStatus status,
    required bool isNewOrder,
    required bool matchedPending,
    required double amount,
    required DateTime dueDate,
    required DateTime today,
    String? accountId,
  }) async {
    if (workspaceId.isEmpty) return null;
    if (!isNewOrder) return null;
    if (type != OrderType.expense) return null;

    // "Realizada": agendar um gasto JÁ é planejar, e perguntar sobre limite
    // nesse momento seria corrigir quem acabou de acertar.
    final isRealized =
        status == InstallmentStatus.paid || status == InstallmentStatus.settled;
    if (!isRealized) return null;

    // Casou com um agendamento: o gasto estava previsto, ainda que sem
    // limite de categoria. Não há nada de "não planejado" nele.
    if (matchedPending) return null;

    if (category == null || !category.isSelectable) return null;
    if (amount <= 0) return null;

    if (await _hasLimit(category.id, dueDate)) return null;

    if (await store.wasShownToday(workspaceId, category.id, today)) {
      return null;
    }

    return UnplannedNudge(
      category: category,
      amount: amount,
      dueDate: dueDate,
      accountId: accountId,
      suggestedLimit: await suggestedLimit(category.id, today),
    );
  }

  /// Marca que o convite desta categoria já foi feito hoje.
  Future<void> markShown(String categoryId, DateTime today) {
    return store.markShown(workspaceId, categoryId, today);
  }

  /// Limite vigente da categoria no mês do vencimento.
  ///
  /// Uma falha de leitura devolve "tem limite": na dúvida o app fica calado,
  /// porque um convite indevido é pior que um convite que não veio.
  Future<bool> _hasLimit(String categoryId, DateTime dueDate) async {
    try {
      final plannings = await planningService.plannings(
        month: dueDate.monthKey,
      );

      return plannings.any((planning) => planning.category.id == categoryId);
    } catch (_) {
      return true;
    }
  }

  /// Média dos últimos [suggestionMonths] meses de `actualAmount` da
  /// categoria, arredondada para cima em R$ 10.
  ///
  /// A média é sobre os meses que EXISTEM no `period_summaries`, não sobre
  /// três fixos: quem usa o app há um mês teria a sugestão dividida por três e
  /// receberia um limite que já nasce estourado.
  Future<double?> suggestedLimit(String categoryId, DateTime today) async {
    var total = Money.zero;
    var months = 0;

    for (var back = 1; back <= suggestionMonths; back++) {
      final reference = DateTime(today.year, today.month - back, 1);

      try {
        final summary = await summaryService
            .watchMonth(reference.year, reference.month)
            .first;

        final entry = summary?.categories[categoryId];
        if (entry == null) continue;

        total += entry.actualAmount.asMoney;
        months++;
      } catch (_) {
        // Um mês ilegível não invalida os outros.
        continue;
      }
    }

    if (months == 0) return null;

    final average = (total * (1 / months)).toDouble();
    if (average <= 0) return null;

    return roundUpToTen(average);
  }

  /// Arredonda para cima no múltiplo de 10 mais próximo. Um limite de
  /// R$ 487,31 não é uma decisão que alguém toma; R$ 490 é.
  static double roundUpToTen(double value) => (value / 10).ceil() * 10.0;
}
