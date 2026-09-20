import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/arena/domain/models/arena_state.dart';
import 'package:funances/features/arena/domain/services/arena_calculator.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/user/domain/models/user_model.dart';

/// A conta da Arena é a única parte da POC que precisa estar CERTA.
///
/// O resto — pose, tremor, partícula — se confere olhando a tela. Um HP que
/// diverge da soma dos compromissos, não: ele parece plausível e mente.
///
/// A mecânica que estes testes guardam:
///
/// - o monstro é feito **só** de compromisso agendado (mais o atraso). Não há
///   mais rateio de orçamento no HP dele — era a dupla contagem que fazia o
///   mesmo dinheiro aparecer no monstro e no comprometido do herói;
/// - os heróis têm o SALDO como vida, medido do domingo até agora. HP máximo
///   é o saldo do começo da semana; HP atual é o de agora;
/// - pagar um compromisso tira vida dos DOIS: do monstro porque a dívida
///   some, dos heróis porque o dinheiro sai. É o custo do golpe.

const String _week = '2026-W38';

/// Domingo da semana 38 de 2026, ao meio-dia (a hora que o app usa para
/// vencimento).
final DateTime _sunday = DateTime(2026, 9, 20, 12);

/// Quarta-feira: o "hoje" padrão dos testes — quarto dia da semana.
final DateTime _wednesday = DateTime(2026, 9, 23, 10);

InstallmentModel _expense({
  required String id,
  required double amount,
  int dayOffset = 0,
  InstallmentStatus status = InstallmentStatus.pending,
  double? paidAmount,
  DateTime? paidDate,
}) => InstallmentModel(
  id: id,
  orderId: 'order-$id',
  amount: amount,
  description: id,
  dueDate: _sunday.add(Duration(days: dayOffset)),
  paidAmount: paidAmount,
  paidDate: paidDate,
  status: status,
  type: OrderType.expense,
  installmentType: InstallmentType.single,
);

InstallmentModel _income({
  required String id,
  required double amount,
  InstallmentStatus status = InstallmentStatus.paid,
}) => InstallmentModel(
  id: id,
  orderId: 'order-$id',
  amount: amount,
  description: id,
  dueDate: _sunday.add(const Duration(days: 1)),
  paidDate: _sunday.add(const Duration(days: 1)),
  status: status,
  type: OrderType.income,
  installmentType: InstallmentType.single,
);

ArenaAccountReading _account(
  String id, {
  String? name,
  double initial = 0,
  double current = 0,
}) => ArenaAccountReading(
  accountId: id,
  name: name ?? id,
  initial: initial,
  current: current,
);

UserModel _member(String id, {String? name, String email = ''}) => UserModel(
  id: id,
  email: email.isEmpty ? '$id@funances.test' : email,
  displayName: name,
  createdAt: _sunday,
);

ArenaInputs _inputs({
  List<ArenaAccountReading> accounts = const [],
  List<InstallmentModel> week = const [],
  List<InstallmentModel> overdue = const [],
  List<UserModel> members = const [],
  DateTime? today,
  double weeklyXp = 0,
}) => ArenaInputs(
  weekId: _week,
  today: today ?? _wednesday,
  accounts: accounts,
  weekInstallments: week,
  overdueInstallments: overdue,
  members: members,
  weeklyXp: weeklyXp,
);

void main() {
  group('HP do monstro: só compromisso agendado', () {
    test('nasce da soma das parcelas de despesa da semana', () {
      final state = ArenaCalculator.from(
        _inputs(
          week: [
            _expense(id: 'aluguel', amount: 1200),
            _expense(id: 'luz', amount: 180, dayOffset: 3),
          ],
        ),
      );

      expect(state.monsterMaxHp, 1380);
      expect(state.monsterHp, 1380);
      expect(state.monsterHpRatio, 1);
    });

    test('orçamento de categoria NÃO entra: o monstro só conhece dívida', () {
      // A POC 1 somava o rateio de `period_summaries` ao HP. O mesmo gasto
      // aparecia no monstro e na faixa de comprometido do herói, e a barra
      // andava duas vezes pelo mesmo real. A calculadora nova nem recebe o
      // resumo — não há como a dupla contagem voltar por descuido.
      final state = ArenaCalculator.from(
        _inputs(week: [_expense(id: 'aluguel', amount: 1200)]),
      );

      expect(state.monsterMaxHp, 1200);
    });

    test('pagar um compromisso tira exatamente o valor dele', () {
      final state = ArenaCalculator.from(
        _inputs(
          week: [
            _expense(
              id: 'aluguel',
              amount: 1200,
              status: InstallmentStatus.paid,
              paidDate: _sunday.add(const Duration(days: 1)),
            ),
            _expense(id: 'luz', amount: 180, dayOffset: 3),
          ],
        ),
      );

      expect(state.monsterMaxHp, 1380, reason: 'o pago continua no inicial');
      expect(state.monsterHp, 180);
      expect(state.paidSoFar, 1200);
    });

    test('o valor PAGO manda quando difere do previsto', () {
      final state = ArenaCalculator.from(
        _inputs(
          week: [
            _expense(
              id: 'luz',
              amount: 180,
              paidAmount: 183.45,
              status: InstallmentStatus.paid,
              paidDate: _sunday.add(const Duration(days: 1)),
            ),
          ],
        ),
      );

      expect(state.monsterMaxHp, 183.45);
      expect(state.monsterHp, 0);
      expect(state.isDefeated, isTrue);
    });

    test('pagar mais do que o previsto não leva a barra abaixo de zero', () {
      final state = ArenaCalculator.from(
        _inputs(
          week: [
            _expense(
              id: 'luz',
              amount: 180,
              paidAmount: 300,
              status: InstallmentStatus.settled,
              paidDate: _sunday.add(const Duration(days: 1)),
            ),
          ],
        ),
      );

      expect(state.monsterHp, 0);
      expect(state.monsterHpRatio, 0);
    });

    test('receita não alimenta o monstro', () {
      final state = ArenaCalculator.from(
        _inputs(
          week: [
            _income(id: 'salario', amount: 6000),
            _expense(id: 'luz', amount: 180),
          ],
        ),
      );

      expect(state.monsterMaxHp, 180);
    });

    test('transferência não é compromisso', () {
      final transfer = InstallmentModel(
        id: 'transf',
        orderId: 'order-transf',
        amount: 900,
        description: 'transf',
        dueDate: _sunday,
        status: InstallmentStatus.paid,
        paidDate: _sunday,
        type: OrderType.transfer,
        installmentType: InstallmentType.single,
      );

      final state = ArenaCalculator.from(_inputs(week: [transfer]));

      expect(state.monsterMaxHp, 0);
      expect(state.healedThisWeek, 0);
    });

    test('a soma é em centavos: doze parcelas de 0,10 dão 1,20 exato', () {
      final state = ArenaCalculator.from(
        _inputs(
          week: [
            for (var i = 0; i < 12; i++) _expense(id: 'p$i', amount: 0.10),
          ],
        ),
      );

      expect(state.monsterMaxHp, 1.20);
    });

    test('semana sem compromisso nenhum não conta como vitória', () {
      final state = ArenaCalculator.from(
        _inputs(accounts: [_account('c', initial: 900, current: 900)]),
      );

      expect(state.monsterMaxHp, 0);
      expect(state.isDefeated, isFalse);
    });
  });

  group('atraso', () {
    test('soma ao HP inicial, enfurece o monstro e vira cicatriz', () {
      final state = ArenaCalculator.from(
        _inputs(
          week: [_expense(id: 'luz', amount: 180, dayOffset: 3)],
          overdue: [_expense(id: 'cartao', amount: 640, dayOffset: -9)],
        ),
      );

      expect(state.overdueAmount, 640);
      expect(state.monsterMaxHp, 820);
      expect(state.monsterHp, 820);
      expect(state.isEnraged, isTrue);
      expect(state.monsterSkin, MonsterSkin.demon);
    });

    test('parcela atrasada JÁ PAGA não conta', () {
      final state = ArenaCalculator.from(
        _inputs(
          overdue: [
            _expense(
              id: 'cartao',
              amount: 640,
              dayOffset: -9,
              status: InstallmentStatus.paid,
            ),
          ],
        ),
      );

      expect(state.overdueAmount, 0);
      expect(state.isEnraged, isFalse);
    });

    test('o atrasado é marcado como tal na lista', () {
      final state = ArenaCalculator.from(
        _inputs(
          week: [_expense(id: 'luz', amount: 180, dayOffset: 3)],
          overdue: [_expense(id: 'cartao', amount: 640, dayOffset: -9)],
        ),
      );

      final atrasado = state.commitments.firstWhere((c) => c.isOverdue);
      expect(atrasado.installment.id, 'cartao');
      expect(atrasado.isPaid, isFalse);
      expect(atrasado.daysUntilDue, lessThan(0));
    });
  });

  group('ordem da folha do monstro', () {
    test(
      'atrasados, hoje, amanhã, resto da semana — e os pagos por último',
      () {
        final state = ArenaCalculator.from(
          _inputs(
            week: [
              // quarta é o dia 3 (offset 3); sábado é 6.
              _expense(id: 'sabado', amount: 50, dayOffset: 6),
              _expense(id: 'quinta', amount: 40, dayOffset: 4),
              _expense(id: 'hoje', amount: 30, dayOffset: 3),
              _expense(
                id: 'pago',
                amount: 20,
                dayOffset: 1,
                status: InstallmentStatus.paid,
                paidDate: _sunday.add(const Duration(days: 1)),
              ),
            ],
            overdue: [_expense(id: 'atrasado', amount: 10, dayOffset: -4)],
          ),
        );

        expect(state.commitments.map((c) => c.installment.id).toList(), [
          'atrasado',
          'hoje',
          'quinta',
          'sabado',
          'pago',
        ]);
      },
    );

    test('"hoje" e "amanhã" são o próximo golpe; o resto da semana não é', () {
      final state = ArenaCalculator.from(
        _inputs(
          week: [
            _expense(id: 'hoje', amount: 30, dayOffset: 3),
            _expense(id: 'amanha', amount: 40, dayOffset: 4),
            _expense(id: 'sabado', amount: 50, dayOffset: 6),
          ],
        ),
      );

      expect(state.nextBlow.map((c) => c.installment.id).toList(), [
        'hoje',
        'amanha',
      ]);
      expect(state.commitments.first.isDueToday, isTrue);
      expect(state.commitments[1].isDueTomorrow, isTrue);
    });

    test('o que já venceu e não foi pago não é "próximo golpe": é atraso', () {
      final state = ArenaCalculator.from(
        _inputs(overdue: [_expense(id: 'atrasado', amount: 10, dayOffset: -4)]),
      );

      expect(state.nextBlow, isEmpty);
      expect(state.pendingCommitments.single.isOverdue, isTrue);
    });

    test('pendentes e pagos são separáveis pela folha', () {
      final state = ArenaCalculator.from(
        _inputs(
          week: [
            _expense(id: 'a', amount: 10, dayOffset: 4),
            _expense(
              id: 'b',
              amount: 20,
              status: InstallmentStatus.paid,
              paidDate: _sunday,
            ),
          ],
        ),
      );

      expect(state.pendingCommitments.map((c) => c.installment.id), ['a']);
      expect(state.paidCommitments.map((c) => c.installment.id), ['b']);
    });
  });

  group('HP dos heróis: o saldo é a vida', () {
    test('máximo é o saldo de domingo; atual é o de agora', () {
      final state = ArenaCalculator.from(
        _inputs(
          accounts: [
            _account('corrente', initial: 4200, current: 3100),
            _account('investimento', initial: 1000, current: 880),
          ],
        ),
      );

      expect(state.initialBalance, 5200);
      expect(state.currentBalance, 3980);
      expect(state.heroHpRatio, closeTo(3980 / 5200, 0.0001));
      expect(state.isOverhealed, isFalse);
    });

    test('a soma das contas é em centavos', () {
      final state = ArenaCalculator.from(
        _inputs(
          accounts: [
            for (var i = 0; i < 3; i++)
              _account('c$i', initial: 0.1, current: 0.1),
          ],
        ),
      );

      expect(state.initialBalance, 0.30);
      expect(state.currentBalance, 0.30);
    });

    test('conta SEM documento antes do domingo entra com zero no inicial', () {
      // É o caso da conta criada no meio da semana: ela não existia no começo
      // da luta, e inventar um saldo de partida para ela faria a barra nascer
      // cheia com dinheiro que não estava lá.
      final state = ArenaCalculator.from(
        _inputs(
          accounts: [
            _account('antiga', initial: 3000, current: 2500),
            _account('nova', initial: 0, current: 700),
          ],
        ),
      );

      expect(state.initialBalance, 3000);
      expect(state.currentBalance, 3200);
      expect(state.isOverhealed, isTrue, reason: 'entrou mais do que saiu');
      expect(state.overheal, 200);
      expect(state.heroHpRatio, 1, reason: 'a barra cheia para no topo');
    });

    test('o comprometido é o MESMO número do monstro', () {
      final state = ArenaCalculator.from(
        _inputs(
          accounts: [_account('corrente', initial: 5000, current: 4000)],
          week: [_expense(id: 'aluguel', amount: 1200)],
        ),
      );

      expect(state.committed, state.monsterHp);
      expect(state.committed, 1200);
      expect(state.freeBalance, 2800);
      expect(state.committedRatio, closeTo(1200 / 5000, 0.0001));
    });

    test('comprometido acima do saldo de domingo: a hachura para em 1', () {
      final state = ArenaCalculator.from(
        _inputs(
          accounts: [_account('corrente', initial: 400, current: 300)],
          week: [_expense(id: 'aluguel', amount: 1200)],
        ),
      );

      expect(state.committedRatio, 1);
      expect(state.freeBalance, -900);
    });

    test('saldo negativo: exausto', () {
      final state = ArenaCalculator.from(
        _inputs(accounts: [_account('corrente', initial: 500, current: -120)]),
      );

      expect(state.heroMood, HeroMood.exhausted);
      expect(state.heroHpRatio, 0);
    });

    test('abaixo de um terço do saldo de domingo: machucado', () {
      final state = ArenaCalculator.from(
        _inputs(accounts: [_account('corrente', initial: 3000, current: 800)]),
      );

      expect(state.heroMood, HeroMood.hurt);
    });

    test('sem saldo de partida, qualquer caixa positivo é barra cheia', () {
      final state = ArenaCalculator.from(
        _inputs(accounts: [_account('nova', initial: 0, current: 700)]),
      );

      expect(state.heroHpRatio, 1);
      expect(state.heroMood, HeroMood.healthy);
    });

    test('cada conta guarda início, atual e a diferença', () {
      final state = ArenaCalculator.from(
        _inputs(
          accounts: [
            _account('c1', name: 'Nubank', initial: 4200, current: 3100),
            _account('c2', name: 'Tesouro', initial: 1000, current: 1000),
          ],
        ),
      );

      expect(state.accounts.first.name, 'Nubank');
      expect(state.accounts.first.delta, -1100);
      expect(state.accounts.last.delta, 0);
    });
  });

  group('cura', () {
    test('receita RECEBIDA na semana cura; a agendada não', () {
      final state = ArenaCalculator.from(
        _inputs(
          accounts: [_account('corrente', initial: 1000, current: 7000)],
          week: [
            _income(id: 'salario', amount: 6000),
            _income(
              id: 'freela',
              amount: 900,
              status: InstallmentStatus.pending,
            ),
          ],
        ),
      );

      expect(state.healedThisWeek, 6000);
    });
  });

  group('elenco', () {
    test('dois heróis com skins distintas e o resto vira contador', () {
      final state = ArenaCalculator.from(
        _inputs(
          members: [
            _member('u1', name: 'Gabriel Silva'),
            _member('u2', name: 'Ana Paula'),
            _member('u3', name: 'João'),
          ],
        ),
      );

      expect(state.heroes.map((h) => h.name).toList(), ['Gabriel', 'Ana']);
      expect(state.heroes.first.skin, isNot(state.heroes.last.skin));
      expect(state.extraMembers, 1);
    });

    test('sem nome, o herói usa o começo do e-mail', () {
      final state = ArenaCalculator.from(
        _inputs(members: [_member('u1', email: 'gafsel@funances.test')]),
      );

      expect(state.heroes.single.name, 'gafsel');
    });
  });

  group('o marcador do dia', () {
    test('domingo é o dia 1 de 7; quarta é o 4', () {
      expect(
        ArenaCalculator.from(_inputs(today: _sunday)).day,
        ArenaDay.sunday,
      );
      expect(ArenaCalculator.from(_inputs(today: _wednesday)).day.ordinal, 4);
      expect(ArenaCalculator.from(_inputs(today: _wednesday)).day.daysLeft, 4);
    });

    test('sábado é o último dia', () {
      final saturday = _sunday.add(const Duration(days: 6));
      final state = ArenaCalculator.from(_inputs(today: saturday));

      expect(state.day, ArenaDay.saturday);
      expect(state.day.daysLeft, 1);
    });
  });

  group('monstro da semana', () {
    test('a skin é estável para o mesmo id de semana', () {
      expect(
        ArenaCalculator.skinForWeek('2026-W12'),
        ArenaCalculator.skinForWeek('2026-W12'),
      );
    });

    test('semanas vizinhas não repetem o bicho', () {
      expect(
        ArenaCalculator.skinForWeek('2026-W12'),
        isNot(ArenaCalculator.skinForWeek('2026-W13')),
      );
    });
  });

  group('cena vazia', () {
    test(
      'sem compromisso e sem caixa, a Arena sabe que não tem o que mostrar',
      () {
        expect(ArenaCalculator.from(_inputs()).isEmpty, isTrue);
      },
    );

    test('caixa sozinho já é motivo para desenhar a cena', () {
      final state = ArenaCalculator.from(
        _inputs(accounts: [_account('c', initial: 100, current: 100)]),
      );

      expect(state.isEmpty, isFalse);
    });
  });
}
