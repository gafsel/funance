import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/repositories/account_repository.dart';
import 'package:funances/features/finance/domain/repositories/finance_repository.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/domain/repositories/category_repository.dart';
import 'package:funances/features/workspace/domain/repositories/workspace_repository.dart';
import 'package:funances/features/workspace/presentation/providers.dart';

mixin _Unimplemented {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    'Método não esperado neste teste: ${invocation.memberName}',
  );
}

class _FakeWorkspaceRepository with _Unimplemented
    implements IWorkspaceRepository {}

class _FakeAccountRepository with _Unimplemented
    implements IAccountRepository {
  _FakeAccountRepository(this.accounts);

  final List<AccountModel> accounts;

  @override
  Stream<List<AccountModel>> getAccounts(
    String workspaceId, {
    AccountType? type,
  }) => Stream.value(accounts);
}

class _FakeCategoryRepository with _Unimplemented
    implements ICategoryRepository {
  final controller = StreamController<List<CategoryModel>>.broadcast();

  @override
  Stream<List<CategoryModel>> getCategories(String workspaceId) =>
      controller.stream;
}

class _FakeFinanceRepository with _Unimplemented implements IFinanceRepository {
  final List<({DateTime? startDate, DateTime? endDate, String? accountId})>
  watchCalls = [];

  @override
  Stream<List<InstallmentModel>> watchInstallments(
    String workspaceId, {
    int? limit,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    OrderType? type,
    InstallmentStatus? status,
  }) {
    watchCalls.add((
      startDate: startDate,
      endDate: endDate,
      accountId: accountId,
    ));
    return Stream.value([
      _installment(
        amount: 30,
        category: _food,
        description: 'Mercado',
      ).copyWith(id: 'inst-1', type: OrderType.expense, isInvoice: false),
    ]);
  }
}

const _food = CategoryModel(
  id: 'cat-food',
  name: 'Alimentação',
  icon: 'restaurant',
  color: '#FF0000',
);

final _card = CreditCardAccount(
  id: 'card-1',
  name: 'Cartão',
  icon: 'credit_card',
  color: '#123456',
  initialBalanceDate: DateTime(2026, 1, 1, 12),
  limit: 5000,
  closingDay: 20,
  dueDay: 28,
);

InstallmentModel _installment({
  required double amount,
  CategoryModel? category,
  String description = 'Fatura de março',
}) {
  return InstallmentModel(
    id: 'inv-1',
    orderId: 'order-1',
    amount: amount,
    description: description,
    dueDate: DateTime(2026, 3, 28, 12),
    status: InstallmentStatus.pending,
    type: OrderType.transfer,
    installmentType: InstallmentType.single,
    accounts: const {'card-1': AccountImpact.credit},
    category: category,
    isInvoice: true,
  );
}

void main() {
  group('chave da fatura', () {
    test('não muda quando a parcela é editada', () {
      final invoice = _installment(amount: 100);
      final edited = invoice.copyWith(
        amount: 250,
        description: 'Fatura de março (revisada)',
        status: InstallmentStatus.paid,
      );

      expect(edited, isNot(invoice));
      expect(edited.invoiceKey, invoice.invoiceKey);
    });

    test('a família devolve o mesmo provider para a parcela editada', () {
      final invoice = _installment(amount: 100);
      final edited = invoice.copyWith(amount: 250);

      // Providers de família são iguais (e compartilham o mesmo elemento no
      // container) quando o argumento é igual.
      expect(
        FinanceViewProviders.invoiceInstallments(invoice.invoiceKey),
        FinanceViewProviders.invoiceInstallments(edited.invoiceKey),
      );
      expect(
        FinanceViewProviders.invoicePieChart(invoice.invoiceKey),
        FinanceViewProviders.invoicePieChart(edited.invoiceKey),
      );
      expect(
        FinanceViewProviders.invoiceInstallmentsList(invoice.invoiceKey),
        FinanceViewProviders.invoiceInstallmentsList(edited.invoiceKey),
      );
    });
  });

  group('chave de período mensal', () {
    test('colapsa instantes do mesmo mês', () {
      expect(DateTime(2026, 3, 1, 10, 30, 12, 345).monthKey, '2026-03');
      expect(DateTime(2026, 3, 28).monthKey, '2026-03');
      expect(DateTime(2026, 12, 31, 23, 59).monthKey, '2026-12');
    });

    test('faz o round-trip com parseMonthKey', () {
      final (year, month) = DateTimeExtension.parseMonthKey(
        DateTime(2026, 3, 9, 7, 45).monthKey,
      );
      expect(year, 2026);
      expect(month, 3);
    });
  });

  test('as parcelas da fatura seguem o ciclo do cartão', () async {
    final financeRepository = _FakeFinanceRepository();
    final container = ProviderContainer(
      overrides: [
        WorkspaceDomainProviders.repository.overrideWithValue(
          _FakeWorkspaceRepository(),
        ),
        AccountDomainProviders.repository.overrideWithValue(
          _FakeAccountRepository([_card]),
        ),
        CategoryDomainProviders.repository.overrideWithValue(
          _FakeCategoryRepository(),
        ),
        FinanceDomainProviders.repository.overrideWithValue(financeRepository),
      ],
    );
    addTearDown(container.dispose);

    final invoice = _installment(amount: 100);
    final key = invoice.invoiceKey;

    // As famílias são autoDispose: sem um listener o provider morre entre um
    // `read` e outro.
    container.listen(
      FinanceViewProviders.invoiceInstallments(key),
      (_, _) {},
      fireImmediately: true,
    );
    container.listen(
      FinanceViewProviders.invoicePieChart(key),
      (_, _) {},
      fireImmediately: true,
    );

    final installments = await container.read(
      FinanceViewProviders.invoiceInstallments(key).future,
    );
    expect(installments, hasLength(1));

    expect(financeRepository.watchCalls, hasLength(1));
    final call = financeRepository.watchCalls.single;
    expect(call.accountId, 'card-1');
    // Fechamento no dia 20: o ciclo da fatura que vence em 28/03 vai de
    // 21/02 a 20/03.
    expect(call.startDate!.isBefore(call.endDate!), isTrue);
    expect(call.endDate!.isBefore(invoice.dueDate), isTrue);

    // O gráfico reaproveita o mesmo stream — não dispara uma segunda query.
    final slices = await container.read(
      FinanceViewProviders.invoicePieChart(key).future,
    );
    expect(slices, hasLength(1));
    expect(slices.single.category.id, 'cat-food');
    expect(financeRepository.watchCalls, hasLength(1));
  });

  group('conta resolvida da parcela', () {
    test('usa o target quando existe', () {
      final invoice = _installment(amount: 100);

      expect(invoice.type, OrderType.transfer);
      expect(invoice.resolvedAccountId, 'card-1');
      expect(invoice.invoiceKey.accountId, 'card-1');
    });

    test('cai no source quando a fatura já foi paga', () {
      // Fatura paga: deixa de ser transferência, então accountIdTarget é null
      // e a conta vem do lado debt.
      final paid = _installment(amount: 100).copyWith(
        type: OrderType.expense,
        status: InstallmentStatus.paid,
        accounts: const {
          'checking-1': AccountImpact.debt,
          'card-1': AccountImpact.credit,
        },
      );

      expect(paid.accountIdTarget, isNull);
      expect(paid.resolvedAccountId, 'checking-1');
      expect(paid.invoiceKey.accountId, isNotEmpty);
    });

    test('cai na primeira conta impactada quando não há source nem target', () {
      final odd = _installment(amount: 100).copyWith(
        type: OrderType.expense,
        accounts: const {'card-1': AccountImpact.credit},
      );

      expect(odd.accountIdTarget, isNull);
      expect(odd.accountIdSource, isNull);
      expect(odd.resolvedAccountId, 'card-1');
      expect(
        odd.invoiceKey.accountId,
        'card-1',
        reason: 'chave vazia faria o provider listar o extrato inteiro',
      );
    });
  });

  test('o filtro de categoria sobrevive ao vir do detalhe de fatura', () async {
    final categoryRepository = _FakeCategoryRepository();
    addTearDown(categoryRepository.controller.close);

    final container = ProviderContainer(
      overrides: [
        WorkspaceDomainProviders.repository.overrideWithValue(
          _FakeWorkspaceRepository(),
        ),
        AccountDomainProviders.repository.overrideWithValue(
          _FakeAccountRepository([_card]),
        ),
        CategoryDomainProviders.repository.overrideWithValue(
          categoryRepository,
        ),
        FinanceDomainProviders.repository.overrideWithValue(
          _FakeFinanceRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    // A query que a barra de filtro do detalhe de fatura carrega, já com a
    // categoria escolhida pelo usuário.
    final invoice = _installment(amount: 100);
    final query = TransactionQuery(
      accountId: invoice.invoiceKey.accountId,
      categoryId: 'cat-food',
      startDate: DateTime(2026, 2, 21),
      endDate: DateTime(2026, 3, 20, 23, 59, 59),
    );

    final filter = FinanceViewProviders.transactionFilter(query);
    container.listen(filter, (_, _) {}, fireImmediately: true);

    // A lista de categorias ainda não chegou.
    expect(container.read(filter).category, isNull);

    categoryRepository.controller.add(const [_food]);
    // A categoria atravessa dois StreamProvider encadeados (allStream -> byId),
    // então leva algumas voltas do event loop.
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }

    expect(container.read(filter).category, _food);
    expect(
      container.read(filter).toQuery().categoryId,
      'cat-food',
      reason: 'o filtro de categoria foi descartado em silêncio',
    );
  });
}
