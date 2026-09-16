import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/goal/domain/models/goal_model.dart';
import 'package:funances/features/goal/presentation/model/goal_progress_ui.dart';
import 'package:funances/features/workspace/domain/models/badge_catalog_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/l10n/app_localizations.dart';

/// F2.5 (QA) — o DESFECHO da meta, não o valor, é quem diz se ela acabou e
/// como. Nas metas de redução, passar do alvo é fracasso: o app não pode
/// chamar isso de conclusão em lugar nenhum.
void main() {
  late AppLocalizations pt;
  late AppLocalizations en;

  setUpAll(() async {
    pt = await AppLocalizations.delegate.load(const Locale('pt'));
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  String fmt(DateTime date) => '10/06/2026';

  final quando = DateTime(2026, 6, 10);

  GoalModel poupanca({GoalOutcome? outcome, DateTime? completedAt, DateTime? failedAt}) =>
      GoalModel.saveMoney(
        id: 'g1',
        name: 'Reserva',
        targetAmount: 1000,
        currentAmount: 1000,
        deadline: DateTime(2026, 12, 31),
        accountId: 'acc1',
        startDate: DateTime(2026, 1, 1),
        outcome: outcome,
        completedAt: completedAt,
        failedAt: failedAt,
      );

  GoalModel teto({GoalOutcome? outcome, DateTime? completedAt, DateTime? failedAt}) =>
      GoalModel.reduceExpense(
        id: 'g2',
        name: 'Segurar o mercado',
        targetAmount: 1000,
        currentAmount: 1800,
        deadline: DateTime(2026, 12, 31),
        category: const CategoryModel(
          id: 'cat1',
          name: 'Mercado',
          icon: 'shopping_cart',
          color: '#EF5350',
          type: CategoryType.expense,
        ),
        startDate: DateTime(2026, 1, 1),
        outcome: outcome,
        completedAt: completedAt,
        failedAt: failedAt,
      );

  group('desfecho da meta', () {
    test('meta sem desfecho está em andamento e não tem rótulo', () {
      expect(poupanca().isActive, isTrue);
      expect(poupanca().isCompleted, isFalse);
      expect(poupanca().isFailed, isFalse);
      expect(poupanca().outcomeLabel(pt, fmt), isNull);
    });

    test('meta de redução ACIMA do alvo, sem desfecho, não é "concluída"', () {
      // 1800 gastos contra um teto de 1000: o valor sozinho não conclui nada.
      final estourada = teto();
      expect(estourada.currentAmount, greaterThan(estourada.targetAmount));
      expect(estourada.isCompleted, isFalse);
      expect(estourada.outcomeLabel(pt, fmt), isNull);
    });

    test('sucesso mostra "Concluída em" nos dois tipos', () {
      expect(
        poupanca(outcome: GoalOutcome.success, completedAt: quando)
            .outcomeLabel(pt, fmt),
        pt.goalCompletedAt('10/06/2026'),
      );
      expect(
        teto(outcome: GoalOutcome.success, completedAt: quando)
            .outcomeLabel(pt, fmt),
        pt.goalCompletedAt('10/06/2026'),
      );
    });

    test('redução que falhou mostra "Limite estourado em"', () {
      final falhada = teto(outcome: GoalOutcome.failed, failedAt: quando);

      expect(falhada.outcomeLabel(pt, fmt), pt.goalLimitBlownAt('10/06/2026'));
      expect(falhada.outcomeLabel(pt, fmt), isNot(pt.goalCompletedAt('10/06/2026')));
      expect(falhada.isCompleted, isFalse);
      expect(falhada.isFailed, isTrue);
    });

    test('acúmulo que falhou mostra "Prazo encerrado sem atingir"', () {
      final falhada = poupanca(outcome: GoalOutcome.failed, failedAt: quando);

      expect(
        falhada.outcomeLabel(pt, fmt),
        pt.goalDeadlineMissedAt('10/06/2026'),
      );
    });

    test('o visual da falha é o de erro, e o do sucesso é o de conquista', () {
      final falhada = teto(outcome: GoalOutcome.failed, failedAt: quando);
      final vencedora = poupanca(outcome: GoalOutcome.success, completedAt: quando);

      expect(falhada.outcomeIcon, Icons.report_gmailerrorred);
      expect(vencedora.outcomeIcon, Icons.emoji_events);
      expect(falhada.outcomeColor, isNot(vencedora.outcomeColor));
    });

    test('desfecho sem carimbo de data não inventa rótulo', () {
      expect(poupanca(outcome: GoalOutcome.success).outcomeLabel(pt, fmt), isNull);
      expect(teto(outcome: GoalOutcome.failed).outcomeLabel(pt, fmt), isNull);
    });

    test('meta encerrada não é ativa', () {
      expect(poupanca(outcome: GoalOutcome.success, completedAt: quando).isActive, isFalse);
      expect(teto(outcome: GoalOutcome.failed, failedAt: quando).isActive, isFalse);
    });
  });

  group('serialização do desfecho', () {
    test('lê outcome e failedAt do JSON do servidor', () {
      final goal = GoalModel.fromJson({
        'runtimeType': 'reduceExpense',
        'id': 'g3',
        'name': 'Teto',
        'targetAmount': 1000.0,
        'currentAmount': 1800.0,
        'deadline': '2026-12-31T00:00:00.000',
        'startDate': '2026-01-01T00:00:00.000',
        'category': {
          'id': 'cat1',
          'name': 'Mercado',
          'icon': 'shopping_cart',
          'color': '#EF5350',
          'type': 'expense',
        },
        'outcome': 'failed',
        'failedAt': '2026-06-10T00:00:00.000',
      });

      expect(goal.isFailed, isTrue);
      expect(goal.failedAt, DateTime(2026, 6, 10));
      expect(goal.outcomeLabel(en, fmt), en.goalLimitBlownAt('10/06/2026'));
    });

    test('desfecho desconhecido vira "em andamento", não quebra a tela', () {
      final goal = GoalModel.fromJson({
        'runtimeType': 'saveMoney',
        'id': 'g4',
        'name': 'Reserva',
        'targetAmount': 1000.0,
        'currentAmount': 10.0,
        'deadline': '2026-12-31T00:00:00.000',
        'startDate': '2026-01-01T00:00:00.000',
        'accountId': 'acc1',
        'outcome': 'desfecho_do_futuro',
      });

      expect(goal.outcome, isNull);
      expect(goal.isActive, isTrue);
    });
  });

  group('catálogo de badges por locale', () {
    const badge = BadgeCatalogItem(
      id: 'first_step',
      name: {'pt': 'Primeiro Passo', 'en': 'First Step'},
      description: {'pt': 'Concluir o onboarding.', 'en': 'Finish onboarding.'},
    );

    test('escolhe o texto do locale pedido', () {
      expect(badge.nameIn('en'), 'First Step');
      expect(badge.nameIn('pt'), 'Primeiro Passo');
      expect(badge.descriptionIn('en'), 'Finish onboarding.');
    });

    test('aceita locale com região (pt_BR, en-US)', () {
      expect(badge.nameIn('pt_BR'), 'Primeiro Passo');
      expect(badge.nameIn('en-US'), 'First Step');
    });

    test('locale sem tradução cai no português', () {
      expect(badge.nameIn('fr'), 'Primeiro Passo');
    });

    test('catálogo antigo (texto em string pura) é lido como português', () {
      final item = BadgeCatalogItem.fromJson(const {
        'id': 'first_step',
        'name': 'Primeiro Passo',
        'description': 'Concluir o onboarding.',
      });

      expect(item.nameIn('pt'), 'Primeiro Passo');
      expect(item.nameIn('en'), 'Primeiro Passo');
    });

    test('texto ausente devolve vazio em vez de estourar', () {
      const vazio = BadgeCatalogItem(id: 'x');
      expect(vazio.nameIn('pt'), '');
      expect(vazio.descriptionIn('en'), '');
    });
  });
}
