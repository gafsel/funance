import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/router/app_router.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';

/// F3.9 (QA) — o endereço é o único estado das telas de detalhe, então um
/// parâmetro vazio não pode virar um id. `/accounts/form?id=` era montado pela
/// própria lista de contas quando não havia conta selecionada, e a rota
/// respondia "este item não existe mais" em cima do formulário de criação.
void main() {
  group('idParam', () {
    test('ausente, vazio e só espaço são todos "não me disseram qual"', () {
      expect(idParam(Uri.parse('/accounts/form'), 'id'), isNull);
      expect(idParam(Uri.parse('/accounts/form?id='), 'id'), isNull);
      expect(idParam(Uri.parse('/accounts/form?id=%20'), 'id'), isNull);
    });

    test('id de verdade passa inteiro', () {
      expect(idParam(Uri.parse('/accounts/form?id=acc-1'), 'id'), 'acc-1');
    });
  });

  group('/accounts/form', () {
    test('sem query: formulário de criação, sem tipo sugerido', () {
      final args = accountFormArgs(Uri.parse('/accounts/form'));

      expect(args.accountId, isNull);
      expect(args.initialType, isNull);
    });

    test('com `?id=` vazio: criação, NÃO uma conta inexistente', () {
      final args = accountFormArgs(Uri.parse('/accounts/form?id='));

      expect(args.accountId, isNull);
    });

    test('com `?type=`: criação já com o tipo escolhido', () {
      final args = accountFormArgs(Uri.parse('/accounts/form?type=creditCard'));

      expect(args.accountId, isNull);
      expect(args.initialType, AccountType.creditCard);
    });

    test('tipo desconhecido não derruba a rota', () {
      expect(
        accountFormArgs(Uri.parse('/accounts/form?type=cofrinho')).initialType,
        isNull,
      );
    });

    test('com id: edição daquela conta', () {
      final args = accountFormArgs(Uri.parse('/accounts/form?id=acc-1'));

      expect(args.accountId, 'acc-1');
    });
  });

  group('/workspace/accounts', () {
    test('sem `?type=`: a lista abre em todos os tipos', () {
      expect(accountListType(Uri.parse('/workspace/accounts')), isNull);
      expect(accountListType(Uri.parse('/workspace/accounts?type=')), isNull);
    });

    test('com `?type=`: a lista abre filtrada naquele tipo', () {
      expect(
        accountListType(Uri.parse('/workspace/accounts?type=creditCard')),
        AccountType.creditCard,
      );
      expect(
        accountListType(Uri.parse('/workspace/accounts?type=debt')),
        AccountType.debt,
      );
    });

    test('tipo desconhecido abre em todos, sem derrubar a rota', () {
      expect(
        accountListType(Uri.parse('/workspace/accounts?type=cofrinho')),
        isNull,
      );
    });
  });
}
