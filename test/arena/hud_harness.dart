import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/money/money.dart';
import 'package:funances/core/theme/app_theme.dart';
import 'package:funances/features/arena/domain/models/hud_state.dart';
import 'package:funances/features/arena/domain/services/hud_calculator.dart';
import 'package:funances/features/arena/presentation/providers/arena_providers.dart';
import 'package:funances/features/arena/presentation/providers/hud_intro_store.dart';
import 'package:funances/features/arena/presentation/providers/hud_providers.dart';
import 'package:funances/features/arena/presentation/widgets/arena_hud_footer.dart';
import 'package:funances/features/arena/presentation/widgets/hud_explanation.dart';
import 'package:funances/features/arena/presentation/widgets/hud_glyph.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'arena_harness.dart';

/// O rodapé mensal montado num teste, com o estado já calculado.
///
/// Os números padrão são os do cofre REAL do dono em setembro de 2026
/// (workspace 42d43a0e). Um harness com números redondos inventados esconde
/// justamente o que este pacote precisa provar: que quatro ícones de 30 px e
/// os rótulos deles cabem ao lado de "R$ 20.187,80" e "9/16".

/// O dia em que o retrato foi tirado: 20 de setembro de 2026.
///
/// Ele importa porque uma das seis faturas já VENCEU — a do Nubank, em 17/09
/// —, e "vencida" é uma afirmação sobre hoje.
final DateTime hudTestToday = DateTime(2026, 9, 20);

/// R$ 18.550,00 — salário de R$ 17.000 mais R$ 1.550 de benefícios,
/// agendados no mês, no retrato da manhã de 20/09.
///
/// DEFASADO de propósito: às 12:37 do mesmo dia o servidor republicou
/// `expectedIncome` como R$ 18.000,00 (planned). As três razões não mudam
/// de dígito (< 0,1× · 1,1× · 0,4×), mas o valor aparece literal nas
/// folhas e em goldens; a atualização fica para o próximo retrato mensal
/// (ver README, "HUD mensal da Arena").
final ExpectedIncome hudTestIncome = ExpectedIncome(
  monthKey: '2026-09',
  amount: Money.fromCents(1855000),
  source: ExpectedIncomeSource.planned,
);

/// As seis faturas reais, somando R$ 20.187,80.
///
/// A do Nubank de R$ 8.300,55 é a única de ciclo FECHADO: ela venceu em
/// 17/09 e continua pendente. As outras cinco ainda estão acumulando.
///
/// O LIMITE e o saldo usado de cada cartão vêm junto desde que a folha dos
/// incubados passou a desenhar a progressão de uso, e os seis são os REAIS
/// do cofre do dono em 20/09/2026 — limite cadastrado na conta e saldo do
/// dia em módulo. Nenhum deles está estourado, e nenhum está sem limite: o
/// cartão sem limite e o cartão furado são casos SINTÉTICOS, e vivem em
/// [hudInvoiceSemLimite] e [hudInvoiceEstourado], declarados como tais.
///
/// A razão de não inventar: um harness que se apresenta como o retrato do
/// cofre real e serve números redondos vira a fonte de um número errado no
/// README — foi o que aconteceu com o C6, que "tinha limite zero" aqui e
/// tem R\$ 9.217,00 lá fora.
List<HudInvoiceReading> hudTestInvoices() => [
  _invoice(
    'samsclub',
    'Cartão Samsclub',
    286.22,
    closing: 10,
    due: 12,
    limit: 7300,
    used: 286.26,
  ),
  _invoice(
    'nubank1',
    'Cartão Nubank G98Y',
    2717.10,
    closing: 4,
    due: 10,
    limit: 10350,
    used: 2553.99,
  ),
  _invoice(
    'inter',
    'Cartão Inter',
    3634.86,
    closing: 4,
    due: 10,
    limit: 17900,
    used: 1592.84,
  ),
  _invoice(
    'itau',
    'Cartão Itaú',
    2843.07,
    closing: 4,
    due: 10,
    limit: 8000,
    used: 3114.33,
  ),
  _invoice(
    'c6',
    'Cartão C6',
    2406.00,
    closing: 4,
    due: 10,
    limit: 9217,
    used: 3480.98,
  ),
  HudInvoiceReading(
    accountId: 'nubank2',
    name: 'Cartão Nubank VgIy',
    amount: 8300.55,
    closingDate: DateTime(2026, 9, 10),
    dueDate: DateTime(2026, 9, 17),
    isOpenCycle: false,
    color: '#8A05BE',
    installmentId: 'inst-nubank2',
    overdueDays: 3,
    limit: 21000,
    usedLimit: 4854.39,
  ),
];

/// Um cartão SINTÉTICO sem limite cadastrado.
///
/// Ele não é de ninguém: `accounts.limit` nasce zero quando o usuário não o
/// preenche, e o caso existe: é o que a folha tem de responder com "limite
/// não informado" em vez de desenhar 0%. Fica fora de [hudTestInvoices]
/// porque os seis de lá são reais e todos têm limite.
HudInvoiceReading hudInvoiceSemLimite() => _invoice(
  'sintetico-sem-limite',
  'Cartão sem limite',
  500,
  closing: 4,
  due: 10,
);

/// Um cartão SINTÉTICO já estourado: R\$ 812,00 acima do limite.
///
/// Também não é de ninguém — nenhum dos seis cartões do dono passou do teto
/// em setembro —, e o caso é justamente o que o par "100% · R\$ 0,00" escondia.
HudInvoiceReading hudInvoiceEstourado() => _invoice(
  'sintetico-estourado',
  'Cartão estourado',
  1200,
  closing: 4,
  due: 10,
  limit: 9000,
  used: 9812,
);

HudInvoiceReading _invoice(
  String id,
  String name,
  double amount, {
  required int closing,
  required int due,
  double limit = 0,
  double used = 0,
}) => HudInvoiceReading(
  accountId: id,
  name: name,
  amount: amount,
  closingDate: DateTime(2026, 10, closing),
  dueDate: DateTime(2026, 10, due),
  isOpenCycle: true,
  color: '#8A05BE',
  installmentId: 'inst-$id',
  limit: limit,
  usedLimit: used,
);

/// As categorias reais de setembro, lidas de produção em 20/09/2026: DEZESSEIS
/// aldeões — nove de pé e sete caídos — e seis categorias sem proteção.
///
/// **As duas `virtual_*` NÃO estão aqui, e é o ponto.** No cofre do dono elas
/// se chamam "Empréstimo/Dívidas" (`virtual_debt_expense`, R$ 3.800 de alvo) e
/// "Investimentos" (`virtual_investment_expense`, R$ 200) — as duas com
/// allocation `investment` e nenhum aporte. Elas são categorias de SISTEMA: o
/// servidor as peneira por id, e o app passou a peneirar igual. Enquanto ele
/// olhava só a flag `isSystem` — que em workspace legado não existe em
/// documento nenhum —, as duas entravam como aldeãs, matavam o envelope de
/// investimento sozinhas e o app dizia "9/18, vila em risco, +135 XP" onde o
/// servidor pagava "9/16, vila viva, 235 XP".
///
/// "Taxas de Juros" é a única categoria de investimento de verdade do mês:
/// alvo de R$ 50 com R$ 431,54 realizados — de pé, e o envelope de
/// investimento fecha com ela.
///
/// As duas linhas do sumário SEM documento de categoria (R$ 3.800 e R$ 2.000,
/// de categorias apagadas) também ficam de fora, como no app: id que o app não
/// conhece não vira aldeão.
List<HudCategoryReading> hudTestCategories() => [
  _category('Supermercado', 3500, 2597.99),
  _category('Educação', 2770, 3301.54),
  _category('Empregada', 2650, 1728.24),
  _category('Cuidados pessoais', 1500, 1707.18),
  _category('Compras', 1300, 2163.89),
  _category('Lazer', 1200, 801.17),
  _category('Saúde', 1000, 1160.11),
  _category('Alimentação', 1000, 1065.85),
  _category('Gasolina', 1000, 525.54),
  _category('Moradia', 500, 106.24),
  _category('Festas', 500, 0),
  _category('Pets', 400, 284.29),
  _category('Manutenção do carro', 350, 1462.85),
  _category('Outros', 300, 135.87),
  _category('Transporte', 200, 293.97),
  _category('Taxas de Juros', 50, 431.54, investimento: true),
  _category('Pagamento de Empréstimo', 0, 1944.54, investimento: true),
  _category('Seguros', 0, 828.11),
  _category('Assinaturas', 0, 665.02),
  _category('Água', 0, 437.82),
  _category('Celular', 0, 435.00),
  _category('Internet/TV', 0, 167.90),
];

HudCategoryReading _category(
  String name,
  double planned,
  double actual, {
  bool investimento = false,
}) => HudCategoryReading(
  categoryId: 'cat-$name',
  name: name,
  icon: 'shopping_cart',
  color: '#FF5722',
  isExpense: true,
  isSystem: false,
  planned: planned,
  actual: actual,
  isInvestment: investimento,
);

/// O retrato do mês fechado, como o servidor o gravou.
const HudMonthlyReport hudTestReport = HudMonthlyReport(
  monthKey: '2026-08',
  villagersPlanned: 17,
  villagersAlive: 9,
  villageAlive: false,
  xpAwarded: 135,
);

/// O HUD do cofre real, com cada peça substituível.
HudState hudTestState({
  ExpectedIncome? income = _sentinel,
  List<HudBalanceReading>? investments,
  List<HudBalanceReading>? debts,
  List<HudInvoiceReading>? invoices,
  List<HudCategoryReading>? categories,
  List<HudMonthlyReport>? history,
}) {
  return HudCalculator.from(
    HudInputs(
      monthKey: '2026-09',
      income: identical(income, _sentinel) ? hudTestIncome : income,
      investments:
          investments ??
          const [
            HudBalanceReading(
              accountId: 'cofrinho',
              name: 'Cofrinho Disney',
              balance: 263.41,
              color: '#2E7D32',
            ),
          ],
      debts:
          debts ??
          const [
            HudBalanceReading(
              accountId: 'itau',
              name: 'Empréstimo Itaú',
              balance: -7623.68,
              color: '#EC7000',
            ),
          ],
      invoices: invoices ?? hudTestInvoices(),
      categories: categories ?? hudTestCategories(),
      history: history ?? const [hudTestReport],
      // A parcela REAL do empréstimo Itaú: R$ 3.811,78 em 22/09. O harness se
      // apresenta como o retrato do cofre do dono, e um número inventado
      // aqui é uma mentira que os goldens fotografam.
      debtInstallments: {
        'itau': (
          amount: Money.fromDouble(3811.78),
          dueDate: DateTime(2026, 9, 22),
        ),
      },
    ),
  );
}

/// Marcador de "não passaram nada" que aceita `null` como valor legítimo —
/// e `null` aqui é o caso mais importante: a receita que o servidor ainda
/// não publicou.
const ExpectedIncome _sentinel = ExpectedIncome(
  monthKey: '',
  amount: Money.zero,
  source: ExpectedIncomeSource.planned,
);

/// A faixa sozinha, dentro de um router de verdade.
Widget hudFooterApp(
  HudState hud, {
  ThemeData? theme,
  bool compact = true,
  bool isBusiness = false,
  bool reduceMotion = false,
  AsyncValue<HudState>? asyncState,
  Color? background,
}) => ProviderScope(
  overrides: [
    HudViewProviders.state.overrideWith(
      (ref) => asyncState ?? AsyncValue<HudState>.data(hud),
    ),
    ArenaViewProviders.isBusiness.overrideWith((ref) => isBusiness),
  ],
  child: MaterialApp.router(
    debugShowCheckedModeBanner: false,
    theme: theme ?? AppTheme.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: child!,
    ),
    routerConfig: GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            // A faixa NÃO tem fundo próprio: ela é transparente e mora sobre
            // a superfície de jogo da cena. Quem a fotografa sozinha precisa
            // dizer o que há atrás dela, senão o golden mostra tinta clara
            // sobre papel branco e os rótulos somem.
            backgroundColor: background,
            // A faixa vive no PÉ da cena, e é lá que ela precisa caber.
            body: Align(
              alignment: Alignment.bottomCenter,
              child: ArenaHudFooter(
                height: compact ? 56 : 64,
                compact: compact,
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/planning',
          builder: (_, _) => const HudMarker('planejamento'),
        ),
        GoRoute(
          path: '/workspace/accounts',
          builder: (_, _) => const HudMarker('contas'),
        ),
        GoRoute(
          path: '/accounts/:id/statement',
          builder: (_, _) => const HudMarker('extrato'),
        ),
        GoRoute(
          path: '/invoices/:id',
          builder: (_, _) => const HudMarker('fatura'),
        ),
        GoRoute(
          path: '/category-details',
          builder: (_, _) => const HudMarker('categorias'),
        ),
      ],
    ),
    localizationsDelegates: arenaLocalizationDelegates,
    supportedLocales: arenaSupportedLocales,
    locale: const Locale('pt'),
  ),
);

class HudMarker extends StatelessWidget {
  const HudMarker(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(label)));
}

/// Monta a faixa num tamanho dado.
///
/// [introSeen] decide se as quatro explicações já foram lidas NESTE aparelho.
/// O padrão é `true`, e ele é o estado do usuário de todo dia: a folha abre
/// com os dados e nada mais. Quem testa a apresentação automática — e só ele
/// — passa `false`.
Future<void> pumpHudFooter(
  WidgetTester tester, {
  HudState? hud,
  Size size = const Size(400, 800),
  ThemeData? theme,
  bool compact = true,
  bool isBusiness = false,
  bool reduceMotion = true,
  bool introSeen = true,
  AsyncValue<HudState>? asyncState,
  Color? background,
}) async {
  SharedPreferences.setMockInitialValues({
    if (introSeen)
      for (final slot in HudSlot.values) HudIntroStore.keyFor(slot): true,
  });

  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    hudFooterApp(
      hud ?? hudTestState(),
      theme: theme,
      compact: compact,
      isBusiness: isBusiness,
      reduceMotion: reduceMotion,
      asyncState: asyncState,
      background: background,
    ),
  );

  // Com movimento LIGADO não dá para "assentar": a gota pisca e o ovo treme
  // em ciclo, e `pumpAndSettle` espera por um repouso que nunca chega. Dois
  // quadros bastam para a faixa existir.
  if (reduceMotion) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// Abre a folha de um slot da faixa e espera o que vem depois dela.
///
/// Os dois `pumpAndSettle` não são superstição: entre o toque e o painel de
/// apresentação há uma ida ao disco (o `SharedPreferences`), e uma leitura
/// assíncrona não agenda quadro nenhum — o primeiro `pumpAndSettle` volta
/// antes de a resposta chegar, e o segundo é o que desenha o que ela abriu.
Future<void> openHudSheet(WidgetTester tester, int index) async {
  await tester.tap(find.byType(HudGlyph).at(index));
  await tester.pumpAndSettle();
  await tester.pumpAndSettle();
}

/// Abre a explicação pelo ícone de informação do cabeçalho da folha.
Future<void> openHudExplanation(WidgetTester tester) async {
  await tester.tap(find.byType(HudExplanationButton));
  await tester.pumpAndSettle();
}
