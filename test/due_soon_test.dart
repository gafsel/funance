import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/home/domain/models/due_soon_model.dart';

/// D3 — a regra de "o que conta como vencendo".
///
/// A parte que erra num bloco de prazo é a REGRA, não o desenho: o que entra
/// na janela, o que já foi resolvido, e o que aparece duas vezes por ser o
/// mesmo compromisso visto de dois lugares. Por isso [dueSoonFrom] é uma
/// função pura, testada aqui sem Firestore, sem widget e sem relógio.

final _hoje = DateTime(2026, 3, 15);
final _amanha = DateTime(2026, 3, 16);
final _depois = DateTime(2026, 3, 17);

InstallmentModel _parcela({
  String id = 'i1',
  String orderId = 'o1',
  String description = 'Aluguel',
  double amount = 1800,
  required DateTime dueDate,
  InstallmentStatus status = InstallmentStatus.pending,
  OrderType type = OrderType.expense,
  bool isInvoice = false,
}) => InstallmentModel(
  id: id,
  orderId: orderId,
  amount: amount,
  description: description,
  // O app grava vencimento ao MEIO-DIA; o recorte por dia tem de ignorar a
  // hora, ou a janela dependeria do fuso da máquina.
  dueDate: DateTime(dueDate.year, dueDate.month, dueDate.day, 12),
  status: status,
  type: type,
  installmentType: InstallmentType.single,
  isInvoice: isInvoice,
);

AccountModel _cartao({
  String id = 'c1',
  String name = 'Nubank',
  required DateTime closingDate,
  double amount = 950,
  String orderId = 'invoice-c1-2026-03-15',
  String? installmentId,
}) => AccountModel.creditCard(
  id: id,
  name: name,
  icon: 'credit_card',
  color: '#8E5BD9',
  limit: 5000,
  initialBalanceDate: DateTime(2026, 1, 1),
  closingDay: closingDate.day,
  dueDay: closingDate.day + 7,
  nextInvoice: NextInvoice(
    dueDate: closingDate.add(const Duration(days: 7)),
    closingDate: closingDate,
    cycleStart: closingDate.subtract(const Duration(days: 30)),
    cycleEnd: closingDate,
    amount: amount,
    orderId: orderId,
    installmentId: installmentId,
  ),
);

DueSoon _build({
  List<InstallmentModel> pending = const [],
  List<AccountModel> accounts = const [],
}) => dueSoonFrom(today: _hoje, pending: pending, accounts: accounts);

void main() {
  group('a janela é de dois dias', () {
    test('pega hoje e amanhã, e não depois de amanhã', () {
      final due = _build(
        pending: [
          _parcela(id: 'hoje', dueDate: _hoje),
          _parcela(id: 'amanha', dueDate: _amanha),
          _parcela(id: 'depois', dueDate: _depois),
        ],
      );

      expect(due.items.map((i) => i.id), ['hoje', 'amanha']);
      expect(due.today.single.id, 'hoje');
      expect(due.tomorrow.single.id, 'amanha');
    });

    test('a hora gravada não desloca o dia', () {
      final due = dueSoonFrom(
        // Fim do dia: o recorte ingênuo por `DateTime` perderia hoje inteiro.
        today: DateTime(2026, 3, 15, 23, 59),
        pending: [_parcela(dueDate: _hoje)],
        accounts: const [],
      );

      expect(due.today, hasLength(1));
    });

    test('o que já venceu ontem não entra', () {
      final due = _build(
        pending: [_parcela(dueDate: _hoje.subtract(const Duration(days: 1)))],
      );

      expect(
        due.isEmpty,
        isTrue,
        reason:
            'o bloco é sobre o que ainda dá tempo de resolver; atraso é outro '
            'assunto e outra conversa',
      );
    });
  });

  group('o que não é compromisso', () {
    test('parcela paga some', () {
      final due = _build(
        pending: [
          _parcela(dueDate: _hoje, status: InstallmentStatus.paid),
          _parcela(id: 'i2', dueDate: _hoje, status: InstallmentStatus.settled),
        ],
      );

      expect(due.isEmpty, isTrue);
    });

    test('receita não é conta a pagar', () {
      final due = _build(
        pending: [_parcela(dueDate: _hoje, type: OrderType.income)],
      );

      expect(
        due.isEmpty,
        isTrue,
        reason: 'o salário caindo hoje não é algo a resolver',
      );
    });

    test('conta que não é cartão não fala de fechamento', () {
      final due = _build(
        accounts: [
          AccountModel.checking(
            id: 'cc',
            name: 'Conta',
            icon: 'account_balance',
            color: '#1565C0',
            initialBalanceDate: _hoje,
          ),
        ],
      );

      expect(due.isEmpty, isTrue);
    });
  });

  group('a fatura fechando', () {
    test('entra como compromisso, com o nome do cartão', () {
      final due = _build(accounts: [_cartao(closingDate: _amanha)]);

      final item = due.items.single;
      expect(item.kind, DueKind.invoiceClosing);
      expect(item.title, 'Nubank');
      expect(item.day, DueDay.tomorrow);
      expect(item.amount, 950);
    });

    test('não aparece duas vezes quando a parcela dela já está na lista', () {
      final due = _build(
        pending: [
          _parcela(
            id: 'parcela-da-fatura',
            orderId: 'invoice-c1-2026-03-15',
            description: 'Fatura Nubank',
            amount: 950,
            dueDate: _hoje,
            isInvoice: true,
          ),
        ],
        accounts: [
          _cartao(closingDate: _hoje, orderId: 'invoice-c1-2026-03-15'),
        ],
      );

      expect(due.items, hasLength(1));
      expect(
        due.total,
        950,
        reason:
            'o mesmo compromisso visto de dois lugares dobraria o total, e o '
            'total é o número que o bloco mostra fechado',
      );
    });

    test('fechamento fora da janela não entra', () {
      final due = _build(accounts: [_cartao(closingDate: _depois)]);

      expect(due.isEmpty, isTrue);
    });
  });

  group('a ordem', () {
    test('hoje antes de amanhã; dentro do dia, o maior valor primeiro', () {
      final due = _build(
        pending: [
          _parcela(id: 'a', amount: 200, dueDate: _amanha),
          _parcela(id: 'b', amount: 100, dueDate: _hoje),
          _parcela(id: 'c', amount: 900, dueDate: _hoje),
        ],
      );

      expect(due.items.map((i) => i.id), ['c', 'b', 'a']);
    });

    test('o total soma a janela inteira', () {
      final due = _build(
        pending: [
          _parcela(id: 'a', amount: 200, dueDate: _amanha),
          _parcela(id: 'b', amount: 100, dueDate: _hoje),
        ],
        accounts: [_cartao(closingDate: _hoje, amount: 50)],
      );

      expect(due.total, 350);
    });
  });
}
