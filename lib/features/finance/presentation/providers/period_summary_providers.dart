// ─────────────────────────────────────────────────────────────────────────────
// Providers do RESUMO DE PERÍODO (`period_summaries`), que é o que o servidor
// agrega e o app só lê.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/features/finance/data/repositories/period_summary_repository_impl.dart';
import 'package:funances/features/finance/domain/models/period_summary_model.dart';
import 'package:funances/features/finance/domain/repositories/period_summary_repository.dart';
import 'package:funances/features/finance/domain/services/period_summary_service.dart';
import 'package:funances/features/home/presentation/model/overview_view_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/presentation/providers.dart';

class PeriodSummaryDomainProviders {
  static final repository = Provider<IPeriodSummaryRepository>(
    (ref) => PeriodSummaryRepositoryImpl(),
  );

  static final service = Provider(
    (ref) => PeriodSummaryService(
      workspaceId: ref.watch(WorkspaceViewProviders.currentWorkspaceId) ?? "",
      repository: ref.read(repository),
    ),
  );
}

List<OverviewCategorySummary> _mapToOverview(
  PeriodSummaryModel? summary,
  List<CategoryModel> categories,
) {
  final List<OverviewCategorySummary> result = [];
  if (summary == null) return result;

  summary.categories.forEach((categoryId, data) {
    final category = categories.where((c) => c.id == categoryId).firstOrNull;

    if (category != null) {
      result.add(
        OverviewCategorySummary(
          category: category,
          generalPlannedAmount: data.generalPlannedAmount,
          specificPlannedAmount: data.specificPlannedAmount,
          actualAmount: data.actualAmount,
        ),
      );
    }
  });
  return result;
}

class PeriodSummaryViewProviders {
  /// Chaveado por `YYYY-MM` (veja `DateTimeExtension.monthKey`): um
  /// `DateTime` como chave criaria uma família por instante distinto, já que
  /// o período nasce do relógio.
  static final monthSummary = StreamProvider.autoDispose
      .family<List<OverviewCategorySummary>, String>((ref, monthKey) {
        final service = ref.watch(PeriodSummaryDomainProviders.service);
        final categoriesAsync = ref.watch(CategoryViewProviders.allStream);

        // Falha ao ler categorias PROPAGA. Virar lista vazia fazia o resumo do
        // mês dizer "nenhuma categoria" — uma afirmação, e errada — em vez de
        // deixar a tela mostrar o erro e oferecer tentar de novo.
        if (categoriesAsync.hasError) {
          return Stream<List<OverviewCategorySummary>>.error(
            categoriesAsync.error!,
            categoriesAsync.stackTrace ?? StackTrace.current,
          );
        }

        final List<CategoryModel> categories = categoriesAsync.valueOrNull ?? [];

        final (year, month) = DateTimeExtension.parseMonthKey(monthKey);

        return service
            .watchMonth(year, month)
            .map((summary) => _mapToOverview(summary, categories));
      });
}
