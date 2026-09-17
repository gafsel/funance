import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

/// As categorias que o SERVIDOR cria para dar contrapartida a uma
/// transferência.
///
/// Transferir da conta corrente para um empréstimo não é "gasto" nem
/// "receita": é abater dívida. O servidor resolve isso trocando a categoria da
/// transferência por uma destas quatro, e o 50-30-20 e o coaching contam a
/// partir delas.
///
/// Havia TRÊS implementações desta mesma ideia no app — a árvore de decisão
/// duplicada linha a linha em `finance_service.dart` (uma cópia para
/// `OrderModel`, outra para `InstallmentModel`), um `switch` por id em
/// `transaction_list_notifier.dart` e o enum de apresentação
/// `TransferAccounting` — mais uma quarta no backend. Cada uma decidia "é
/// virtual?" de um jeito: aqui era uma lista literal de quatro ids, lá é o
/// prefixo.
///
/// **A regra que vale é a do backend**, porque é ele quem grava: um id é
/// virtual quando começa com `virtual_`
/// (`functions/.../category.model.ts:VIRTUAL_CATEGORY_ID_PREFIX`). Com a
/// lista literal, uma categoria virtual nova publicada pelo servidor entraria
/// nos seletores do app como se fosse do usuário.
enum VirtualCategory {
  debtExpense,
  debtIncome,
  investmentExpense,
  investmentIncome;

  /// Mesmo prefixo de `VIRTUAL_CATEGORY_ID_PREFIX` no backend.
  static const String idPrefix = 'virtual_';

  /// Id da categoria sintética do saldo inicial (`INITIAL_BALANCE_CATEGORY_ID`
  /// no backend). Não é virtual — é de sistema —, mas o app também não tem
  /// tradução para o nome que o servidor grava.
  static const String initialBalanceId = 'initial-balance';

  String get id => switch (this) {
    debtExpense => '${idPrefix}debt_expense',
    debtIncome => '${idPrefix}debt_income',
    investmentExpense => '${idPrefix}investment_expense',
    investmentIncome => '${idPrefix}investment_income',
  };

  /// Que tipo de conta do outro lado da transferência gerou esta categoria.
  AccountType get accountType => switch (this) {
    debtExpense || debtIncome => AccountType.debt,
    investmentExpense || investmentIncome => AccountType.investment,
  };

  CategoryType get categoryType => switch (this) {
    debtExpense || investmentExpense => CategoryType.expense,
    debtIncome || investmentIncome => CategoryType.income,
  };

  static VirtualCategory? byId(String? id) {
    if (id == null) return null;
    for (final value in values) {
      if (value.id == id) return value;
    }
    return null;
  }

  /// A regra única de "é virtual?". Adotada do backend: prefixo, não lista.
  static bool isVirtualId(String id) => id.startsWith(idPrefix);

  /// A contrapartida de uma transferência, a partir dos tipos das duas contas.
  ///
  /// Esta árvore estava escrita três vezes: duas em `finance_service.dart` (a
  /// segunda uma cópia literal de 44 linhas, trocando `OrderModel` por
  /// `InstallmentModel`) e uma em `summary.service.ts`.
  ///
  /// O DESTINO manda: dinheiro que ENTRA numa dívida ou num investimento é
  /// saída do ponto de vista de quem planeja (você abateu ou aportou). Só
  /// quando o destino é uma conta comum é que a origem decide — aí o dinheiro
  /// veio de um empréstimo ou de um resgate, e é entrada.
  static VirtualCategory? resolve({AccountType? source, AccountType? target}) {
    return switch (target) {
      AccountType.debt => debtExpense,
      AccountType.investment => investmentExpense,
      _ => switch (source) {
        AccountType.debt => debtIncome,
        AccountType.investment => investmentIncome,
        _ => null,
      },
    };
  }
}
