import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/models/period_summary_model.dart';
import 'package:funances/features/finance/domain/repositories/account_repository.dart';
import 'package:funances/features/finance/domain/repositories/finance_repository.dart';
import 'package:funances/features/finance/domain/repositories/period_summary_repository.dart';
import 'package:funances/features/finance/domain/services/finance_service.dart';
import 'package:funances/features/finance/domain/services/period_summary_service.dart';
import 'package:funances/features/home/domain/models/mission_model.dart';
import 'package:funances/features/home/domain/services/mission_service.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/domain/repositories/category_repository.dart';
import 'package:funances/features/workspace/domain/services/category_service.dart';

/// F4.10 §6.5, risco nº 9 — `MissionService.watchMissions` são 200 linhas sem
/// nenhum caso: o HP de cada categoria, os limiares `+0.1`/`-0.2` do
/// `ChallengeStatus` e o `PartyStatus` do time. Tudo depende do DIA DA SEMANA,
/// e o `Clock` injetável do serviço nunca tinha sido usado num teste.

mixin _NaoUsado {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} não usado no teste');
}

class _ParcelasFake with _NaoUsado implements IFinanceRepository {
  _ParcelasFake({this.atrasadas = const [], this.daSemana = const []});

  final List<InstallmentModel> atrasadas;
  final List<InstallmentModel> daSemana;

  /// As janelas com que o serviço perguntou — é como o teste confere que a
  /// semana usada foi a certa.
  final List<({DateTime? startDate, DateTime? endDate})> consultas = [];

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
    consultas.add((startDate: startDate, endDate: endDate));
    // O serviço faz duas consultas: as atrasadas (só `endDate`, pendentes) e
    // as da semana (janela fechada).
    return Stream.value(startDate == null ? atrasadas : daSemana);
  }
}

class _ResumoFake with _NaoUsado implements IPeriodSummaryRepository {
  _ResumoFake(this.categorias);

  final Map<String, PeriodSummaryCategoryModel> categorias;
  int? anoConsultado;
  int? semanaConsultada;

  @override
  Stream<PeriodSummaryModel?> watchWeek(
    String workspaceId,
    int year,
    int week,
  ) {
    anoConsultado = year;
    semanaConsultada = week;
    return Stream.value(
      PeriodSummaryModel.week(
        year: year,
        week: week,
        categories: categorias,
        lastUpdate: DateTime(2026, 3, 15),
      ),
    );
  }
}

class _CategoriasFake with _NaoUsado implements ICategoryRepository {
  _CategoriasFake(this.itens);

  final List<CategoryModel> itens;

  @override
  Stream<List<CategoryModel>> getCategories(String workspaceId) =>
      Stream.value(itens);
}

class _ContasFake with _NaoUsado implements IAccountRepository {}

CategoryModel _cat(String id, {CategoryType type = CategoryType.expense}) =>
    CategoryModel(id: id, name: id, icon: 'x', color: '#000000', type: type);

PeriodSummaryCategoryModel _plano({
  required double planejado,
  required double realizado,
}) => PeriodSummaryCategoryModel(
  generalPlannedAmount: planejado,
  actualAmount: realizado,
);

InstallmentModel _parcela({
  required String id,
  required InstallmentStatus status,
  double valor = 100,
  String descricao = 'Conta de luz',
}) => InstallmentModel(
  id: id,
  orderId: 'o-$id',
  amount: valor,
  description: descricao,
  dueDate: DateTime(2026, 3, 10, 12),
  status: status,
  type: OrderType.expense,
  installmentType: InstallmentType.single,
);

/// Quarta-feira, 11/03/2026. `weekday % 7` = 3, então a semana decorrida é
/// `(3 + 1) / 7` = 0,5714.
final _quarta = DateTime(2026, 3, 11, 10);

/// Domingo, 08/03/2026: o primeiro dia da semana, `weekElapsedRatio` = 1/7.
final _domingo = DateTime(2026, 3, 8, 10);

/// Sábado, 14/03/2026: último dia, `weekElapsedRatio` = 1.0.
final _sabado = DateTime(2026, 3, 14, 10);

Future<MissionModel> _missoes({
  Map<String, PeriodSummaryCategoryModel> resumo = const {},
  List<CategoryModel> categorias = const [],
  List<InstallmentModel> atrasadas = const [],
  List<InstallmentModel> daSemana = const [],
  DateTime? hoje,
  _ParcelasFake? parcelas,
  _ResumoFake? resumoFake,
}) {
  final parcelasRepo =
      parcelas ?? _ParcelasFake(atrasadas: atrasadas, daSemana: daSemana);
  final resumoRepo = resumoFake ?? _ResumoFake(resumo);

  final servico = MissionService(
    financeService: FinanceService(
      workspaceId: 'ws',
      repository: parcelasRepo,
      accountRepository: _ContasFake(),
      categoryRepository: _CategoriasFake(categorias),
    ),
    summaryService: PeriodSummaryService(
      workspaceId: 'ws',
      repository: resumoRepo,
    ),
    categoryService: CategoryService(
      workspaceId: 'ws',
      repository: _CategoriasFake(categorias),
    ),
    now: () => hoje ?? _quarta,
  );

  return servico.watchMissions().first;
}

void main() {
  group('a janela da semana', () {
    test('as consultas usam domingo 00:00 e o fim do sábado', () async {
      final parcelas = _ParcelasFake();
      await _missoes(parcelas: parcelas, hoje: _quarta);

      final semana = parcelas.consultas.firstWhere((c) => c.startDate != null);
      expect(semana.startDate, DateTime(2026, 3, 8));
      expect(
        semana.endDate,
        DateTime(2026, 3, 15).subtract(const Duration(milliseconds: 1)),
      );

      // As atrasadas são o que venceu ANTES do começo da semana.
      final atrasadas = parcelas.consultas.firstWhere(
        (c) => c.startDate == null,
      );
      expect(
        atrasadas.endDate,
        DateTime(2026, 3, 8).subtract(const Duration(seconds: 1)),
      );
    });

    test('o resumo semanal é pedido pelo id da semana do produto', () async {
      final resumo = _ResumoFake(const {});
      await _missoes(resumoFake: resumo, hoje: _quarta);

      expect(resumo.anoConsultado, 2026);
      expect(resumo.semanaConsultada, 10);
    });

    test('o modelo devolve a janela que usou', () async {
      final modelo = await _missoes(hoje: _quarta);

      expect(modelo.startDate, DateTime(2026, 3, 8));
      expect(modelo.endDate.day, 14);
    });
  });

  group('HP e ChallengeStatus de uma DESPESA', () {
    Future<PlanningMission> despesa({
      required double planejado,
      required double realizado,
      DateTime? hoje,
    }) async {
      final modelo = await _missoes(
        categorias: [_cat('mercado')],
        resumo: {'mercado': _plano(planejado: planejado, realizado: realizado)},
        hoje: hoje,
      );
      return modelo.planningMissions.single;
    }

    test('HP é o que sobra do limite', () async {
      final missao = await despesa(planejado: 100, realizado: 25);

      expect(missao.progress, 0.25);
      expect(missao.hp, closeTo(0.75, 0.0001));
      expect(missao.isAdherent, isTrue);
    });

    test('estourar o limite zera o HP e fica CRÍTICO', () async {
      final missao = await despesa(planejado: 100, realizado: 140);

      expect(missao.status, ChallengeStatus.critical);
      expect(missao.hp, 0.0);
      expect(missao.isAdherent, isFalse);
    });

    test('gastar exatamente o limite ainda NÃO é crítico', () async {
      // Crítico é `> 1.0`, não `>=`: quem gastou exatamente o planejado
      // cumpriu o planejado, e `isAdherent` diz isso. Mas o HP já é zero (não
      // sobrou limite) e, numa quarta-feira, gastar a semana inteira em três
      // dias é aviso — as duas leituras convivem de propósito.
      final missao = await despesa(planejado: 100, realizado: 100);

      expect(missao.status, isNot(ChallengeStatus.critical));
      expect(missao.status, ChallengeStatus.warning);
      expect(missao.hp, 0.0);
      expect(missao.isAdherent, isTrue);
    });

    test('gastar mais rápido que o tempo da semana vira AVISO', () async {
      // Quarta: 57,1% da semana. O limiar é 57,1% + 10% = 67,1%.
      expect(
        (await despesa(planejado: 100, realizado: 70, hoje: _quarta)).status,
        ChallengeStatus.warning,
      );
      expect(
        (await despesa(planejado: 100, realizado: 60, hoje: _quarta)).status,
        ChallengeStatus.stable,
      );
    });

    test(
      'a folga de 10 pontos existe: no limiar exato ainda é estável',
      () async {
        // 57,14% + 10% = 67,14%. Gastar 67% não dispara.
        final missao = await despesa(
          planejado: 100,
          realizado: 67,
          hoje: _quarta,
        );
        expect(missao.status, ChallengeStatus.stable);
      },
    );

    test('o MESMO gasto muda de status conforme o dia da semana', () async {
      // É o ponto do `weekElapsedRatio`: gastar 60% do limite é cedo demais no
      // domingo e perfeitamente normal no sábado.
      expect(
        (await despesa(planejado: 100, realizado: 60, hoje: _domingo)).status,
        ChallengeStatus.warning,
      );
      expect(
        (await despesa(planejado: 100, realizado: 60, hoje: _sabado)).status,
        ChallengeStatus.stable,
      );
    });
  });

  group('HP e ChallengeStatus de uma RECEITA', () {
    Future<PlanningMission> receita({
      required double planejado,
      required double realizado,
      DateTime? hoje,
    }) async {
      final modelo = await _missoes(
        categorias: [_cat('salario', type: CategoryType.income)],
        resumo: {'salario': _plano(planejado: planejado, realizado: realizado)},
        hoje: hoje,
      );
      return modelo.planningMissions.single;
    }

    test('HP é o quanto já entrou — o oposto da despesa', () async {
      final missao = await receita(planejado: 1000, realizado: 250);

      expect(missao.hp, closeTo(0.25, 0.0001));
      expect(missao.isAdherent, isFalse);
    });

    test('receber tudo satura o HP em 1 e é estável', () async {
      final missao = await receita(planejado: 1000, realizado: 1500);

      expect(missao.hp, 1.0);
      expect(missao.status, ChallengeStatus.stable);
      expect(missao.isAdherent, isTrue);
    });

    test('ficar 20 pontos abaixo do ritmo da semana vira AVISO', () async {
      // Quarta: 57,1%. O limiar é 57,1% - 20% = 37,1%.
      expect(
        (await receita(planejado: 1000, realizado: 300, hoje: _quarta)).status,
        ChallengeStatus.warning,
      );
      expect(
        (await receita(planejado: 1000, realizado: 400, hoje: _quarta)).status,
        ChallengeStatus.stable,
      );
    });

    test('receita NUNCA fica crítica — só despesa mata', () async {
      final missao = await receita(
        planejado: 1000,
        realizado: 0,
        hoje: _sabado,
      );

      expect(missao.status, ChallengeStatus.warning);
      expect(missao.hp, 0.0);
    });
  });

  group('categoria sem plano da semana não vira desafio', () {
    test('planejado zero é ignorado', () async {
      final modelo = await _missoes(
        categorias: [_cat('mercado')],
        resumo: {'mercado': _plano(planejado: 0, realizado: 300)},
      );

      expect(modelo.planningMissions, isEmpty);
    });

    test(
      'resumo de uma categoria que o workspace não tem é ignorado',
      () async {
        // Acontece com categoria apagada: o resumo do período guarda o id.
        final modelo = await _missoes(
          categorias: [_cat('mercado')],
          resumo: {'fantasma': _plano(planejado: 100, realizado: 50)},
        );

        expect(modelo.planningMissions, isEmpty);
      },
    );
  });

  group('PartyStatus — a saúde do time', () {
    Future<MissionModel> time(
      Map<String, PeriodSummaryCategoryModel> resumo, {
      DateTime? hoje,
      List<CategoryModel>? categorias,
    }) => _missoes(
      categorias: categorias ?? [_cat('mercado'), _cat('lazer')],
      resumo: resumo,
      hoje: hoje,
    );

    test('todo mundo dentro do ritmo: saudável', () async {
      final modelo = await time({
        'mercado': _plano(planejado: 500, realizado: 200),
        'lazer': _plano(planejado: 200, realizado: 50),
      });

      expect(modelo.partyStatus, PartyStatus.healthy);
      expect(modelo.totalPlannedAmount, 700);
      expect(modelo.totalActualAmount, 250);
      expect(modelo.partyHp, closeTo(1 - 250 / 700, 0.0001));
    });

    test('o total estourado derruba o time', () async {
      final modelo = await time({
        'mercado': _plano(planejado: 500, realizado: 600),
        'lazer': _plano(planejado: 200, realizado: 300),
      });

      expect(modelo.partyStatus, PartyStatus.defeated);
      expect(modelo.partyHp, 0.0);
    });

    test('UMA categoria crítica já tira o time do saudável', () async {
      // O total está confortável (310 de 5200), mas o lazer estourou. Sem esta
      // regra, o time apareceria verde com um membro morto.
      final modelo = await time({
        'mercado': _plano(planejado: 5000, realizado: 100),
        'lazer': _plano(planejado: 200, realizado: 210),
      });

      expect(
        modelo.planningMissions
            .firstWhere((m) => m.category.id == 'lazer')
            .status,
        ChallengeStatus.critical,
      );
      expect(modelo.partyStatus, PartyStatus.strained);
    });

    test('o time só conta DESPESAS — receita não entra no total', () async {
      final modelo = await time(
        {
          'mercado': _plano(planejado: 500, realizado: 200),
          'salario': _plano(planejado: 9000, realizado: 0),
        },
        categorias: [
          _cat('mercado'),
          _cat('salario', type: CategoryType.income),
        ],
      );

      expect(modelo.totalPlannedAmount, 500);
      expect(modelo.totalActualAmount, 200);
    });

    test('sem nenhum plano, o time nasce inteiro', () async {
      final modelo = await _missoes();

      expect(modelo.partyStatus, PartyStatus.healthy);
      expect(modelo.partyHp, 1.0);
      expect(modelo.totalPlannedAmount, 0);
    });
  });

  group('o checklist da semana', () {
    test('separa o que falta do que já foi feito', () async {
      final modelo = await _missoes(
        daSemana: [
          _parcela(
            id: 'a',
            status: InstallmentStatus.pending,
            descricao: 'Água',
          ),
          _parcela(id: 'b', status: InstallmentStatus.paid, descricao: 'Luz'),
          _parcela(
            id: 'c',
            status: InstallmentStatus.settled,
            descricao: 'Internet',
          ),
        ],
      );

      expect(modelo.pendingInstallments.map((m) => m.installment.id), ['a']);
      expect(modelo.completedInstallments.map((m) => m.installment.id), [
        'c',
        'b',
      ]);
      expect(modelo.completedCount, 2);
      // O que está feito conta como aderente; o que falta, não.
      expect(modelo.completedInstallments.every((m) => m.isAdherent), isTrue);
      expect(modelo.pendingInstallments.every((m) => !m.isAdherent), isTrue);
    });

    test('parcela removida e valor zero ficam de fora do checklist', () async {
      final modelo = await _missoes(
        daSemana: [
          _parcela(id: 'a', status: InstallmentStatus.removed),
          _parcela(id: 'b', status: InstallmentStatus.pending, valor: 0),
        ],
        atrasadas: [
          _parcela(id: 'c', status: InstallmentStatus.removed),
          _parcela(id: 'd', status: InstallmentStatus.pending, valor: 0),
        ],
      );

      expect(modelo.pendingInstallments, isEmpty);
      expect(modelo.completedInstallments, isEmpty);
      expect(modelo.overdueInstallments, isEmpty);
    });

    test(
      'as atrasadas vêm em lista própria, ordenadas por descrição',
      () async {
        final modelo = await _missoes(
          atrasadas: [
            _parcela(
              id: 'z',
              status: InstallmentStatus.pending,
              descricao: 'Zelador',
            ),
            _parcela(
              id: 'a',
              status: InstallmentStatus.pending,
              descricao: 'Aluguel',
            ),
          ],
        );

        expect(
          modelo.overdueInstallments.map((m) => m.installment.description),
          ['Aluguel', 'Zelador'],
        );
      },
    );

    test('os desafios saem ordenados por nome de categoria', () async {
      final modelo = await _missoes(
        categorias: [_cat('zzz'), _cat('aaa')],
        resumo: {
          'zzz': _plano(planejado: 100, realizado: 10),
          'aaa': _plano(planejado: 100, realizado: 10),
        },
      );

      expect(modelo.planningMissions.map((m) => m.category.id), ['aaa', 'zzz']);
    });
  });
}
