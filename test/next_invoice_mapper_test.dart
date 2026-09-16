import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/finance/data/models/account_mapper.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';

/// F1.8 — o app LÊ `accounts/{id}.nextInvoice` e a janela do ciclo gravada na
/// parcela de fatura. Estes testes cobrem a conversão do documento cru: é onde
/// um `Timestamp` esquecido viraria uma fatura sem data.

/// Instante do meio-dia de São Paulo (UTC-3 o ano inteiro desde 2019).
DateTime _spNoon(String dateKey) {
  final parts = dateKey.split('-').map(int.parse).toList();
  return DateTime.utc(parts[0], parts[1], parts[2], 15);
}

Map<String, dynamic> _cardDoc({Map<String, dynamic>? nextInvoice}) => {
  'name': 'Cartão',
  'icon': 'credit_card',
  'color': '#8A05BE',
  'runtimeType': 'creditCard',
  'isDeleted': false,
  'initialBalance': 0.0,
  'initialBalanceDate': Timestamp.fromDate(DateTime.utc(2025, 1, 1, 15)),
  'limit': 5000.0,
  'closingDay': 5,
  'dueDay': 10,
  'nextInvoice': ?nextInvoice,
};

Map<String, dynamic> _nextInvoiceDoc({
  bool completo = true,
  double amount = 350.5,
}) => {
  'dueDate': Timestamp.fromDate(_spNoon('2025-03-10')),
  'closingDate': Timestamp.fromDate(DateTime.utc(2025, 3, 5, 3)),
  'cycleStart': Timestamp.fromDate(DateTime.utc(2025, 2, 5, 3)),
  if (completo)
    'cycleEnd': Timestamp.fromDate(
      DateTime.utc(2025, 3, 5, 2, 59, 59, 999),
    ),
  'amount': amount,
  'orderId': 'invoice-card-1-2025-03-10',
  'installmentId': 'inst-fatura',
  'status': 'pending',
};

void main() {
  group('mapper de nextInvoice', () {
    test('converte os Timestamps preservando o instante', () {
      final account = AccountModel.fromJson(
        accountJsonFromFirestore(
          _cardDoc(nextInvoice: _nextInvoiceDoc()),
          'card-1',
        ),
      );

      final card = account as CreditCardAccount;
      final next = card.nextInvoice!;

      expect(next.amount, 350.5);
      expect(next.orderId, 'invoice-card-1-2025-03-10');
      expect(next.installmentId, 'inst-fatura');
      expect(next.status, InstallmentStatus.pending);
      expect(next.isEmpty, isFalse);

      // As bordas do ciclo são limites de consulta: o instante precisa chegar
      // intacto, e não normalizado para meio-dia como uma data de calendário.
      expect(next.cycleStart.toUtc(), DateTime.utc(2025, 2, 5, 3));
      expect(next.cycleEnd.toUtc(), DateTime.utc(2025, 3, 5, 2, 59, 59, 999));
      expect(next.closingDate.toUtc(), DateTime.utc(2025, 3, 5, 3));
      expect(next.dueDate.toUtc(), _spNoon('2025-03-10'));
    });

    test('conta sem o campo vira nextInvoice nulo (base antes do backfill)', () {
      final account = AccountModel.fromJson(
        accountJsonFromFirestore(_cardDoc(), 'card-1'),
      );

      expect((account as CreditCardAccount).nextInvoice, isNull);
    });

    test('resumo incompleto é descartado em vez de chegar pela metade', () {
      final account = AccountModel.fromJson(
        accountJsonFromFirestore(
          _cardDoc(nextInvoice: _nextInvoiceDoc(completo: false)),
          'card-1',
        ),
      );

      // Sem `cycleEnd` não há janela: melhor "calculando" do que uma fatura
      // com borda pela metade.
      expect((account as CreditCardAccount).nextInvoice, isNull);
    });

    test('ciclo aberto sem compras é reconhecido como vazio', () {
      final doc = _nextInvoiceDoc(amount: 0)..['installmentId'] = null;
      final account = AccountModel.fromJson(
        accountJsonFromFirestore(_cardDoc(nextInvoice: doc), 'card-1'),
      );

      final next = (account as CreditCardAccount).nextInvoice!;
      expect(next.isEmpty, isTrue);
      expect(next.amount, 0);
      expect(next.installmentId, isNull);
    });

    test('o cliente NUNCA envia nextInvoice de volta', () {
      final account = AccountModel.fromJson(
        accountJsonFromFirestore(
          _cardDoc(nextInvoice: _nextInvoiceDoc()),
          'card-1',
        ),
      );

      // As rules negam o campo num create/update da conta; o modelo não o
      // serializa, então o formulário continua podendo mandar o documento.
      expect(account.toJson().containsKey('nextInvoice'), isFalse);
    });
  });

  group('mapper da janela do ciclo na parcela', () {
    test('não serializa cycleStart/cycleEnd de volta para o servidor', () {
      final invoice = InstallmentModel(
        id: 'inv-1',
        orderId: 'invoice-card-1-2025-03-10',
        amount: 350.5,
        description: 'Fatura Cartão',
        dueDate: _spNoon('2025-03-10'),
        status: InstallmentStatus.pending,
        type: OrderType.transfer,
        installmentType: InstallmentType.single,
        isInvoice: true,
        cycleStart: DateTime.utc(2025, 2, 5, 3),
        cycleEnd: DateTime.utc(2025, 3, 5, 2, 59, 59, 999),
      );

      final json = invoice.toJson();
      expect(json.containsKey('cycleStart'), isFalse);
      expect(json.containsKey('cycleEnd'), isFalse);
    });
  });
}
