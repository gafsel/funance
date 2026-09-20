import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/money/money.dart';
import 'package:funances/core/theme/app_theme.dart';
import 'package:funances/features/arena/domain/models/hud_state.dart';
import 'package:funances/features/arena/domain/services/hud_calculator.dart';
import 'package:funances/features/arena/presentation/providers/arena_providers.dart';
import 'package:funances/features/arena/presentation/providers/hud_providers.dart';
import 'package:funances/features/arena/presentation/widgets/arena_hud_footer.dart';
import 'package:go_router/go_router.dart';

import 'arena_harness.dart';

/// O rodapé mensal montado num teste, com o estado já calculado.
///
/// Os números padrão são os do cofre REAL do dono em setembro de 2026
/// (workspace 42d43a0e). Um harness com números redondos inventados esconde
/// justamente o que este pacote precisa provar: que quatro ícones de 30 px e
/// os rótulos deles cabem ao lado de "R$ 20.187,80" e "13/18".

/// R$ 18.550,00 — salário de R$ 17.000 mais R$ 1.550 de benefícios,
/// agendados no mês.
final ExpectedIncome hudTestIncome = ExpectedIncome(
  monthKey: '2026-09',
  amount: Money.fromCents(1855000),
  source: ExpectedIncomeSource.planned,
);

/// As seis faturas reais, somando R$ 20.187,80.
List<HudInvoiceReading> hudTestInvoices() => [
  _invoice('samsclub', 'Cartão Samsclub', 286.22, due: 12),
  _invoice('nubank1', 'Cartão Nubank', 2717.10, due: 10),
  _invoice('inter', 'Cartão Inter', 3634.86, due: 10),
  _invoice('itau', 'Cartão Itaú', 2843.07, due: 10),
  _invoice('c6', 'Cartão C6', 2406.00, due: 10),
  _invoice('nubank2', 'Cartão Nubank', 8300.55, due: 1, open: false),
];

HudInvoiceReading _invoice(
  String id,
  String name,
  double amount, {
  required int due,
  bool open = true,
}) => HudInvoiceReading(
  accountId: id,
  name: name,
  amount: amount,
  closingDate: DateTime(2026, 10, 4),
  dueDate: DateTime(2026, 10, due),
  isOpenCycle: open,
  color: '#8A05BE',
  installmentId: 'inst-$id',
);

/// As categorias reais de setembro: dezoito aldeões, cinco caídos, cinco sem
/// proteção.
List<HudCategoryReading> hudTestCategories() => [
  _category('Supermercado', 3500, 1158.20),
  _category('Educação', 2770, 3301.54),
  _category('Empregada', 2650, 1728.24),
  _category('Empréstimo/Dívidas', 3800, 0),
  _category('Cuidados pessoais', 1500, 1171.20),
  _category('Compras', 1300, 1993.97),
  _category('Lazer', 1200, 801.17),
  _category('Saúde', 1000, 1160.11),
  _category('Alimentação', 1000, 839.40),
  _category('Gasolina', 1000, 259.54),
  _category('Moradia', 500, 106.24),
  _category('Festas', 500, 0),
  _category('Pets', 400, 284.29),
  _category('Manutenção do carro', 350, 1462.77),
  _category('Outros', 300, 103.87),
  _category('Transporte', 200, 113.97),
  _category('Investimentos', 200, 0),
  _category('Taxas de Juros', 50, 427.69),
  _category('Pagamento de Empréstimo', 0, 1944.54),
  _category('Assinaturas', 0, 495.25),
  _category('Água', 0, 437.82),
  _category('Celular', 0, 435.00),
  _category('Internet/TV', 0, 167.90),
];

HudCategoryReading _category(String name, double planned, double actual) =>
    HudCategoryReading(
      categoryId: 'cat-$name',
      name: name,
      icon: 'shopping_cart',
      color: '#FF5722',
      isExpense: true,
      isSystem: false,
      planned: planned,
      actual: actual,
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
      debtInstallments: {
        'itau': (
          amount: Money.fromDouble(648.18),
          dueDate: DateTime(2026, 10, 5),
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
Future<void> pumpHudFooter(
  WidgetTester tester, {
  HudState? hud,
  Size size = const Size(400, 800),
  ThemeData? theme,
  bool compact = true,
  bool isBusiness = false,
  bool reduceMotion = true,
  AsyncValue<HudState>? asyncState,
}) async {
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
