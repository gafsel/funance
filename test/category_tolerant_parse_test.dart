import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/finance/data/models/automatic_transaction_mapper.dart';
import 'package:funances/features/finance/domain/models/automatic_transaction_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

/// Bug pré-existente — uma pendência malformada derrubava TODAS as outras.
///
/// `AutomaticTransactionRepositoryImpl.getPendingTransactions` mapeava a
/// coleção inteira de uma vez, então UM documento ilegível apagava a lista
/// toda: quem tinha uma notificação malformada não conseguia consolidar
/// nenhuma.
///
/// Os dois produtores REAIS do documento estão abaixo. O leitor de
/// notificação OMITE a categoria quando não classifica; a sugestão da IA vem
/// sempre completa, com `name`, `icon` e `color`. A categoria pela metade não
/// é nenhum dos dois — e é justamente por isso que ela derruba: uma forma que
/// ninguém promete é a que não tem quem a corrija. Este arquivo prende os
/// dois caminhos honestos e o terceiro, o que não deveria existir.

/// O documento do LEITOR DE NOTIFICAÇÃO: sem categoria nenhuma.
Map<String, dynamic> _pendenteDoLeitor() => {
  'id': 'auto-1c40',
  'description': 'COMPRA CARTAO 4412',
  'amount': 89.9,
  'date': '2026-03-15T12:00:00.000Z',
  'type': 'expense',
  'originNotificationId': 'n-771',
  'packageName': 'com.nubank.app',
  'isConsolidated': false,
  'isIgnored': false,
};

/// O documento com SUGESTÃO DA IA: categoria completa.
Map<String, dynamic> _pendenteDaIa() => {
  'id': 'auto-8f2c',
  'description': 'MERCADO CENTRAL',
  'amount': 132.4,
  'date': '2026-03-15T12:00:00.000Z',
  'type': 'expense',
  'originNotificationId': 'n-772',
  'packageName': 'com.nubank.app',
  'isConsolidated': false,
  'isIgnored': false,
  'suggestedCategory': {
    'id': 'mercado',
    'name': 'Mercado',
    'icon': 'shopping_cart',
    'color': '#2E7D32',
    'type': 'expense',
  },
};

/// A forma que NENHUM dos dois produtores promete: categoria pela metade.
Map<String, dynamic> _pendenteComCategoriaIncompleta() => {
  ..._pendenteDaIa(),
  'id': 'auto-8f2c',
  'suggestedCategory': {
    'icon': 'shopping_cart',
    'color': '#FF5722',
    'type': 'expense',
  },
};

/// Uma conta sugerida QUEBRADA: sem `initialBalanceDate`, que a união exige.
/// É a mesma exposição da categoria, num campo que ninguém tinha olhado.
Map<String, dynamic> _pendenteComContaQuebrada() => {
  'id': 'auto-9a1b',
  'description': 'PIX ENVIADO',
  'amount': 250.0,
  'date': '2026-03-15T12:00:00.000Z',
  'type': 'expense',
  'isConsolidated': false,
  'isIgnored': false,
  'suggestedAccount': {
    'runtimeType': 'checking',
    'id': 'acc-1',
    'name': 'Conta',
    'icon': 'account_balance',
    'color': '#1565C0',
  },
};

Map<String, dynamic> _pendenteIntegro() =>
    {..._pendenteDoLeitor(), 'id': 'auto-ok'};

void main() {
  group('os documentos REAIS', () {
    test('o do leitor não traz categoria nenhuma, e isso é normal', () {
      final transacao = AutomaticTransactionModel.fromJson(
        _pendenteDoLeitor(),
      );

      expect(transacao.suggestedCategory, isNull);
      expect(transacao.description, 'COMPRA CARTAO 4412');
    });

    test('o da IA traz a categoria inteira', () {
      final categoria = AutomaticTransactionModel.fromJson(
        _pendenteDaIa(),
      ).suggestedCategory!;

      expect(categoria.id, 'mercado');
      expect(categoria.name, 'Mercado');
      expect(categoria.icon, 'shopping_cart');
      expect(categoria.color, '#2E7D32');
    });
  });

  group('CategoryModel.fromJson tolerante', () {
    test('categoria sem name e sem id não derruba o parse', () {
      final transacao = AutomaticTransactionModel.fromJson(
        _pendenteComCategoriaIncompleta(),
      );

      expect(transacao.id, 'auto-8f2c');
      expect(transacao.amount, 132.4);

      final categoria = transacao.suggestedCategory!;
      expect(categoria.id, '');
      expect(categoria.name, '');
      expect(
        categoria.icon,
        'shopping_cart',
        reason: 'o que veio no documento continua valendo',
      );
      expect(categoria.color, '#FF5722');
    });

    test('nenhum dos quatro campos de texto derruba o parse', () {
      final categoria = CategoryModel.fromJson(const {
        'type': 'income',
        'allocation': 'essential',
      });

      expect(categoria.id, '');
      expect(categoria.name, '');
      expect(categoria.icon, '');
      expect(categoria.color, '');
      expect(
        categoria.type,
        CategoryType.income,
        reason: 'o que o documento trouxe não pode ser perdido no conserto',
      );
      expect(categoria.allocation, CategoryAllocation.essential);
    });

    test('campo de texto com o TIPO errado também cai no default', () {
      final categoria = CategoryModel.fromJson(const {
        'id': 42,
        'name': 'Mercado',
        'icon': 'shopping_cart',
        'color': '#FF5722',
      });

      expect(categoria.id, '');
      expect(categoria.name, 'Mercado');
    });

    test('o documento íntegro passa exatamente igual', () {
      final json = const {
        'id': 'mercado',
        'name': 'Mercado',
        'icon': 'shopping_cart',
        'color': '#2E7D32',
        'type': 'expense',
        'allocation': 'essential',
        'isSystem': false,
        'isDeleted': false,
      };

      expect(CategoryModel.fromJson(json).toJson(), json);
    });

    test('toJson NÃO muda: o app grava o que tem', () {
      final categoria = CategoryModel.fromJson(const {
        'icon': 'shopping_cart',
        'color': '#FF5722',
      });

      expect(categoria.toJson(), {
        'id': '',
        'name': '',
        'icon': 'shopping_cart',
        'color': '#FF5722',
        'type': 'expense',
        'allocation': 'comfort',
        'isSystem': false,
        'isDeleted': false,
      });
    });

    test('o mapa de entrada não é modificado', () {
      final json = <String, dynamic>{'icon': 'x', 'color': '#000000'};

      CategoryModel.fromJson(json);

      expect(
        json,
        {'icon': 'x', 'color': '#000000'},
        reason:
            'o mapa vem do snapshot do Firestore; consertá-lo no lugar '
            'mudaria o que outra leitura enxerga',
      );
    });
  });

  /// Item 4 — a fronteira é a LEITURA da coleção, não cada modelo.
  ///
  /// A rodada anterior tolerou a categoria sem nome e parou aí. O mesmo
  /// documento carrega `suggestedAccount` (uma união com `runtimeType`,
  /// datas obrigatórias e campos por tipo de conta), e o leitor de
  /// notificação é um processo fora do controle do app: a lista continuava
  /// caindo inteira por causa de um documento.
  group('parsePendingTransactions', () {
    test('um documento ilegível não derruba os outros', () {
      final ignorados = <String>[];

      final itens = parsePendingTransactions(
        [
          (id: 'auto-1', data: _pendenteComCategoriaIncompleta()),
          (id: 'auto-quebrado', data: _pendenteComContaQuebrada()),
          (id: 'auto-3', data: _pendenteIntegro()),
        ],
        onInvalid: (id, error, stack) => ignorados.add(id),
      );

      expect(itens.map((t) => t.id), ['auto-8f2c', 'auto-ok']);
      expect(
        ignorados,
        ['auto-quebrado'],
        reason:
            'o id entra no registro para que dê para achar o documento; o '
            'conteúdo dele, não',
      );
    });

    test('documento sem dados também é pulado, não explodido', () {
      final ignorados = <String>[];

      final itens = parsePendingTransactions(
        [
          (id: 'vazio', data: null),
          (id: 'auto-3', data: _pendenteIntegro()),
        ],
        onInvalid: (id, error, stack) => ignorados.add(id),
      );

      expect(itens, hasLength(1));
      expect(ignorados, ['vazio']);
    });

    test('coleção inteira íntegra não registra nada', () {
      final ignorados = <String>[];

      final itens = parsePendingTransactions(
        [
          (id: 'a', data: _pendenteIntegro()),
          (id: 'b', data: _pendenteIntegro()),
        ],
        onInvalid: (id, error, stack) => ignorados.add(id),
      );

      expect(itens, hasLength(2));
      expect(ignorados, isEmpty);
    });
  });
}
