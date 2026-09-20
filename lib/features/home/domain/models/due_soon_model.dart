import 'package:flutter/foundation.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';

/// Quando uma coisa vence, do ponto de vista de HOJE.
enum DueDay { today, tomorrow }

/// Que tipo de compromisso é.
enum DueKind {
  /// Uma parcela pendente com vencimento no dia.
  installment,

  /// A fatura de um cartão FECHANDO — o último dia para uma compra cair
  /// nela, que é uma informação de prazo tanto quanto um vencimento.
  invoiceClosing,
}

/// Uma linha do bloco "vence hoje e amanhã".
@immutable
class DueSoonItem {
  const DueSoonItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.day,
    required this.kind,
    this.route,
  });

  /// Identidade estável, para chave de widget e para deduplicar.
  final String id;

  /// O que vence: descrição da parcela ou nome do cartão.
  final String title;

  /// Valor em aberto. Pode ser zero numa fatura de ciclo vazio.
  final double amount;

  final DueDay day;
  final DueKind kind;

  /// Para onde o toque leva, quando há um destino.
  final String? route;
}

/// O que vence hoje e amanhã, já ordenado.
@immutable
class DueSoon {
  const DueSoon(this.items);

  static const DueSoon empty = DueSoon(<DueSoonItem>[]);

  final List<DueSoonItem> items;

  bool get isEmpty => items.isEmpty;

  List<DueSoonItem> get today => [
    for (final i in items)
      if (i.day == DueDay.today) i,
  ];

  List<DueSoonItem> get tomorrow => [
    for (final i in items)
      if (i.day == DueDay.tomorrow) i,
  ];

  /// Soma de tudo que vence na janela. É o número que o bloco mostra fechado.
  double get total => items.fold(0, (sum, i) => sum + i.amount);
}

/// Monta a janela de dois dias a partir do que o app já sabe.
///
/// Função PURA de propósito: a regra de "o que conta como vencendo" é a parte
/// que erra, e ela precisa ser testável sem Firestore, sem widget e sem
/// relógio de verdade.
///
/// O que entra:
///
/// - parcelas PENDENTES com vencimento em hoje ou amanhã. Pagas e liquidadas
///   ficam de fora: já foram resolvidas, e listá-las transformaria o bloco
///   num extrato;
/// - faturas de cartão cujo FECHAMENTO cai na janela. Fechamento não é
///   vencimento, mas é o último dia em que uma compra ainda entra nesta
///   fatura — e é a informação de prazo que some da tela justamente por não
///   ter um "vencimento" no extrato.
///
/// A parcela da própria fatura, quando existe, tem precedência sobre o aviso
/// de fechamento do mesmo cartão: são o mesmo compromisso visto de dois
/// lugares, e contá-lo duas vezes inflaria o total.
DueSoon dueSoonFrom({
  required DateTime today,
  required List<InstallmentModel> pending,
  required List<AccountModel> accounts,
}) {
  final hoje = DateTime(today.year, today.month, today.day);
  final amanha = hoje.add(const Duration(days: 1));

  DueDay? dayOf(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    if (d == hoje) return DueDay.today;
    if (d == amanha) return DueDay.tomorrow;
    return null;
  }

  final items = <DueSoonItem>[];
  final invoiceOrderIds = <String>{};

  for (final installment in pending) {
    if (installment.status != InstallmentStatus.pending) continue;
    if (installment.type == OrderType.income) continue;

    final day = dayOf(installment.dueDate);
    if (day == null) continue;

    if (installment.isInvoice) invoiceOrderIds.add(installment.orderId);

    items.add(
      DueSoonItem(
        id: installment.id,
        title: installment.description,
        amount: installment.amount,
        day: day,
        kind: DueKind.installment,
        route: '/transactions/form?installmentId=${installment.id}',
      ),
    );
  }

  for (final account in accounts) {
    if (account is! CreditCardAccount) continue;
    final invoice = account.nextInvoice;
    if (invoice == null) continue;

    final day = dayOf(invoice.closingDate);
    if (day == null) continue;

    // Mesma fatura já listada pela parcela: o aviso de fechamento seria a
    // segunda voz do mesmo compromisso.
    if (invoiceOrderIds.contains(invoice.orderId)) continue;

    items.add(
      DueSoonItem(
        id: 'invoice:${account.id}',
        title: account.name,
        amount: invoice.amount,
        day: day,
        kind: DueKind.invoiceClosing,
        route: invoice.installmentId == null
            ? null
            : '/invoices/${invoice.installmentId}',
      ),
    );
  }

  // Hoje antes de amanhã; dentro do dia, o maior valor primeiro — é o que
  // decide se dá para deixar para depois.
  items.sort((a, b) {
    final porDia = a.day.index.compareTo(b.day.index);
    if (porDia != 0) return porDia;
    return b.amount.compareTo(a.amount);
  });

  return DueSoon(List.unmodifiable(items));
}
