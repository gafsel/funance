import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/money/money.dart';
import 'package:funances/features/arena/domain/models/hud_state.dart';
import 'package:funances/features/arena/domain/services/hud_calculator.dart';

/// O rodapé mensal da Arena, conferido contra o cofre REAL do dono
/// (workspace 42d43a0e, setembro de 2026) e contra os cortes do contrato.
///
/// O que estes testes guardam, e por quê:
///
/// - as **faixas da escala** nos limites exatos. Elas são fechadas à
///   esquerda (`>=`), e o corte é decidido em CENTAVOS INTEIROS: metade de
///   R$ 18.550,00 é exata em `int` e aproximada em `double`, e uma poção
///   exatamente no corte precisa cair do lado de cima;
/// - a **ausência de `expectedIncome`**, que é o estado mais fácil de errar:
///   sem denominador a razão não é zero, é NENHUMA. Zero é um veredito
///   ("você não guardou nada") sobre alguém de quem o servidor ainda não sabe
///   a receita;
/// - a **peneira da vila**: sistema, receita e categoria sem orçamento não
///   são aldeãos, e a soma é em centavos.

/// A receita prevista real do cofre do dono em setembro de 2026:
/// R$ 17.000 de salário + R$ 1.550 de benefícios, agendados.
const int _rendaCents = 1855000;

ExpectedIncome _renda({
  int cents = _rendaCents,
  ExpectedIncomeSource source = ExpectedIncomeSource.planned,
}) => ExpectedIncome(
  monthKey: '2026-09',
  amount: Money.fromCents(cents),
  source: source,
);

HudBalanceReading _conta(String id, double saldo, {String? nome}) =>
    HudBalanceReading(
      accountId: id,
      name: nome ?? id,
      balance: saldo,
      color: '#2E7D32',
    );

HudInvoiceReading _fatura(
  String id,
  double valor, {
  String? nome,
  int diaVencimento = 10,
  bool aberta = false,
}) => HudInvoiceReading(
  accountId: id,
  name: nome ?? id,
  amount: valor,
  closingDate: DateTime(2026, 10, 4),
  dueDate: DateTime(2026, 10, diaVencimento),
  isOpenCycle: aberta,
);

HudCategoryReading _categoria(
  String nome, {
  double planejado = 0,
  double realizado = 0,
  bool despesa = true,
  bool sistema = false,
  bool investimento = false,
}) => HudCategoryReading(
  categoryId: 'cat-$nome',
  name: nome,
  icon: 'shopping_cart',
  color: '#FF5722',
  isExpense: despesa,
  isSystem: sistema,
  planned: planejado,
  actual: realizado,
  isInvestment: investimento,
);

HudState _hud({
  ExpectedIncome? renda,
  List<HudBalanceReading> investimentos = const [],
  List<HudBalanceReading> dividas = const [],
  List<HudInvoiceReading> faturas = const [],
  List<HudCategoryReading> categorias = const [],
  List<HudMonthlyReport> historico = const [],
  Map<String, ({Money amount, DateTime dueDate})> parcelas = const {},
}) => HudCalculator.from(
  HudInputs(
    monthKey: '2026-09',
    income: renda,
    investments: investimentos,
    debts: dividas,
    invoices: faturas,
    categories: categorias,
    history: historico,
    debtInstallments: parcelas,
  ),
);

void main() {
  group('a escala: uma só, e mede tamanho', () {
    // Os quatro cortes valem igual nos três ícones de razão. Aqui eles são
    // exercitados na poção; os outros dois usam o MESMO `HudRatio`.
    HudTier? classeDe(double saldo) => _hud(
      renda: _renda(),
      investimentos: [_conta('inv', saldo)],
    ).potion.ratio.tier;

    test('abaixo de meio mês de receita não tem classe', () {
      // R$ 9.274,99 contra R$ 18.550,00: um centavo abaixo da metade.
      // Sem classe: o dono tirou o "gole", e abaixo do primeiro
      // corte a poção mostra a razão em vez de um título.
      expect(classeDe(9274.99), isNull);
    });

    test('exatamente meio mês já é semi: a faixa é fechada à esquerda', () {
      expect(classeDe(9275), HudTier.semi);
    });

    test('um centavo antes do mês inteiro ainda é semi', () {
      expect(classeDe(18549.99), HudTier.semi);
    });

    test('um mês inteiro é regular', () {
      expect(classeDe(18550), HudTier.regular);
    });

    test('um mês e meio é super', () {
      expect(classeDe(27825), HudTier.superTier);
    });

    test('um centavo antes de um mês e meio ainda é regular', () {
      expect(classeDe(27824.99), HudTier.regular);
    });

    test('dois meses é hiper, e daí para cima não sobe mais', () {
      expect(classeDe(37100), HudTier.hyper);
      expect(classeDe(200000), HudTier.hyper);
    });

    test('o corte é em centavos inteiros, não em ponto flutuante', () {
      // Uma receita ÍMPAR em centavos: metade de R$ 100,01 é R$ 50,005, que
      // não existe. O corte tem de cair no centavo seguinte — R$ 50,00 ainda
      // é "nenhuma", R$ 50,01 já é semi.
      HudTier? classe(double saldo) => _hud(
        renda: _renda(cents: 10001),
        investimentos: [_conta('inv', saldo)],
      ).potion.ratio.tier;

      expect(classe(50), isNull);
      expect(classe(50.01), HudTier.semi);
    });
  });

  group('sem receita prevista, nenhuma razão existe', () {
    // `expectedIncome` ausente é CARREGAMENTO, nunca receita zero. O app não
    // inventa denominador — mostra o ícone neutro com um traço.
    final estado = _hud(
      investimentos: [_conta('inv', 5000)],
      dividas: [_conta('debt', -8000)],
      faturas: [_fatura('card', 3000)],
    );

    test('a poção não tem classe nem valor', () {
      expect(estado.potion.ratio.tier, isNull);
      expect(estado.potion.ratio.value, isNull);
      expect(estado.potion.ratio.isUnknown, isTrue);
    });

    test('o ovo e a gota também não', () {
      expect(estado.egg.ratio.tier, isNull);
      expect(estado.drop.ratio.tier, isNull);
    });

    test('mas os VALORES continuam de pé: o que falta é o divisor', () {
      expect(estado.potion.total, Money.fromDouble(5000));
      expect(estado.egg.total, Money.fromDouble(3000));
      expect(estado.drop.total, Money.fromDouble(8000));
    });

    test('e o anel fica vazio, em vez de cheio por divisão por zero', () {
      expect(estado.egg.ratio.fill, 0);
      expect(estado.egg.stage, 0);
      expect(estado.egg.isTrembling, isFalse);
    });

    test('receita publicada como zero vale o mesmo que ausente', () {
      // O contrato diz que o servidor não publica zero. Se publicar, dividir
      // por ele daria infinito — e infinito vira anel cheio.
      final zerada = _hud(
        renda: _renda(cents: 0),
        investimentos: [_conta('inv', 5000)],
      );

      expect(zerada.potion.ratio.isUnknown, isTrue);
      expect(zerada.potion.ratio.tier, isNull);
    });

    test('a vila NÃO depende da receita: ela tem denominador próprio', () {
      final vila = _hud(
        categorias: [
          _categoria('Mercado', planejado: 1000, realizado: 400),
          _categoria('Lazer', planejado: 1000, realizado: 600),
        ],
      ).village;

      expect(vila.ring, closeTo(0.5, 0.0001));
      expect(vila.plannedCount, 2);
    });
  });

  group('a poção: o que está guardado', () {
    test('sem conta de investimento ela fica vazia e opaca', () {
      final potion = _hud(renda: _renda()).potion;

      expect(potion.isFilled, isFalse);
      expect(potion.total, Money.zero);
      expect(potion.ratio.tier, isNull);
    });

    test('com saldo ela acende, mesmo sem chegar a meio mês', () {
      // O retrato real: Cofrinho Disney, R$ 263,41 contra R$ 18.550,00 — 1,4%
      // de um mês. A poção é VERDE porque há o que beber; a CLASSE é que não
      // subiu.
      final potion = _hud(
        renda: _renda(),
        investimentos: [_conta('cofrinho', 263.41, nome: 'Cofrinho Disney')],
      ).potion;

      expect(potion.isFilled, isTrue);
      expect(potion.ratio.tier, isNull);
      expect(potion.ratio.value, closeTo(0.0142, 0.0001));
    });

    test('as contas vêm da maior para a menor', () {
      final potion = _hud(
        renda: _renda(),
        investimentos: [
          _conta('a', 100, nome: 'Pequena'),
          _conta('b', 9000, nome: 'Grande'),
          _conta('c', 500, nome: 'Média'),
        ],
      ).potion;

      expect(potion.accounts.map((a) => a.name), [
        'Grande',
        'Média',
        'Pequena',
      ]);
    });

    test('a soma é em centavos: três de 0,10 dão 0,30 exato', () {
      final potion = _hud(
        renda: _renda(),
        investimentos: [for (var i = 0; i < 3; i++) _conta('c$i', 0.1)],
      ).potion;

      expect(potion.total.cents, 30);
    });

    test('saldo negativo não vira razão negativa', () {
      // Um resgate maior que o aporte deixa a conta no vermelho. A linha
      // continua aparecendo como é, mas a razão tem piso em zero: uma poção
      // "menos meio mês" não quer dizer nada.
      final potion = _hud(
        renda: _renda(),
        investimentos: [_conta('inv', -400)],
      ).potion;

      expect(potion.total.cents, -40000);
      expect(potion.ratio.value, 0);
      expect(potion.ratio.tier, isNull);
      expect(potion.isFilled, isFalse);
    });
  });

  group('a vila: quem é aldeão', () {
    test('categoria de despesa com orçamento é aldeã; o HP é o que sobra', () {
      final vila = _hud(
        categorias: [
          _categoria('Mercado', planejado: 3500, realizado: 1158.20),
        ],
      ).village;

      expect(vila.villagers.single.hp, Money.fromDouble(2341.80));
      expect(vila.villagers.single.isAlive, isTrue);
    });

    test('estourou o orçamento, o aldeão cai — e o HP fica negativo', () {
      final aldeao = _hud(
        categorias: [
          _categoria('Manutenção do carro', planejado: 350, realizado: 1462.77),
        ],
      ).village.villagers.single;

      expect(aldeao.isAlive, isFalse);
      expect(aldeao.hp, Money.fromDouble(-1112.77));
      expect(aldeao.hpRatio, 0);
    });

    test('gastar EXATAMENTE o planejado é o alvo, não uma falha', () {
      final aldeao = _hud(
        categorias: [_categoria('Água', planejado: 437.82, realizado: 437.82)],
      ).village.villagers.single;

      expect(aldeao.isAlive, isTrue);
      expect(aldeao.hp, Money.zero);
    });

    test('categoria de RECEITA não é aldeã', () {
      final vila = _hud(
        categorias: [
          _categoria(
            'Salário',
            planejado: 17000,
            realizado: 17000,
            despesa: false,
          ),
        ],
      ).village;

      expect(vila.villagers, isEmpty);
      expect(vila.unprotected, isEmpty);
    });

    test('categoria de SISTEMA não é aldeã', () {
      // O saldo inicial é uma categoria de sistema. Sem o filtro, abrir uma
      // conta viraria um aldeão gigante no primeiro mês do workspace.
      final vila = _hud(
        categorias: [
          _categoria(
            'Saldo inicial',
            planejado: 20000,
            realizado: 0,
            sistema: true,
          ),
        ],
      ).village;

      expect(vila.villagers, isEmpty);
    });

    test('categoria SEM orçamento e COM gasto fica sem proteção', () {
      // Ela não perde nada: o jogo premia planejar de propósito, e tratar o
      // não planejado como morte puniria quem ainda não começou.
      final vila = _hud(
        categorias: [
          _categoria('Assinaturas', planejado: 0, realizado: 495.25),
        ],
      ).village;

      expect(vila.villagers, isEmpty);
      expect(vila.unprotected.single.name, 'Assinaturas');
      expect(vila.unprotected.single.amount, Money.fromDouble(495.25));
    });

    test('categoria sem orçamento e sem gasto não aparece em lugar nenhum', () {
      final vila = _hud(categorias: [_categoria('Dormente')]).village;

      expect(vila.villagers, isEmpty);
      expect(vila.unprotected, isEmpty);
      expect(vila.isEmpty, isTrue);
    });

    test('os aldeões vêm do pior HP para o melhor', () {
      final vila = _hud(
        categorias: [
          _categoria('Folgada', planejado: 1000, realizado: 100),
          _categoria('Estourada', planejado: 100, realizado: 900),
          _categoria('No limite', planejado: 500, realizado: 480),
        ],
      ).village;

      expect(vila.villagers.map((v) => v.name), [
        'Estourada',
        'No limite',
        'Folgada',
      ]);
    });

    test('risco é FRAÇÃO de HP, não folga em reais', () {
      // O caso real do cofre do dono, e o defeito que a ordem por HP
      // absoluto produzia: "Investimentos" tem R$ 200 de orçamento e nada
      // gasto — está 100% vivo — e subia acima de "Cuidados pessoais", que
      // já queimou 78% de R$ 1.500 e é quem pode cair este mês. R$ 200 de
      // folga é menos que R$ 328,80, e a conta antiga parava aí.
      final vila = _hud(
        categorias: [
          _categoria('Investimentos', planejado: 200, realizado: 0),
          _categoria('Cuidados pessoais', planejado: 1500, realizado: 1171.20),
        ],
      ).village;

      expect(vila.villagers.map((v) => v.name), [
        'Cuidados pessoais',
        'Investimentos',
      ]);
    });

    test('os MORTOS vêm antes de todos os vivos, do mais fundo', () {
      final vila = _hud(
        categorias: [
          // Vivo, mas quase caindo: 1% de HP.
          _categoria('Quase caindo', planejado: 1000, realizado: 990),
          // Morto raso: R$ 20 além.
          _categoria('Raso', planejado: 100, realizado: 120),
          // Morto fundo: R$ 1.112,77 além.
          _categoria('Fundo', planejado: 350, realizado: 1462.77),
          _categoria('Folgado', planejado: 1000, realizado: 100),
        ],
      ).village;

      expect(vila.villagers.map((v) => v.name), [
        'Fundo',
        'Raso',
        'Quase caindo',
        'Folgado',
      ]);
    });

    test('empate de fração desempata pelo nome', () {
      final vila = _hud(
        categorias: [
          _categoria('Zulu', planejado: 1000, realizado: 500),
          _categoria('Alfa', planejado: 200, realizado: 100),
        ],
      ).village;

      expect(vila.villagers.map((v) => v.name), ['Alfa', 'Zulu']);
    });
  });

  group('a receita prevista é a DESTE mês', () {
    test('receita de outro mês é tratada como ausente', () {
      // O documento do workspace guarda um `monthKey` justamente porque o
      // campo pode ficar para trás: o cron do dia 1 não rodou, o app virou o
      // mês aberto na mão do usuário. Dividir as faturas de setembro pela
      // receita de agosto daria um número, e o número seria apresentado com
      // a mesma confiança de um certo.
      final hud = _hud(
        renda: ExpectedIncome(
          monthKey: '2026-08',
          amount: Money.fromCents(_rendaCents),
          source: ExpectedIncomeSource.planned,
        ),
        investimentos: [_conta('inv', 9275)],
      );

      expect(hud.income, isNull, reason: 'fora de mês é "ainda não sei"');
      expect(hud.hasIncome, isFalse);
      expect(hud.potion.ratio.tier, isNull);
      expect(hud.potion.ratio.isUnknown, isTrue);

      // E o numerador continua sendo o que é: o que sumiu é o denominador.
      expect(hud.potion.total, Money.fromDouble(9275));
    });

    test('receita do mês corrente vale, e é o denominador', () {
      final hud = _hud(renda: _renda(), investimentos: [_conta('inv', 9275)]);

      expect(hud.income!.monthKey, hud.monthKey);
      expect(hud.potion.ratio.tier, HudTier.semi);
    });

    test('a ausência de mês certo não afeta a vila', () {
      // A vila não depende da receita: o denominador dela é o próprio plano.
      final hud = _hud(
        renda: ExpectedIncome(
          monthKey: '2026-08',
          amount: Money.fromCents(_rendaCents),
          source: ExpectedIncomeSource.planned,
        ),
        categorias: [
          _categoria('Supermercado', planejado: 3500, realizado: 1158.20),
        ],
      );

      expect(hud.village.villagers, hasLength(1));
      expect(hud.village.ring, closeTo(0.3309, 0.0001));
    });
  });

  group('a vila: o anel e o XP', () {
    HudVillage vilaDe(List<({double p, double a})> linhas) => _hud(
      categorias: [
        for (var i = 0; i < linhas.length; i++)
          _categoria('c$i', planejado: linhas[i].p, realizado: linhas[i].a),
      ],
    ).village;

    test('o anel é Σ realizado ÷ Σ planejado', () {
      // O retrato real de setembro: R$ 14.912,20 de R$ 22.220,00.
      final vila = vilaDe([(p: 22220, a: 14912.20)]);

      expect(vila.ring, closeTo(0.6711, 0.0001));
    });

    test('a vila estourada enche o anel, sem passar dele', () {
      final vila = vilaDe([(p: 100, a: 250)]);

      expect(vila.ring, 1);
      expect(vila.progress, closeTo(2.5, 0.0001));
      expect(vila.isAlive, isFalse);
    });

    test('a soma é em centavos: doze de 0,10 fecham em 1,20', () {
      // Em `double` a soma dá 1.2000000000000002 e a vila morreria por ruído
      // de representação.
      final vila = vilaDe([for (var i = 0; i < 12; i++) (p: 0.10, a: 0.10)]);

      expect(vila.plannedTotal.cents, 120);
      expect(vila.actualTotal.cents, 120);
      expect(vila.isAlive, isTrue);
    });

    test('a vila exige três aldeões', () {
      // Com dois, "a soma coube na soma" é uma banalidade já paga pelos 15 de
      // cada aldeão.
      final dois = vilaDe([(p: 100, a: 10), (p: 100, a: 10)]);
      final tres = vilaDe([(p: 100, a: 10), (p: 100, a: 10), (p: 100, a: 10)]);

      expect(dois.isAlive, isFalse);
      expect(tres.isAlive, isTrue);
    });

    test('o aldeão de INVESTIMENTO funciona ao contrário', () {
      // Decisão do dono (2026-09-20): "as categorias que estiverem como
      // investimento funcionam ao contrário... se não cumprirem o limite é
      // que ficam em risco de morrer".
      //
      // O defeito que isto impede: com a regra da despesa, a categoria de
      // investimento com meta de R$ 200 e NADA aportado era o aldeão mais
      // saudável da vila — HP cheio por não ter recebido um centavo.
      final vila = _hud(
        categorias: [
          _categoria('Mercado', planejado: 1000, realizado: 400),
          _categoria('Lazer', planejado: 1000, realizado: 400),
          _categoria(
            'Investimentos',
            planejado: 200,
            realizado: 0,
            investimento: true,
          ),
        ],
      ).village;

      final investimento = vila.villagers.firstWhere(
        (v) => v.name == 'Investimentos',
      );

      expect(investimento.isInvestment, isTrue);
      expect(investimento.isAlive, isFalse);
      expect(investimento.isAtRisk, isTrue);
      // E NÃO caído: o mês não acabou, e ainda dá para aportar.
      expect(investimento.isFallen, isFalse);
      expect(investimento.missing.cents, 20000);
      // O anel ENCHE conforme se aporta, em vez de esvaziar.
      expect(investimento.hpRatio, 0);

      expect(vila.aliveCount, 2);
      expect(vila.atRiskCount, 1);
      expect(vila.fallenCount, 0);
    });

    test('o aldeão de investimento fica de pé quando bate a meta', () {
      final vila = _hud(
        categorias: [
          _categoria(
            'Investimentos',
            planejado: 200,
            realizado: 200,
            investimento: true,
          ),
          _categoria(
            'Previdência',
            planejado: 200,
            realizado: 250,
            investimento: true,
          ),
          _categoria(
            'Reserva',
            planejado: 200,
            realizado: 199.99,
            investimento: true,
          ),
        ],
      ).village;

      // Exatamente a meta JÁ é de pé — o alvo não é uma falha por um
      // centavo —, e um centavo abaixo ainda é risco.
      expect(vila.aliveCount, 2);
      expect(vila.atRiskCount, 1);
      expect(
        vila.villagers.firstWhere((v) => v.name == 'Reserva').missing.cents,
        1,
      );
    });

    test('o aporte não conta na soma que derruba a vila', () {
      // Se o investimento entrasse na soma, guardar dinheiro derrubaria a
      // vila — o contrário do que o jogo premia. A soma é só das despesas.
      final vila = _hud(
        categorias: [
          _categoria('Mercado', planejado: 1000, realizado: 400),
          _categoria('Lazer', planejado: 1000, realizado: 400),
          _categoria('Saúde', planejado: 1000, realizado: 400),
          _categoria(
            'Investimentos',
            planejado: 200,
            realizado: 5000,
            investimento: true,
          ),
        ],
      ).village;

      expect(vila.expenseActualTotal.cents, 120000);
      expect(vila.expensePlannedTotal.cents, 300000);
      expect(vila.isAlive, isTrue);
      expect(vila.progress, closeTo(0.4, 0.0001));
    });

    test('os caídos vêm antes dos em risco, e estes antes dos de pé', () {
      final vila = _hud(
        categorias: [
          _categoria('Folgado', planejado: 1000, realizado: 100),
          _categoria('Estourado', planejado: 100, realizado: 900),
          _categoria(
            'Investimentos',
            planejado: 200,
            realizado: 50,
            investimento: true,
          ),
        ],
      ).village;

      expect(vila.villagers.map((v) => v.name).toList(), [
        'Estourado',
        'Investimentos',
        'Folgado',
      ]);
    });

    test('o XP projetado paga 15 por aldeão vivo e 100 pela vila', () {
      final vila = vilaDe([(p: 100, a: 10), (p: 100, a: 10), (p: 100, a: 10)]);

      expect(vila.aliveCount, 3);
      expect(vila.projectedXp, 3 * 15 + 100);
    });

    test('o teto é de dez aldeões', () {
      // Sem o teto, o caminho mais curto para o XP seria fatiar o orçamento
      // em trinta categorias de R$ 10 e não gastar em nenhuma.
      final vila = vilaDe([for (var i = 0; i < 30; i++) (p: 10, a: 0)]);

      expect(vila.aliveCount, 30);
      expect(vila.projectedXp, 10 * 15 + 100);
    });

    test(
      'vila morta não paga os 100, mas os aldeões vivos continuam pagos',
      () {
        final vila = vilaDe([
          (p: 100, a: 10),
          (p: 100, a: 10),
          (p: 100, a: 900),
        ]);

        expect(vila.isAlive, isFalse);
        expect(vila.projectedXp, 2 * 15);
      },
    );

    test('o histórico vem do mês mais recente para o mais antigo', () {
      final vila = _hud(
        historico: const [
          HudMonthlyReport(
            monthKey: '2026-07',
            villagersPlanned: 12,
            villagersAlive: 12,
            villageAlive: true,
            xpAwarded: 250,
          ),
          HudMonthlyReport(
            monthKey: '2026-08',
            villagersPlanned: 17,
            villagersAlive: 9,
            villageAlive: false,
            xpAwarded: 135,
          ),
        ],
      ).village;

      expect(vila.history.map((h) => h.monthKey), ['2026-08', '2026-07']);
    });
  });

  group('a vila tem DOIS envelopes', () {
    // O contrato que o backend (wp/villagers-investment) fechou e o dono
    // aprovou: vila viva ⇔ despesas dentro do planejado E investimentos
    // acima do planejado. As duas metades do plano se medem em direções
    // opostas, e uma soma só não consegue medir as duas.

    test('sem categoria de investimento, degenera na regra antiga', () {
      // Nenhum cofre que não usa allocation de investimento muda de
      // comportamento: o envelope vazio está fechado por vacuidade.
      final dentro = _hud(
        categorias: [
          _categoria('Mercado', planejado: 1000, realizado: 400),
          _categoria('Lazer', planejado: 1000, realizado: 400),
          _categoria('Saúde', planejado: 1000, realizado: 400),
        ],
      ).village;
      final fora = _hud(
        categorias: [
          _categoria('Mercado', planejado: 1000, realizado: 4000),
          _categoria('Lazer', planejado: 1000, realizado: 400),
          _categoria('Saúde', planejado: 1000, realizado: 400),
        ],
      ).village;

      expect(dentro.hasInvestmentEnvelope, isFalse);
      expect(dentro.investmentEnvelopeMet, isTrue);
      expect(dentro.isAlive, isTrue);
      expect(fora.isAlive, isFalse);
      expect(fora.isFallen, isTrue);
    });

    test('aporte generoso NÃO paga estouro de despesa', () {
      // Com uma soma única, quem aportasse R$ 5.000 a mais compraria o
      // direito de estourar o mercado em R$ 5.000 e a vila diria que o mês
      // foi bom. São dois envelopes justamente para isso não acontecer.
      final vila = _hud(
        categorias: [
          _categoria('Mercado', planejado: 1000, realizado: 6000),
          _categoria('Lazer', planejado: 1000, realizado: 400),
          _categoria('Saúde', planejado: 1000, realizado: 400),
          _categoria(
            'Investimentos',
            planejado: 200,
            realizado: 5200,
            investimento: true,
          ),
        ],
      ).village;

      expect(vila.investmentEnvelopeMet, isTrue);
      expect(vila.expenseEnvelopeMet, isFalse);
      expect(vila.isAlive, isFalse);
      expect(vila.isFallen, isTrue);
      expect(vila.isAtRisk, isFalse);
    });

    test('o envelope de investimento sozinho derruba a vila', () {
      // Quem planejou aportar e não aportou não fechou o plano que
      // escreveu, ainda que não tenha gasto um centavo a mais.
      final vila = _hud(
        categorias: [
          _categoria('Mercado', planejado: 1000, realizado: 400),
          _categoria('Lazer', planejado: 1000, realizado: 400),
          _categoria('Saúde', planejado: 1000, realizado: 400),
          _categoria(
            'Investimentos',
            planejado: 200,
            realizado: 50,
            investimento: true,
          ),
        ],
      ).village;

      expect(vila.expenseEnvelopeMet, isTrue);
      expect(vila.investmentEnvelopeMet, isFalse);
      expect(vila.isAlive, isFalse);
      // No meio do mês isso é RISCO, e não queda: ainda dá para aportar.
      expect(vila.isAtRisk, isTrue);
      expect(vila.isFallen, isFalse);
      // E os 100 da vila não entram na projeção enquanto ela não fecha.
      expect(vila.projectedXp, 3 * 15);
    });

    test('o teto de dez e o mínimo de três não mudaram', () {
      final trinta = _hud(
        categorias: [
          for (var i = 0; i < 30; i++) _categoria('c$i', planejado: 10),
          _categoria(
            'Investimentos',
            planejado: 200,
            realizado: 200,
            investimento: true,
          ),
        ],
      ).village;
      final dois = _hud(
        categorias: [
          _categoria('Mercado', planejado: 1000, realizado: 400),
          _categoria(
            'Investimentos',
            planejado: 200,
            realizado: 200,
            investimento: true,
          ),
        ],
      ).village;

      expect(trinta.aliveCount, 31);
      expect(trinta.isAlive, isTrue);
      expect(trinta.projectedXp, 10 * 15 + 100);

      expect(dois.isAlive, isFalse);
      expect(dois.isAtRisk, isFalse);
      expect(dois.isFallen, isFalse);
    });

    test('exatamente o alvo JÁ fecha o envelope de aporte', () {
      final vila = _hud(
        categorias: [
          _categoria('Mercado', planejado: 1000, realizado: 400),
          _categoria('Lazer', planejado: 1000, realizado: 400),
          _categoria(
            'Investimentos',
            planejado: 200,
            realizado: 200,
            investimento: true,
          ),
        ],
      ).village;

      expect(vila.investmentActualTotal.cents, 20000);
      expect(vila.investmentPlannedTotal.cents, 20000);
      expect(vila.isAlive, isTrue);
    });
  });

  group('o ovo: as faturas por vir', () {
    test('a fatura VENCIDA vai para o topo da lista', () {
      // Ela continua entrando na soma — o contrato é Σ nextInvoice, e uma
      // fatura vencida e não paga é a mais devida de todas. O que ela ganha
      // é o LUGAR: a primeira linha da folha.
      final ovo = _hud(
        renda: _renda(),
        faturas: [
          _fatura('c6', 2406, nome: 'Cartão C6', diaVencimento: 10),
          HudInvoiceReading(
            accountId: 'nubank2',
            name: 'Cartão Nubank',
            amount: 8300.55,
            closingDate: DateTime(2026, 9, 10),
            dueDate: DateTime(2026, 9, 17),
            isOpenCycle: false,
            overdueDays: 3,
          ),
        ],
      ).egg;

      expect(ovo.invoices.first.name, 'Cartão Nubank');
      expect(ovo.invoices.first.isOverdue, isTrue);
      expect(ovo.invoices.first.overdueDays, 3);
      expect(ovo.total, Money.fromDouble(10706.55));
    });

    test('a razão é a soma das faturas sobre a receita prevista', () {
      // O retrato real: seis cartões somando R$ 20.187,80 contra R$ 18.550,00
      // — um mês inteiro de receita já comprometido com o cartão.
      final ovo = _hud(
        renda: _renda(),
        faturas: [
          _fatura(
            'samsclub',
            286.22,
            nome: 'Cartão Samsclub',
            diaVencimento: 12,
          ),
          _fatura('nubank1', 2717.10, nome: 'Cartão Nubank'),
          _fatura('inter', 3634.86, nome: 'Cartão Inter'),
          _fatura('itau', 2843.07, nome: 'Cartão Itaú'),
          _fatura('c6', 2406.00, nome: 'Cartão C6'),
          _fatura('nubank2', 8300.55, nome: 'Cartão Nubank', diaVencimento: 1),
        ],
      ).egg;

      expect(ovo.total, Money.fromDouble(20187.80));
      expect(ovo.ratio.value, closeTo(1.0883, 0.0001));
      expect(ovo.ratio.tier, HudTier.regular);
    });

    test('a razão em 1 enche o anel e põe o ovo no último estágio', () {
      final ovo = _hud(renda: _renda(), faturas: [_fatura('c', 18550)]).egg;

      expect(ovo.ratio.fill, 1);
      expect(ovo.stage, 2);
      expect(ovo.isTrembling, isTrue);
    });

    test('o ovo treme a partir de 0,8 — e não antes', () {
      final quase = _hud(
        renda: _renda(),
        faturas: [_fatura('c', 14839.99)],
      ).egg;
      final tremendo = _hud(
        renda: _renda(),
        faturas: [_fatura('c', 14840)],
      ).egg;

      expect(quase.isTrembling, isFalse, reason: '0,79999 ainda não treme');
      expect(tremendo.isTrembling, isTrue);
    });

    test('os três estágios da casca', () {
      int estagioDe(double valor) =>
          _hud(renda: _renda(), faturas: [_fatura('c', valor)]).egg.stage;

      expect(estagioDe(1000), 0);
      expect(estagioDe(9275), 1);
      expect(estagioDe(18550), 2);
    });

    test('as faturas vêm pelo vencimento mais próximo', () {
      final ovo = _hud(
        renda: _renda(),
        faturas: [
          _fatura('a', 100, nome: 'Depois', diaVencimento: 20),
          _fatura('b', 100, nome: 'Antes', diaVencimento: 3),
        ],
      ).egg;

      expect(ovo.invoices.map((i) => i.name), ['Antes', 'Depois']);
    });

    test('sem cartão não há ovo nenhum', () {
      final ovo = _hud(renda: _renda()).egg;

      expect(ovo.isEmpty, isTrue);
      expect(ovo.total, Money.zero);
      expect(ovo.stage, 0);
    });

    test('o ciclo ABERTO é marcado: o valor ainda sobe', () {
      final ovo = _hud(
        renda: _renda(),
        faturas: [_fatura('c', 286.22, aberta: true)],
      ).egg;

      expect(ovo.invoices.single.isOpenCycle, isTrue);
    });
  });

  group('a gota: o que você deve', () {
    test('sem dívida ela não pisca', () {
      final gota = _hud(renda: _renda()).drop;

      expect(gota.isBlinking, isFalse);
      expect(gota.total, Money.zero);
      expect(gota.ratio.tier, isNull);
      expect(gota.debts, isEmpty);
    });

    test('com dívida ela pisca, e o saldo devedor vira positivo', () {
      // O retrato real: Empréstimo Itaú, R$ 7.623,68 contra R$ 18.550,00.
      final gota = _hud(
        renda: _renda(),
        dividas: [_conta('itau', -7623.68, nome: 'Empréstimo Itaú')],
      ).drop;

      expect(gota.isBlinking, isTrue);
      expect(gota.total, Money.fromDouble(7623.68));
      expect(gota.ratio.value, closeTo(0.411, 0.001));
      expect(gota.ratio.tier, isNull);
    });

    test('conta de dívida quitada sai da lista', () {
      // Saldo zero ou positivo não deve nada, e uma linha "devo R$ 0,00" só
      // ocupa espaço.
      final gota = _hud(
        renda: _renda(),
        dividas: [_conta('quitada', 0), _conta('sobra', 120)],
      ).drop;

      expect(gota.debts, isEmpty);
      expect(gota.isBlinking, isFalse);
    });

    test('a próxima parcela entra na linha quando existe', () {
      final gota = _hud(
        renda: _renda(),
        dividas: [_conta('itau', -7623.68, nome: 'Empréstimo Itaú')],
        parcelas: {
          'itau': (
            amount: Money.fromDouble(648.18),
            dueDate: DateTime(2026, 10, 5),
          ),
        },
      ).drop;

      expect(gota.debts.single.installment, Money.fromDouble(648.18));
      expect(gota.debts.single.nextDueDate, DateTime(2026, 10, 5));
    });

    test('sem parcela agendada a linha mostra só o saldo devedor', () {
      final gota = _hud(
        renda: _renda(),
        dividas: [_conta('itau', -7623.68)],
      ).drop;

      expect(gota.debts.single.installment, isNull);
      expect(gota.debts.single.nextDueDate, isNull);
    });

    test('as dívidas vêm da maior para a menor', () {
      final gota = _hud(
        renda: _renda(),
        dividas: [
          _conta('a', -1000, nome: 'Pequena'),
          _conta('b', -50000, nome: 'Grande'),
        ],
      ).drop;

      expect(gota.debts.map((d) => d.name), ['Grande', 'Pequena']);
    });

    test('dois meses de receita devidos é uma gota hiper', () {
      final gota = _hud(renda: _renda(), dividas: [_conta('a', -37100)]).drop;

      expect(gota.ratio.tier, HudTier.hyper);
    });
  });

  group('o estado inteiro', () {
    test('carrega o mês e a origem da receita', () {
      final estado = _hud(renda: _renda(source: ExpectedIncomeSource.average));

      expect(estado.monthKey, '2026-09');
      expect(estado.hasIncome, isTrue);
      expect(estado.income!.source, ExpectedIncomeSource.average);
    });

    test('sem receita, o estado diz que não sabe', () {
      expect(_hud().hasIncome, isFalse);
      expect(_hud().income, isNull);
    });
  });
}
