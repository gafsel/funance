import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/coaching/presentation/providers.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/goal/presentation/provider.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:funances/features/workspace/presentation/providers.dart';

/// "Tentar de novo" precisa invalidar a FONTE, não o último provider da fila.
///
/// Foi assim que o botão nasceu errado: a Visão Geral invalidava
/// `monthSummary`, mas o erro vinha de `CategoryViewProviders.allStream` — um
/// `StreamProvider` SEM `autoDispose`, que guarda o `AsyncError` até alguém o
/// invalidar. O `monthSummary` era recriado, lia o erro cacheado do pai e
/// reemitia o mesmo erro: o botão existia, girava e não fazia nada.
///
/// Cada função abaixo percorre a cadeia até quem fala com o Firestore. Quando
/// uma tela ganhar um provider derivado novo, o lugar de ensinar a cadeia é
/// aqui — não no `onRetry` de cada widget.
class Retry {
  const Retry._();

  /// Categorias: `allStream` é a fonte (serviço → Firestore) e alimenta
  /// `byId`, o seletor, o resumo do mês e o 50-30-20.
  static void categories(WidgetRef ref) {
    ref.invalidate(CategoryViewProviders.allStream);
  }

  /// Contas: `all` e `byTypeMap` são duas leituras irmãs do mesmo serviço, e
  /// `byId`/`latestBalanceByType` derivam de `all`. Uma tela pode estar
  /// olhando qualquer uma das duas, então as duas voltam.
  static void accounts(WidgetRef ref) {
    ref.invalidate(AccountViewProviders.all);
    ref.invalidate(AccountViewProviders.byTypeMap);
  }

  static void goals(WidgetRef ref) {
    ref.invalidate(GoalViewProvider.goalsStream);
  }

  /// O checklist e a party da semana (`MissionViewProviders.mission`) leem
  /// direto do serviço: a fonte é o próprio provider.
  static void missions(WidgetRef ref) {
    ref.invalidate(MissionViewProviders.mission);
  }

  /// Histórico da Bússola: o stream é a fonte.
  static void healthHistory(WidgetRef ref) {
    ref.invalidate(JourneyViewProviders.healthHistory);
  }

  static void members(WidgetRef ref) {
    ref.invalidate(WorkspaceViewProviders.members);
  }

  static void coaching(WidgetRef ref) {
    ref.invalidate(CoachingViewProviders.insightsHistory);
  }

  /// O último insight, que é o que a Home mostra. Fonte: o serviço.
  static void lastInsight(WidgetRef ref) {
    ref.invalidate(CoachingViewProviders.lastInsight);
  }

  static void coachingInsight(WidgetRef ref, String id) {
    ref.invalidate(CoachingViewProviders.insightById(id));
  }

  static void installment(WidgetRef ref, String id) {
    ref.invalidate(FinanceViewProviders.installmentById(id));
  }

  /// Resumo do mês: o erro pode ser das CATEGORIAS ou da leitura do mês.
  /// Invalidar só o resumo deixava o erro do pai intacto.
  static void monthSummary(WidgetRef ref, String monthKey) {
    categories(ref);
    ref.invalidate(PeriodSummaryViewProviders.monthSummary(monthKey));
  }

  /// Gráfico da fatura: as parcelas do ciclo são a fonte.
  static void invoiceChart(WidgetRef ref, InvoiceKey invoice) {
    ref.invalidate(FinanceViewProviders.invoiceInstallments(invoice));
    ref.invalidate(FinanceViewProviders.invoicePieChart(invoice));
  }

  /// 50-30-20: a distribuição lê categorias, planejamentos e o resumo do mês.
  static void planning503020(WidgetRef ref, DateTime date, String monthKey) {
    monthSummary(ref, monthKey);
    ref.invalidate(FinanceViewProviders.planning503020Distribution(date));
  }
}
