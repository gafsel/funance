import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/arena/domain/models/arena_state.dart';
import 'package:funances/features/arena/domain/services/arena_calculator.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/models/period_summary_model.dart';
import 'package:funances/features/user/domain/models/user_model.dart';

/// A conta da Arena é a única parte da POC que precisa estar CERTA.
///
/// O resto — pose, tremor, partícula — se confere olhando a tela. Um HP que
/// diverge da soma das parcelas, não: ele parece plausível e mente.

const String _week = '2026-W38';
final DateTime _sunday = DateTime(2026, 9, 20);

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

PeriodSummaryModel _summary(
  Map<String, (double planned, double actual)> categories,
) => PeriodSummaryModel.week(
  year: 2026,
  week: 38,
  lastUpdate: _sunday,
  categories: {
    for (final entry in categories.entries)
      entry.key: PeriodSummaryCategoryModel(
        generalPlannedAmount: entry.value.$1,
        actualAmount: entry.value.$2,
      ),
  },
);

UserModel _member(String id, {String? name, String email = ''}) => UserModel(
  id: id,
  email: email.isEmpty ? '$id@funances.test' : email,
  displayName: name,
  createdAt: _sunday,
);

ArenaInputs _inputs({
  double liquidBalance = 0,
  List<InstallmentModel> week = const [],
  List<InstallmentModel> overdue = const [],
  PeriodSummaryModel? summary,
  List<UserModel> members = const [],
  NextInvoice? invoice,
  double weeklyXp = 0,
}) => ArenaInputs(
  weekId: _week,
  liquidBalance: liquidBalance,
  weekInstallments: week,
  overdueInstallments: overdue,
  weekSummary: summary,
  members: members,
  invoice: invoice,
  weeklyXp: weeklyXp,
);

void main() {
  group('HP do monstro', () {
    test('nasce das parcelas da semana MAIS o rateio do orçamento', () {
      final state = ArenaCalculator.from(
        _inputs(
          week: [
            _expense(id: 'aluguel', amount: 1200),
            _expense(id: 'luz', amount: 180, dayOffset: 3),
          ],
          summary: _summary({
            'mercado': (400, 0),
            'lazer': (150, 0),
          }),
        ),
      );

      expect(state.installmentsInitial, 1380);
      expect(state.budgetInitial, 550);
      expect(state.monsterMaxHp, 1930);
      expect(state.monsterHp, 1930);
      expect(state.monsterHpRatio, 1.0);
    });

    test('pagar uma parcela tira exatamente o valor dela', () {
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

      expect(state.installmentsInitial, 1380);
      expect(state.installmentsRemaining, 180);
      expect(state.monsterHp, 180);
    });

    test('gasto DENTRO do plano também golpeia, e só até o limite', () {
      final state = ArenaCalculator.from(
        _inputs(
          summary: _summary({
            // Gastou 300 de 400: o golpe é de 300.
            'mercado': (400, 300),
            // Gastou 200 de 150: o golpe para em 150; os 50 viram DANO.
            'lazer': (150, 200),
          }),
        ),
      );

      expect(state.budgetInitial, 550);
      expect(state.budgetRemaining, 100, reason: '550 − 300 − 150');
      expect(state.damageThisWeek, 50);
    });

    test('categoria SEM limite: o gasto inteiro é dano, e nada é golpe', () {
      final state = ArenaCalculator.from(
        _inputs(summary: _summary({'impulso': (0, 89.9)})),
      );

      expect(state.budgetInitial, 0);
      expect(state.budgetRemaining, 0);
      expect(state.damageThisWeek, 89.9);
    });

    test('pagar mais do que o previsto não leva a barra abaixo de zero', () {
      final state = ArenaCalculator.from(
        _inputs(
          week: [
            _expense(
              id: 'luz',
              amount: 180,
              status: InstallmentStatus.paid,
              paidAmount: 260,
              paidDate: _sunday,
            ),
          ],
        ),
      );

      expect(state.installmentsRemaining, 0);
      expect(state.monsterHp, 0);
    });

    test('a soma é em centavos: doze parcelas de 0,10 dão 1,20 exato', () {
      final state = ArenaCalculator.from(
        _inputs(
          week: [
            for (var i = 0; i < 12; i++)
              _expense(id: 'p$i', amount: 0.1, dayOffset: i % 7),
          ],
        ),
      );

      expect(state.installmentsInitial, 1.2);
    });
  });

  group('atraso', () {
    test('soma ao HP inicial, enfurece o monstro e vira cicatriz', () {
      final state = ArenaCalculator.from(
        _inputs(
          week: [_expense(id: 'luz', amount: 180)],
          overdue: [
            _expense(id: 'cartao', amount: 640, dayOffset: -10),
            _expense(id: 'agua', amount: 60, dayOffset: -12),
          ],
        ),
      );

      expect(state.overdueAmount, 700);
      expect(state.installmentsInitial, 880);
      expect(state.isEnraged, isTrue);
      expect(state.monsterSkin, MonsterSkin.demon);
    });

    test('parcela atrasada JÁ PAGA não conta', () {
      final state = ArenaCalculator.from(
        _inputs(
          overdue: [
            _expense(
              id: 'agua',
              amount: 60,
              dayOffset: -12,
              status: InstallmentStatus.settled,
            ),
          ],
        ),
      );

      expect(state.overdueAmount, 0);
      expect(state.isEnraged, isFalse);
    });
  });

  group('fuga do monstro', () {
    test('foge quando as parcelas acabam, mesmo com orçamento de pé', () {
      final state = ArenaCalculator.from(
        _inputs(
          week: [
            _expense(
              id: 'luz',
              amount: 180,
              status: InstallmentStatus.paid,
              paidDate: _sunday,
            ),
          ],
          summary: _summary({'mercado': (400, 0)}),
        ),
      );

      expect(state.hasFled, isTrue);
      expect(state.monsterHp, 400, reason: 'o orçamento sobra, mas não segura');
    });

    test('semana sem parcela nenhuma não conta como fuga', () {
      final state = ArenaCalculator.from(
        _inputs(summary: _summary({'mercado': (400, 0)})),
      );

      expect(state.hasFled, isFalse);
    });
  });

  group('HP do herói', () {
    test('é o caixa livre: líquido menos o comprometido', () {
      final state = ArenaCalculator.from(
        _inputs(
          liquidBalance: 5000,
          week: [_expense(id: 'aluguel', amount: 1200)],
          summary: _summary({'mercado': (400, 0)}),
        ),
      );

      expect(state.committed, 1600);
      expect(state.heroHp, 3400);
      expect(state.heroHpRatio, closeTo(0.68, 0.0001));
      expect(state.committedRatio, closeTo(0.32, 0.0001));
      expect(state.heroMood, HeroMood.healthy);
    });

    test('comprometido acima do caixa: exausto, e a barra não passa de 1', () {
      final state = ArenaCalculator.from(
        _inputs(
          liquidBalance: 800,
          week: [_expense(id: 'aluguel', amount: 1200)],
        ),
      );

      expect(state.heroHp, -400);
      expect(state.heroMood, HeroMood.exhausted);
      expect(state.heroHpRatio, 0);
      expect(state.committedRatio, 1);
    });

    test('abaixo de um terço o herói fica machucado, não exausto', () {
      final state = ArenaCalculator.from(
        _inputs(
          liquidBalance: 1000,
          week: [_expense(id: 'aluguel', amount: 800)],
        ),
      );

      expect(state.heroHp, 200);
      expect(state.heroMood, HeroMood.hurt);
    });

    test('receita recebida na semana é cura; a agendada não', () {
      final state = ArenaCalculator.from(
        _inputs(
          liquidBalance: 100,
          week: [
            _income(id: 'salario', amount: 4200),
            _income(id: 'freela', amount: 800, status: InstallmentStatus.pending),
          ],
        ),
      );

      expect(state.healedThisWeek, 4200);
    });

    test('receita não alimenta o monstro', () {
      final state = ArenaCalculator.from(
        _inputs(week: [_income(id: 'salario', amount: 4200)]),
      );

      expect(state.monsterMaxHp, 0);
    });

    test('transferência não é dano nem cura', () {
      final transfer = InstallmentModel(
        id: 'transf',
        orderId: 'order-transf',
        amount: 900,
        description: 'transf',
        dueDate: _sunday,
        status: InstallmentStatus.paid,
        type: OrderType.transfer,
        installmentType: InstallmentType.single,
      );

      final state = ArenaCalculator.from(_inputs(week: [transfer]));

      expect(state.monsterMaxHp, 0);
      expect(state.healedThisWeek, 0);
    });
  });

  group('elenco', () {
    test('dois heróis com skins distintas e o resto vira contador', () {
      final state = ArenaCalculator.from(
        _inputs(
          members: [
            _member('u1', name: 'Gabriel Silva'),
            _member('u2', name: 'Ana Paula Souza'),
            _member('u3'),
            _member('u4'),
          ],
        ),
      );

      expect(state.heroes.map((h) => h.name), ['Gabriel', 'Ana']);
      expect(state.heroes.map((h) => h.skin), [
        HeroSkin.knight,
        HeroSkin.mage,
      ]);
      expect(state.extraMembers, 2);
    });

    test('sem nome, o herói usa o começo do e-mail', () {
      final state = ArenaCalculator.from(
        _inputs(members: [_member('u1', email: 'gafsel@gmail.com')]),
      );

      expect(state.heroes.single.name, 'gafsel');
      expect(state.extraMembers, 0);
    });
  });

  group('monstro da semana', () {
    test('a skin é estável para o mesmo id de semana', () {
      expect(
        ArenaCalculator.skinForWeek('2026-W38'),
        ArenaCalculator.skinForWeek('2026-W38'),
      );
    });

    test('semanas vizinhas não repetem o bicho', () {
      expect(
        ArenaCalculator.skinForWeek('2026-W38'),
        isNot(ArenaCalculator.skinForWeek('2026-W39')),
      );
    });
  });

  group('cena', () {
    test('a folha lista só as parcelas pendentes, por vencimento', () {
      final state = ArenaCalculator.from(
        _inputs(
          week: [
            _expense(id: 'sexta', amount: 10, dayOffset: 5),
            _expense(
              id: 'paga',
              amount: 10,
              dayOffset: 1,
              status: InstallmentStatus.paid,
              paidDate: _sunday,
            ),
            _expense(id: 'segunda', amount: 10, dayOffset: 1),
          ],
        ),
      );

      expect(state.pendingInstallments.map((i) => i.id), [
        'segunda',
        'sexta',
      ]);
    });

    test('o casulo lê a fatura do servidor, sem calcular nada', () {
      final state = ArenaCalculator.from(
        _inputs(
          invoice: NextInvoice(
            dueDate: _sunday,
            closingDate: _sunday,
            cycleStart: _sunday,
            cycleEnd: _sunday,
            amount: 2340.55,
            installmentId: 'inv-1',
          ),
        ),
      );

      expect(state.invoiceAmount, 2340.55);
      expect(state.invoiceInstallmentId, 'inv-1');
    });

    test('workspace vazio: a cena sabe que não tem o que mostrar', () {
      expect(ArenaCalculator.from(_inputs()).isEmpty, isTrue);
    });
  });
}
