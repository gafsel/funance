import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/firestore/offline_write.dart';
import 'package:funances/core/presentation/display_names.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/repositories/account_repository.dart';
import 'package:funances/features/finance/domain/repositories/finance_repository.dart';
import 'package:funances/features/finance/domain/services/finance_service.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/domain/models/virtual_category.dart';
import 'package:funances/features/workspace/domain/repositories/category_repository.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// F4.8 §5.6 — "categoria virtual" tinha TRÊS implementações no app (mais uma
/// no backend), cada uma com a sua regra de "é virtual?". Estes casos fixam a
/// regra única: prefixo `virtual_`, como o servidor define.

mixin _NaoUsado {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} não usado no teste');
}

class _ContasFake with _NaoUsado implements IAccountRepository {
  _ContasFake(this.contas);

  final Map<String, AccountModel> contas;
  final List<String> lidas = [];

  @override
  Future<AccountModel> getAccount(String workspaceId, String accountId) async {
    lidas.add(accountId);
    final conta = contas[accountId];
    if (conta == null) throw StateError('conta $accountId não existe');
    return conta;
  }
}

class _CategoriasFake with _NaoUsado implements ICategoryRepository {
  final List<String> pedidas = [];

  @override
  Future<CategoryModel> getCategory(String workspaceId, String id) async {
    pedidas.add(id);
    return CategoryModel(
      id: id,
      name: 'nome gravado pelo servidor',
      icon: 'handshake',
      color: '#E57373',
      isSystem: true,
    );
  }
}

class _LancamentosFake with _NaoUsado implements IFinanceRepository {
  OrderModel? ordemGravada;
  InstallmentModel? parcelaGravada;

  @override
  Future<Written<OrderModel>> addOrder(
    String workspaceId,
    OrderModel order,
  ) async {
    ordemGravada = order;
    return (value: order, outcome: WriteOutcome.confirmed);
  }

  @override
  Future<WriteOutcome> updateInstallment(
    String workspaceId,
    InstallmentModel installment,
  ) async {
    parcelaGravada = installment;
    return WriteOutcome.confirmed;
  }
}

OrderModel _ordem({
  required String descricao,
  required OrderType type,
  required Map<String, AccountImpact> accounts,
}) => OrderModel(
  id: 'o1',
  amount: 500,
  description: descricao,
  dueDay: 10,
  startMonth: '2026-03',
  installmentType: InstallmentType.single,
  status: OrderStatus.active,
  type: type,
  accounts: accounts,
);

AccountModel _conta(String id, AccountType type) => switch (type) {
  AccountType.debt => AccountModel.debt(
    id: id,
    name: id,
    icon: 'handshake',
    color: '#000000',
    interestRate: 0,
    initialBalanceDate: DateTime(2026, 1, 1),
  ),
  AccountType.investment => AccountModel.investment(
    id: id,
    name: id,
    icon: 'savings',
    color: '#000000',
    interestRate: 0,
    initialBalanceDate: DateTime(2026, 1, 1),
  ),
  _ => AccountModel.checking(
    id: id,
    name: id,
    icon: 'account_balance',
    color: '#000000',
    initialBalanceDate: DateTime(2026, 1, 1),
  ),
};

void main() {
  group('a regra de "é virtual?"', () {
    test('é o prefixo do backend, não uma lista de quatro ids', () {
      for (final virtual in VirtualCategory.values) {
        expect(VirtualCategory.isVirtualId(virtual.id), isTrue);
      }

      // O ponto da mudança: uma categoria virtual que o servidor publique
      // amanhã já é reconhecida. Com a lista literal ela entraria nos
      // seletores como se fosse do usuário.
      expect(VirtualCategory.isVirtualId('virtual_algo_novo'), isTrue);
      expect(VirtualCategory.isVirtualId('mercado'), isFalse);
      expect(VirtualCategory.isVirtualId('initial-balance'), isFalse);
    });

    test('os ids são exatamente os que o servidor semeia', () {
      expect(VirtualCategory.debtExpense.id, 'virtual_debt_expense');
      expect(VirtualCategory.debtIncome.id, 'virtual_debt_income');
      expect(
        VirtualCategory.investmentExpense.id,
        'virtual_investment_expense',
      );
      expect(VirtualCategory.investmentIncome.id, 'virtual_investment_income');
    });

    test('CategoryModel.isVirtual usa a mesma regra', () {
      const nova = CategoryModel(
        id: 'virtual_algo_novo',
        name: '',
        icon: 'x',
        color: '#000000',
      );
      expect(nova.isVirtual, isTrue);

      const comum = CategoryModel(
        id: 'mercado',
        name: 'Mercado',
        icon: 'x',
        color: '#000000',
      );
      expect(comum.isVirtual, isFalse);
    });

    test('byId devolve null para o que não é virtual', () {
      expect(VirtualCategory.byId(null), isNull);
      expect(VirtualCategory.byId('mercado'), isNull);
      expect(
        VirtualCategory.byId('virtual_debt_income'),
        VirtualCategory.debtIncome,
      );
    });
  });

  group('resolve — a contrapartida da transferência', () {
    test('o DESTINO manda: dinheiro que entra na dívida é saída', () {
      expect(
        VirtualCategory.resolve(
          source: AccountType.checking,
          target: AccountType.debt,
        ),
        VirtualCategory.debtExpense,
      );
      expect(
        VirtualCategory.resolve(
          source: AccountType.checking,
          target: AccountType.investment,
        ),
        VirtualCategory.investmentExpense,
      );
    });

    test('sem destino especial, a origem decide: resgate é entrada', () {
      expect(
        VirtualCategory.resolve(
          source: AccountType.debt,
          target: AccountType.checking,
        ),
        VirtualCategory.debtIncome,
      );
      expect(
        VirtualCategory.resolve(
          source: AccountType.investment,
          target: AccountType.checking,
        ),
        VirtualCategory.investmentIncome,
      );
    });

    test('o destino tem precedência sobre a origem', () {
      // Investimento -> dívida: o dinheiro foi abater dívida, e é assim que o
      // 50-30-20 deve contar. A precedência estava implícita na ordem dos
      // `if` de `finance_service.dart`, duplicada em dois métodos.
      expect(
        VirtualCategory.resolve(
          source: AccountType.investment,
          target: AccountType.debt,
        ),
        VirtualCategory.debtExpense,
      );
    });

    test('transferência entre contas comuns não tem contrapartida', () {
      expect(
        VirtualCategory.resolve(
          source: AccountType.checking,
          target: AccountType.checking,
        ),
        isNull,
      );
      expect(VirtualCategory.resolve(), isNull);
    });
  });

  group('FinanceService aplica a contrapartida', () {
    FinanceService servicoCom(
      _ContasFake contas,
      _CategoriasFake categorias,
      _LancamentosFake lancamentos,
    ) => FinanceService(
      workspaceId: 'ws',
      repository: lancamentos,
      accountRepository: contas,
      categoryRepository: categorias,
    );

    test('a ORDER de transferência para dívida vira despesa de dívida', () async {
      final contas = _ContasFake({
        'cc': _conta('cc', AccountType.checking),
        'div': _conta('div', AccountType.debt),
      });
      final categorias = _CategoriasFake();
      final lancamentos = _LancamentosFake();

      await servicoCom(contas, categorias, lancamentos).addOrder(
        _ordem(
          descricao: 'Pagamento do empréstimo',
          type: OrderType.transfer,
          accounts: {'cc': AccountImpact.debt, 'div': AccountImpact.credit},
        ),
      );

      expect(categorias.pedidas, ['virtual_debt_expense']);
      expect(lancamentos.ordemGravada?.category?.id, 'virtual_debt_expense');
    });

    test(
      'a PARCELA segue a mesma regra — era uma cópia literal de 44 linhas',
      () async {
        final contas = _ContasFake({
          'cc': _conta('cc', AccountType.checking),
          'inv': _conta('inv', AccountType.investment),
        });
        final categorias = _CategoriasFake();
        final lancamentos = _LancamentosFake();

        await servicoCom(contas, categorias, lancamentos).updateInstallment(
          InstallmentModel(
            id: 'i1',
            orderId: 'o1',
            amount: 300,
            description: 'Aporte',
            dueDate: DateTime(2026, 3, 10),
            status: InstallmentStatus.pending,
            type: OrderType.transfer,
            installmentType: InstallmentType.single,
            accounts: const {
              'inv': AccountImpact.debt,
              'cc': AccountImpact.credit,
            },
          ),
        );

        expect(categorias.pedidas, ['virtual_investment_income']);
        expect(
          lancamentos.parcelaGravada?.category?.id,
          'virtual_investment_income',
        );
      },
    );

    test('o que não é transferência não lê conta nenhuma', () async {
      final contas = _ContasFake({});
      final categorias = _CategoriasFake();
      final lancamentos = _LancamentosFake();

      await servicoCom(contas, categorias, lancamentos).addOrder(
        _ordem(
          descricao: 'Mercado',
          type: OrderType.expense,
          accounts: {'cc': AccountImpact.debt},
        ),
      );

      expect(contas.lidas, isEmpty);
      expect(categorias.pedidas, isEmpty);
      expect(lancamentos.ordemGravada?.category, isNull);
    });

    test('transferência entre contas comuns não troca a categoria', () async {
      final contas = _ContasFake({
        'cc': _conta('cc', AccountType.checking),
        'poup': _conta('poup', AccountType.checking),
      });
      final categorias = _CategoriasFake();
      final lancamentos = _LancamentosFake();

      await servicoCom(contas, categorias, lancamentos).addOrder(
        _ordem(
          descricao: 'Entre contas',
          type: OrderType.transfer,
          accounts: {'cc': AccountImpact.debt, 'poup': AccountImpact.credit},
        ),
      );

      expect(categorias.pedidas, isEmpty);
      expect(lancamentos.ordemGravada?.category, isNull);
    });
  });

  group('o nome que aparece na tela', () {
    late AppLocalizations pt;
    late AppLocalizations en;

    setUpAll(() async {
      WidgetsFlutterBinding.ensureInitialized();
      pt = await AppLocalizations.delegate.load(const Locale('pt'));
      en = await AppLocalizations.delegate.load(const Locale('en'));
    });

    CategoryModel comoOServidorGrava(String id, String nome) => CategoryModel(
      id: id,
      name: nome,
      icon: 'handshake',
      color: '#E57373',
      isSystem: true,
    );

    test('a categoria virtual é traduzida, e não lida do Firestore', () {
      final gravada = comoOServidorGrava(
        VirtualCategory.debtExpense.id,
        'Empréstimo/Dívidas',
      );

      expect(gravada.displayName(pt), pt.categoryVirtualDebt);
      // Este é o bug: `name` não é vazio, então o fallback nunca pegava e
      // quem usa o app em inglês lia o português do servidor.
      expect(gravada.displayName(en), en.categoryVirtualDebt);
      expect(gravada.displayName(en), isNot('Empréstimo/Dívidas'));
    });

    test('investimento idem, nos dois sentidos', () {
      for (final virtual in [
        VirtualCategory.investmentExpense,
        VirtualCategory.investmentIncome,
      ]) {
        final gravada = comoOServidorGrava(virtual.id, 'Investimentos');
        expect(gravada.displayName(en), en.categoryVirtualInvestment);
      }
    });

    test('o saldo inicial também', () {
      final gravada = comoOServidorGrava('initial-balance', 'Saldo Inicial');
      expect(gravada.displayName(en), en.categoryInitialBalance);
    });

    test('categoria do usuário continua com o nome dela', () {
      const mercado = CategoryModel(
        id: 'mercado',
        name: 'Mercado',
        icon: 'x',
        color: '#000000',
      );
      expect(mercado.displayName(en), 'Mercado');
      expect(mercado.displayName(pt), 'Mercado');
    });
  });
}
