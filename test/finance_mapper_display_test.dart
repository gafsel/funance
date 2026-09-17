import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/presentation/display_names.dart';
import 'package:funances/features/finance/data/models/finance_mapper.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/l10n/app_localizations.dart';

/// F3.8 (QA) — o mapper não escolhe palavra. Quando a IA não manda nome, ele
/// devolve vazio; quem diz "Sem categoria" é a tela, no idioma de quem lê.
/// Enquanto o padrão nascia no mapper, uma sugestão aceita no onboarding
/// gravava "Nova Conta" no Firestore de um usuário em inglês.
void main() {
  late AppLocalizations pt;
  late AppLocalizations en;

  setUpAll(() async {
    pt = await AppLocalizations.delegate.load(const Locale('pt'));
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('o mapper devolve vazio, não português', () {
    test('categoria sem nome (e json inválido)', () {
      expect(FinanceMapper.toCategory(null).name, '');
      expect(FinanceMapper.toCategory(const {'id': 'c1'}).name, '');
      expect(FinanceMapper.toCategory(const {'name': 'Mercado'}).name, 'Mercado');
    });

    test('conta sem nome', () {
      expect(FinanceMapper.toAccount(null, DateTime(2026), 0).name, '');
      expect(
        FinanceMapper.toAccount(const {'id': 'a1'}, DateTime(2026), 0).name,
        '',
      );
    });

    test('lançamento e transação de extrato sem descrição', () {
      expect(FinanceMapper.toOrder(null).description, '');
      expect(FinanceMapper.toOrder(const {'amount': 10}).description, '');
      expect(
        FinanceMapper.toReconciliationTransaction(
          const {'amount': 10},
        ).description,
        '',
      );
    });

    test('meta sem nome', () {
      expect(FinanceMapper.toGoal(const {'targetAmount': 100}).name, '');
    });
  });

  group('a tela escolhe a palavra', () {
    const semNome = CategoryModel(id: 'c1', name: '', icon: 'x', color: '#fff');
    const outros = CategoryModel(
      id: CategoryModel.othersId,
      name: '',
      icon: 'category',
      color: '#333',
    );

    test('categoria sem nome vira "Sem categoria" no idioma da tela', () {
      expect(semNome.displayName(pt), 'Sem categoria');
      expect(semNome.displayName(en), 'No category');
    });

    test('a categoria sintética "Outros" é traduzida, não guardada', () {
      expect(outros.displayName(pt), pt.categoryOthers);
      expect(outros.displayName(en), en.categoryOthers);
      expect(outros.displayName(pt), isNot(outros.displayName(en)));
    });

    test('nome de verdade passa intocado, e só espaço conta como vazio', () {
      expect(displayOr('Mercado', pt.noCategory), 'Mercado');
      expect(displayOr('   ', pt.noCategory), pt.noCategory);
      expect(displayOr(null, pt.noDescription), pt.noDescription);
    });
  });
}
