import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/finance/domain/models/category_planning_model.dart';
import 'package:funances/features/finance/domain/models/period_summary_model.dart';
import 'package:funances/features/finance/domain/services/category_planning_service.dart';
import 'package:funances/features/finance/domain/services/period_summary_service.dart';
import 'package:funances/features/finance/domain/services/planning_50_30_20_service.dart';
import 'package:funances/features/home/domain/services/mission_service.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/domain/repositories/category_repository.dart';
import 'package:funances/features/workspace/domain/services/category_service.dart';

/// F4.10 §6.5, risco nº 4 — `Planning503020Service.watchDistribution` é a
/// regra de dinheiro da feature 50-30-20 inteira (a classificação nas três
/// pools e o denominador `totalIncomes`) e não tinha um único teste. Os três
/// casos que existiam cobriam `onError`, `retry` e um ramo de `savePlanning`.

mixin _NaoUsado {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} não usado no teste');
}

class _CategoriasFake with _NaoUsado implements ICategoryRepository {
  _CategoriasFake(this.itens);

  final List<CategoryModel> itens;

  @override
  Stream<List<CategoryModel>> getCategories(String workspaceId) =>
      Stream.value(itens);
}

class _PlanejamentosFake with _NaoUsado implements CategoryPlanningService {
  _PlanejamentosFake(this.itens);

  final List<CategoryPlanningModel> itens;

  @override
  Future<List<CategoryPlanningModel>> plannings({required String month}) async =>
      itens;
}

class _ResumoFake with _NaoUsado implements PeriodSummaryService {
  _ResumoFake(this.categorias);

  final Map<String, PeriodSummaryCategoryModel>? categorias;

  @override
  Stream<PeriodSummaryModel?> watchMonth(int year, int month) => Stream.value(
    categorias == null
        ? null
        : PeriodSummaryModel.month(
            year: year,
            month: month,
            categories: categorias!,
            lastUpdate: DateTime(2026, 3, 15),
          ),
  );
}

CategoryModel _cat(
  String id, {
  CategoryType type = CategoryType.expense,
  CategoryAllocation allocation = CategoryAllocation.essential,
  bool isSystem = false,
  bool isDeleted = false,
}) => CategoryModel(
  id: id,
  name: id,
  icon: 'x',
  color: '#000000',
  type: type,
  allocation: allocation,
  isSystem: isSystem,
  isDeleted: isDeleted,
);

PeriodSummaryCategoryModel _resumo({
  double previsto = 0,
  double realizado = 0,
}) => PeriodSummaryCategoryModel(
  specificPlannedAmount: previsto,
  actualAmount: realizado,
);

Planning503020Service _servico({
  required List<CategoryModel> categorias,
  Map<String, PeriodSummaryCategoryModel>? resumo,
  List<CategoryPlanningModel> planejamentos = const [],
}) => Planning503020Service(
  planningService: _PlanejamentosFake(planejamentos),
  categoryService: CategoryService(
    workspaceId: 'ws',
    repository: _CategoriasFake(categorias),
  ),
  periodSummaryService: _ResumoFake(resumo),
);

final _marco = DateTime(2026, 3, 1);

void main() {
  group('watchDistribution — as três pools', () {
    test('cada categoria cai na pool da sua alocação', () async {
      final distribuicao = await _servico(
        categorias: [
          _cat('moradia', allocation: CategoryAllocation.essential),
          _cat('mercado', allocation: CategoryAllocation.essential),
          _cat('lazer', allocation: CategoryAllocation.comfort),
          _cat('aportes', allocation: CategoryAllocation.investment),
        ],
        resumo: {
          'moradia': _resumo(previsto: 1500, realizado: 1450),
          'mercado': _resumo(previsto: 800, realizado: 920),
          'lazer': _resumo(previsto: 300, realizado: 410),
          'aportes': _resumo(previsto: 600, realizado: 600),
        },
      ).watchDistribution(_marco).first;

      expect(distribuicao.essential.plannedAmount, 2300);
      expect(distribuicao.essential.actualAmount, 2370);
      expect(distribuicao.comfort.plannedAmount, 300);
      expect(distribuicao.comfort.actualAmount, 410);
      expect(distribuicao.investment.plannedAmount, 600);
      expect(distribuicao.investment.actualAmount, 600);
    });

    test('as porcentagens ideais são 50, 30 e 20 — sempre', () async {
      final distribuicao = await _servico(
        categorias: [_cat('moradia')],
        resumo: {'moradia': _resumo(previsto: 100)},
      ).watchDistribution(_marco).first;

      expect(distribuicao.essential.idealPercentage, 0.5);
      expect(distribuicao.comfort.idealPercentage, 0.3);
      expect(distribuicao.investment.idealPercentage, 0.2);
    });

    test('o LIMITE MENSAL manda sobre o já agendado', () async {
      // `effectiveAmount`: quando existe limite (o "geral"), é ele que conta;
      // sem limite, vale a soma do que já foi agendado para a categoria.
      final distribuicao = await _servico(
        categorias: [_cat('moradia')],
        resumo: {'moradia': _resumo(previsto: 1500, realizado: 1400)},
        planejamentos: [
          CategoryPlanningModel(
            id: 'p1',
            category: _cat('moradia'),
            amount: 1800,
            startMonth: '2026-03',
            endMonth: '2026-03',
          ),
        ],
      ).watchDistribution(_marco).first;

      expect(distribuicao.essential.plannedAmount, 1800);
      expect(distribuicao.essential.actualAmount, 1400);
    });

    test('sem resumo do mês, tudo é zero — e não nulo', () async {
      final distribuicao = await _servico(
        categorias: [_cat('moradia'), _cat('lazer')],
      ).watchDistribution(_marco).first;

      expect(distribuicao.essential.plannedAmount, 0);
      expect(distribuicao.comfort.actualAmount, 0);
      expect(distribuicao.totalIncome, 0);
    });

    test('os centavos somam em INTEIROS, sem resto de ponto flutuante',
        () async {
      // Três lançamentos de 0,10 somam 0,30000000000000004 em `double`. É o
      // tipo de resto que fazia o cabeçalho e a soma das linhas divergirem
      // por um centavo.
      final distribuicao = await _servico(
        categorias: [_cat('a'), _cat('b'), _cat('c')],
        resumo: {
          'a': _resumo(previsto: 0.10),
          'b': _resumo(previsto: 0.10),
          'c': _resumo(previsto: 0.10),
        },
      ).watchDistribution(_marco).first;

      expect(distribuicao.essential.plannedAmount, 0.30);
    });
  });

  group('watchDistribution — o denominador', () {
    test('a renda é a soma das categorias de RECEITA', () async {
      final distribuicao = await _servico(
        categorias: [
          _cat('salario', type: CategoryType.income),
          _cat('freela', type: CategoryType.income),
          _cat('moradia'),
        ],
        resumo: {
          'salario': _resumo(previsto: 5000, realizado: 5000),
          'freela': _resumo(previsto: 1000, realizado: 800),
          'moradia': _resumo(previsto: 1500, realizado: 1450),
        },
      ).watchDistribution(_marco).first;

      expect(distribuicao.totalIncome, 6000);
      expect(distribuicao.totalActualIncome, 5800);
      // E a despesa não entra na renda.
      expect(distribuicao.essential.plannedAmount, 1500);
    });

    test('categoria de SISTEMA não entra em pool nenhuma nem na renda',
        () async {
      // As pools do 50-30-20 são editáveis: só entra o que o usuário pode de
      // fato planejar. A categoria do saldo inicial, semeada pelo servidor,
      // inflaria a renda com um valor que ninguém recebe todo mês.
      final distribuicao = await _servico(
        categorias: [
          _cat('initial-balance', type: CategoryType.income, isSystem: true),
          _cat('salario', type: CategoryType.income),
          _cat('virtual_debt_expense', isSystem: true),
          _cat('moradia'),
        ],
        resumo: {
          'initial-balance': _resumo(previsto: 99999, realizado: 99999),
          'salario': _resumo(previsto: 5000, realizado: 5000),
          'virtual_debt_expense': _resumo(previsto: 700, realizado: 700),
          'moradia': _resumo(previsto: 1500, realizado: 1450),
        },
      ).watchDistribution(_marco).first;

      expect(distribuicao.totalIncome, 5000);
      expect(distribuicao.essential.plannedAmount, 1500);
    });

    test('categoria excluída logicamente também fica de fora', () async {
      final distribuicao = await _servico(
        categorias: [
          _cat('antiga', isDeleted: true),
          _cat('moradia'),
        ],
        resumo: {
          'antiga': _resumo(previsto: 300, realizado: 300),
          'moradia': _resumo(previsto: 1500, realizado: 1450),
        },
      ).watchDistribution(_marco).first;

      expect(distribuicao.essential.plannedAmount, 1500);
    });
  });

  group('MissionService.isAdherentTo — dinheiro em centavos', () {
    test('despesa: gastar exatamente o planejado ainda é aderente', () {
      expect(
        MissionService.isAdherentTo(
          type: CategoryType.expense,
          actualAmount: 500,
          plannedAmount: 500,
        ),
        isTrue,
      );
    });

    test('despesa: um centavo a mais NÃO é aderente', () {
      // Com a tolerância de 0,01 em `double` que havia aqui, este caso passava
      // como aderente — o último ponto do checklist medindo dinheiro em ponto
      // flutuante, contra todo o resto do app já em centavos.
      expect(
        MissionService.isAdherentTo(
          type: CategoryType.expense,
          actualAmount: 500.01,
          plannedAmount: 500,
        ),
        isFalse,
      );
    });

    test('receita: alcançar o planejado é aderente; faltar não é', () {
      expect(
        MissionService.isAdherentTo(
          type: CategoryType.income,
          actualAmount: 1000,
          plannedAmount: 1000,
        ),
        isTrue,
      );
      expect(
        MissionService.isAdherentTo(
          type: CategoryType.income,
          actualAmount: 999.99,
          plannedAmount: 1000,
        ),
        isFalse,
      );
    });

    test('a soma que o `double` erra não muda mais a resposta', () {
      // 0.1 + 0.2 = 0.30000000000000004: em `double` isso "passa" do teto de
      // 0.30; em centavos, 30 == 30.
      expect(
        MissionService.isAdherentTo(
          type: CategoryType.expense,
          actualAmount: 0.1 + 0.2,
          plannedAmount: 0.3,
        ),
        isTrue,
      );
    });
  });
}
