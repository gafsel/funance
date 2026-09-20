import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/time/clock.dart';
import 'package:funances/features/arena/domain/services/arena_calculator.dart';
import 'package:funances/features/arena/presentation/providers/arena_providers.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/repositories/account_repository.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/workspace/presentation/providers.dart';

import '../support/journey_fakes.dart';

/// De onde sai o HP MÁXIMO dos heróis.
///
/// O saldo do começo da semana não é um campo: é o último documento de
/// `accounts/{id}/balance/{YYYY-MM-DD}` com data ANTERIOR ao domingo. Três
/// coisas podem dar errado nessa leitura, e todas as três já deram em algum
/// app:
///
/// 1. pedir o saldo DO domingo em vez do saldo ATÉ o domingo — o repositório
///    compara com `<=`, e o documento do próprio domingo já traz os
///    lançamentos do dia. A barra nasceria com a semana meio andada;
/// 2. uma conta sem documento nenhum antes do domingo (porque foi criada no
///    meio da semana) devolver o saldo de HOJE como se fosse o de partida —
///    a conta nova nasceria com a barra cheia e o dinheiro dela sumiria da
///    leitura de "o que entrou na semana";
/// 3. somar em `double`.
///
/// Este teste segura as três com um repositório de mentira cujos saldos são
/// escritos DIA A DIA, como no Firestore.

final DateTime _wednesday = DateTime(2026, 9, 23, 10);
const String _saturdayBefore = '2026-09-19';
const String _sunday = '2026-09-20';

AccountModel _checking(String id, String name) => AccountModel.checking(
  id: id,
  name: name,
  icon: 'wallet',
  color: '#1565C0',
  initialBalanceDate: DateTime(2026, 1, 1),
);

class _BalanceFake implements IAccountRepository {
  _BalanceFake(this.accounts, this.balances);

  final List<AccountModel> accounts;

  /// `accountId` → (`YYYY-MM-DD` → saldo). O mesmo formato de id de documento
  /// que o app grava.
  final Map<String, Map<String, double>> balances;

  /// As datas que o provider pediu, para provar QUAL dia ele consultou.
  final List<String> asked = <String>[];

  /// Quantas vezes o caminho SEM filtro de data foi usado.
  int latestCalls = 0;

  @override
  Stream<List<AccountModel>> getAccounts(
    String workspaceId, {
    AccountType? type,
  }) => Stream.value(
    type == null ? accounts : accounts.where((a) => a.type == type).toList(),
  );

  /// O "último documento", sem filtro de data. O serviço NÃO deve chamar
  /// isto para responder "saldo atual" — é justamente o caminho que devolvia
  /// o saldo projetado de sexta-feira.
  @override
  Stream<AccountBalanceModel?> getLatestAccountBalance(
    String workspaceId,
    String accountId,
  ) {
    latestCalls++;

    final days = (balances[accountId] ?? const <String, double>{}).keys.toList()
      ..sort();
    if (days.isEmpty) return Stream.value(null);

    return Stream.value(
      AccountBalanceModel(
        id: days.last,
        balance: balances[accountId]![days.last]!,
        updatedAt: _wednesday,
      ),
    );
  }

  @override
  Stream<AccountBalanceModel?> getLatestAccountBalanceBeforeDate(
    String workspaceId,
    String accountId,
    DateTime date,
  ) {
    final key = date.toIso8601String().split('T')[0];
    asked.add(key);

    // A MESMA comparação do repositório de verdade: `<=` sobre o id do
    // documento, que é uma data ISO e por isso ordena como texto.
    final days =
        (balances[accountId] ?? const <String, double>{}).keys
            .where((day) => day.compareTo(key) <= 0)
            .toList()
          ..sort();

    if (days.isEmpty) return Stream.value(null);

    return Stream.value(
      AccountBalanceModel(
        id: days.last,
        balance: balances[accountId]![days.last]!,
        updatedAt: _wednesday,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} não usado na Arena');
}

ProviderContainer _container(_BalanceFake fake) {
  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(() => _wednesday),
      WorkspaceViewProviders.currentWorkspaceId.overrideWithValue('ws-1'),
      AccountDomainProviders.repository.overrideWithValue(fake),
      // `AccountService` também lê o repositório de workspace (ele resolve os
      // donos da conta), e o de verdade abre o Firestore no construtor.
      WorkspaceDomainProviders.repository.overrideWithValue(
        FakeWorkspaceRepository(),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Espera o provider sair de `loading`.
Future<List<ArenaAccountReading>> _lives(ProviderContainer container) =>
    _livesFor(container, DateTime(2026, 9, 20));

Future<List<ArenaAccountReading>> _livesFor(
  ProviderContainer container,
  DateTime weekStart,
) async {
  final args = (weekStart: weekStart, running: true);

  final sub = container.listen(
    ArenaViewProviders.accountLives(args),
    (_, _) {},
    fireImmediately: true,
  );
  addTearDown(sub.close);

  for (var i = 0; i < 30; i++) {
    final value = container
        .read(ArenaViewProviders.accountLives(args))
        .valueOrNull;
    if (value != null) return value;
    await Future<void>.delayed(Duration.zero);
  }

  fail('os saldos não chegaram');
}

void main() {
  // `todayProvider` observa o ciclo de vida do app pelo `WidgetsBinding`.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('o saldo de partida é o do SÁBADO, não o do domingo', () async {
    final fake = _BalanceFake(
      [_checking('c1', 'Nubank')],
      {
        'c1': {
          _saturdayBefore: 5200,
          // O domingo já tem o aluguel do dia. Se a consulta pedisse o
          // domingo, a barra nasceria em 4000 e a semana pareceria ter
          // começado com o herói já ferido.
          _sunday: 4000,
          '2026-09-23': 3980,
        },
      },
    );

    final lives = await _lives(_container(fake));

    expect(fake.asked, contains(_saturdayBefore));
    expect(lives.single.initial, 5200);
    expect(lives.single.current, 3980);
  });

  test('o saldo ATUAL ignora documento com data no futuro', () async {
    // O servidor grava o saldo PROJETADO do dia de um agendamento. Um
    // pagamento marcado para sexta cria `2026-09-25`, que ordena depois do
    // documento de hoje: "o último" devolvia um dinheiro que ainda não saiu.
    //
    // Na Arena isso aparecia como o herói já ferido no domingo; na tela de
    // contas, como um saldo que o extrato não explica.
    final fake = _BalanceFake(
      [_checking('c1', 'Nubank')],
      {
        'c1': {
          _saturdayBefore: 5200,
          '2026-09-23': 3980,
          // Sexta-feira: o aluguel agendado.
          '2026-09-25': 2780,
        },
      },
    );

    final lives = await _lives(_container(fake));

    expect(lives.single.current, 3980);
    expect(
      fake.latestCalls,
      0,
      reason:
          'o "saldo atual" passa pela consulta COM teto de data; o caminho '
          'sem filtro é o que devolvia o futuro',
    );
    expect(fake.asked, contains('2026-09-23'));
  });

  test('a virada do dia reabre a consulta com o teto novo', () async {
    // O celular que passa a noite na mesa de cabeceira. Com o teto de data
    // preso no momento em que a consulta foi montada, o app acordava
    // respondendo com o saldo de ONTEM, e o lançamento de hoje não aparecia
    // até alguém fechar e reabrir.
    var agora = DateTime(2026, 9, 23, 22);

    final fake = _BalanceFake(
      [_checking('c1', 'Nubank')],
      {
        'c1': {_saturdayBefore: 5200, '2026-09-23': 3980, '2026-09-24': 3100},
      },
    );

    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => agora),
        WorkspaceViewProviders.currentWorkspaceId.overrideWithValue('ws-1'),
        AccountDomainProviders.repository.overrideWithValue(fake),
        WorkspaceDomainProviders.repository.overrideWithValue(
          FakeWorkspaceRepository(),
        ),
      ],
    );

    expect((await _lives(container)).single.current, 3980);

    // Meia-noite: o `todayProvider` vira, e quem o observa é refeito.
    agora = DateTime(2026, 9, 24, 0, 1);
    container.read(todayProvider.notifier).refresh();

    final depois = await _livesFor(container, DateTime(2026, 9, 20));
    expect(
      depois.single.current,
      3100,
      reason: 'o teto de data acompanhou a virada',
    );

    container.dispose();
  });

  test('sem documento no sábado, vale o último ANTES dele', () async {
    // O servidor só grava saldo em dia com movimento. Numa conta parada desde
    // agosto não existe documento do sábado, e exigir um faria a barra nascer
    // em zero com dinheiro na conta.
    final fake = _BalanceFake(
      [_checking('parada', 'Poupança')],
      {
        'parada': {'2026-08-11': 1500},
      },
    );

    final lives = await _lives(_container(fake));

    expect(lives.single.initial, 1500);
    expect(lives.single.current, 1500);
  });

  test('conta sem documento antes do domingo começa em zero', () async {
    final fake = _BalanceFake(
      [_checking('nova', 'Conta nova')],
      {
        // Aberta na terça: não havia nada antes do domingo.
        'nova': {'2026-09-22': 700},
      },
    );

    final lives = await _lives(_container(fake));

    expect(lives.single.initial, 0);
    expect(lives.single.current, 700);
  });

  test('conta sem saldo nenhum não quebra a soma', () async {
    final fake = _BalanceFake([_checking('vazia', 'Sem movimento')], {});

    final lives = await _lives(_container(fake));

    expect(lives.single.initial, 0);
    expect(lives.single.current, 0);
  });

  test(
    'só a corrente é vida; investimento, cartão e dívida ficam de fora',
    () async {
      final fake = _BalanceFake(
        [
          _checking('c1', 'Nubank'),
          AccountModel.investment(
            id: 'inv',
            name: 'Tesouro',
            icon: 'savings',
            color: '#2E7D32',
            initialBalanceDate: DateTime(2026, 1, 1),
            interestRate: 0,
          ),
          AccountModel.creditCard(
            id: 'card',
            name: 'Cartão',
            icon: 'credit_card',
            color: '#6A1B9A',
            initialBalanceDate: DateTime(2026, 1, 1),
            limit: 5000,
            dueDay: 10,
            closingDay: 3,
          ),
          AccountModel.debt(
            id: 'debt',
            name: 'Financiamento',
            icon: 'home',
            color: '#B71C1C',
            initialBalanceDate: DateTime(2026, 1, 1),
            interestRate: 0.01,
          ),
        ],
        {
          'c1': {_saturdayBefore: 4200, '2026-09-23': 3100},
          'inv': {_saturdayBefore: 1000, '2026-09-23': 880},
          'card': {_saturdayBefore: -3000, '2026-09-23': -3400},
          'debt': {_saturdayBefore: -50000, '2026-09-23': -49000},
        },
      );

      final lives = await _lives(_container(fake));

      // O investimento saiu com o HUD mensal: ele é a poção, não a vida.
      expect(lives.map((l) => l.accountId).toList(), ['c1']);

      final state = ArenaCalculator.from(
        ArenaInputs(
          weekId: '2026-W38',
          today: _wednesday,
          accounts: lives,
          weekInstallments: const [],
          overdueInstallments: const [],
          members: const [],
        ),
      );

      expect(state.initialBalance, 4200);
      expect(state.currentBalance, 3100);
    },
  );
}
