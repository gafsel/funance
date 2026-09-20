import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/theme/app_theme.dart';
import 'package:funances/features/arena/domain/models/arena_state.dart';
import 'package:funances/features/arena/presentation/providers/arena_providers.dart';
import 'package:funances/features/arena/presentation/widgets/arena_view.dart';
import 'package:funances/features/home/presentation/widgets/arena_tab.dart';
import 'package:funances/features/coaching/domain/models/coaching_model.dart';
import 'package:funances/features/finance/domain/models/automatic_transaction_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/home/domain/models/financial_health_model.dart';
import 'package:funances/features/home/domain/models/weekly_mission_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/user/domain/models/user_model.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../support/home_harness.dart';

/// Monta a Arena num teste, com o estado já calculado.
///
/// Nada de Firebase: o `ArenaViewProviders.state` é substituído por um
/// [ArenaState] pronto. É a vantagem de a conta viver fora da tela — o teste
/// de cena não precisa reencenar o Firestore para provar que a cena monta.

final DateTime arenaTestDay = DateTime(2026, 9, 23, 10);

final UserModel arenaTestUser = UserModel(
  id: 'u1',
  email: 'gafsel@funances.test',
  displayName: 'Gabriel Silva',
  createdAt: arenaTestDay,
);

InstallmentModel arenaTestInstallment({
  String id = 'aluguel',
  String description = 'Aluguel',
  double amount = 1200,
  int dayOffset = 0,
  InstallmentStatus status = InstallmentStatus.pending,
  DateTime? paidDate,
}) => InstallmentModel(
  id: id,
  orderId: 'o-$id',
  description: description,
  dueDate: arenaTestDay.add(Duration(days: dayOffset)),
  // O app ZERA o `amount` na quitação e move o valor para `paidAmount`. O
  // dublê imita isso: sem essa fidelidade, um teste que somasse `amount`
  // passaria aqui e falharia no aparelho.
  amount: status == InstallmentStatus.pending ? amount : 0,
  paidAmount: status == InstallmentStatus.pending ? null : amount,
  paidDate: paidDate,
  status: status,
  type: OrderType.expense,
  installmentType: InstallmentType.single,
);

ArenaCommitment arenaTestCommitment({
  String id = 'aluguel',
  String description = 'Aluguel',
  double amount = 1200,
  int dayOffset = 0,
  bool paid = false,
  bool overdue = false,
  bool scheduled = false,

  /// Quitação PARCIAL: o quanto foi pago de um compromisso que continua de
  /// pé. É a forma da fatura — o `amount` sobrevive à quitação.
  double? partial,
}) => ArenaCommitment(
  installment: partial != null
      ? InstallmentModel(
          id: id,
          orderId: 'o-$id',
          amount: amount,
          paidAmount: partial,
          paidDate: arenaTestDay,
          description: description,
          dueDate: arenaTestDay.add(Duration(days: dayOffset)),
          status: InstallmentStatus.paid,
          type: OrderType.transfer,
          installmentType: InstallmentType.single,
          isInvoice: true,
        )
      : arenaTestInstallment(
          id: id,
          description: description,
          amount: amount,
          dayOffset: dayOffset,
          status: paid || scheduled
              ? InstallmentStatus.paid
              : InstallmentStatus.pending,
          paidDate: scheduled
              ? arenaTestDay.add(const Duration(days: 2))
              : paid
              ? arenaTestDay
              : null,
        ),
  isPaid: partial != null || paid || scheduled,
  isOverdue: overdue,
  isScheduledStrike: scheduled,
  daysUntilDue: dayOffset,
);

/// Uma semana típica: dois heróis, caixa que começou em R$ 5.200 e está em
/// R$ 3.980, e R$ 1.380 de compromisso ainda de pé.
///
/// Os totais do monstro são DERIVADOS da lista de compromissos, e não
/// passados à parte. O QA pegou o harness antigo montando estados
/// impossíveis — cabeçalho dizendo "R$ 1.320 pagos de R$ 2.140" com uma lista
/// que somava outra coisa —, e um golden desses fotografa uma tela que o app
/// nunca mostra. Aqui, mentir exige mexer na lista.
ArenaState arenaTestState({
  double initialBalance = 5200,
  double currentBalance = 3980,
  double healedThisWeek = 0,
  int extraMembers = 0,
  ArenaDay day = ArenaDay.wednesday,
  List<ArenaCommitment>? commitments,
  List<ArenaAccountLife>? accounts,
}) {
  final lista =
      commitments ??
      [
        arenaTestCommitment(),
        arenaTestCommitment(
          id: 'luz',
          description: 'Luz',
          amount: 180,
          dayOffset: 2,
        ),
      ];

  // A MESMA aritmética da calculadora: o inicial é o plano de cada linha, o
  // que falta é a soma dos restos. Escrever outra conta aqui seria montar
  // estados que o app não produz — e foi assim que um golden fotografou um
  // cabeçalho que não batia com a lista embaixo dele.
  double soma(
    double Function(ArenaCommitment) campo, [
    bool Function(ArenaCommitment)? onde,
  ]) => lista
      .where(onde ?? (_) => true)
      .fold<double>(0, (total, c) => total + campo(c));

  return ArenaState(
    weekId: '2026-W38',
    day: day,
    initialBalance: initialBalance,
    currentBalance: currentBalance,
    healedThisWeek: healedThisWeek,
    commitments: lista,
    commitmentsInitial: soma((c) => c.planned),
    commitmentsRemaining: soma((c) => c.remaining),
    overdueAmount: soma((c) => c.remaining, (c) => c.isOverdue),
    monsterSkin: lista.any((c) => c.isOverdue)
        ? MonsterSkin.demon
        : MonsterSkin.spider,
    extraMembers: extraMembers,
    heroes: const [
      ArenaHero(userId: 'u1', name: 'Gabriel', skin: HeroSkin.knight),
      ArenaHero(userId: 'u2', name: 'Ana', skin: HeroSkin.mage),
    ],
    accounts:
        accounts ??
        const [
          ArenaAccountLife(
            accountId: 'c1',
            name: 'Nubank',
            initial: 4200,
            current: 3100,
          ),
          ArenaAccountLife(
            accountId: 'inv',
            name: 'Tesouro',
            initial: 1000,
            current: 880,
          ),
        ],
  );
}

/// As delegates e locales que todo host de teste da Arena usa.
const List<LocalizationsDelegate<Object>> arenaLocalizationDelegates =
    <LocalizationsDelegate<Object>>[
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];

List<Locale> get arenaSupportedLocales => AppLocalizations.supportedLocales;

/// Os dublês de uma Arena montada: os da Home mais o estado da cena.
///
/// Os quatro ícones da lateral leem providers que eram de outros blocos —
/// missões, Bússola, coach e pendências —, e é por isso que um teste da cena
/// precisa de tudo o que a Home precisava.
List<Override> arenaOverrides({
  ArenaState? state,
  bool isBusiness = false,
  List<WeeklyMissionModel> missions = const [],
  List<AutomaticTransactionModel> pendingAutomatic = const [],
  FinancialHealth? health,
  CoachingModel? lastInsight,
  List<Override> extra = const [],
}) => homeOverrides(
  currentUser: arenaTestUser,
  missions: missions,
  pendingAutomatic: pendingAutomatic,
  health: health,
  lastInsight: lastInsight,
  extra: [
    ArenaViewProviders.state.overrideWith(
      (ref) => AsyncValue<ArenaState>.data(state ?? arenaTestState()),
    ),
    ArenaViewProviders.isBusiness.overrideWith((ref) => isBusiness),
    ...extra,
  ],
);

/// A Arena dentro de um router de verdade, para os toques terem para onde ir.
///
/// Os dublês vêm de `homeOverrides`, e não de uma lista própria: desde que a
/// Arena virou a Home inteira, a cena carrega os ícones das missões, da
/// Bússola, do coach e das pendências — quatro providers que antes eram de
/// outros blocos. Duas listas de dublê para a mesma tela divergiriam na
/// primeira vez que alguém acrescentasse um ícone.
Widget arenaApp(
  ArenaState state, {
  ThemeData? theme,
  bool reduceMotion = false,
  bool isBusiness = false,
  List<Override>? overrides,
}) => ProviderScope(
  overrides:
      overrides ?? arenaOverrides(state: state, isBusiness: isBusiness),
  child: MaterialApp.router(
    debugShowCheckedModeBanner: false,
    theme: theme ?? AppTheme.light,
    // "Reduzir movimento" do sistema. A Arena inteira consulta isto — e é o
    // único jeito de um teste provar que ela consulta.
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: child!,
    ),
    routerConfig: GoRouter(
      initialLocation: '/',
      routes: [
        // A Arena É a raiz: a primeira aba da Home. A rota `/arena` continua
        // existindo e redireciona para cá — exatamente como no router do app.
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: ArenaTab()),
        ),
        GoRoute(path: arenaRoutePath, redirect: (_, _) => '/'),
        GoRoute(
          path: '/accounts/:id/statement',
          builder: (_, _) => const _Marker('extrato'),
        ),
        GoRoute(
          path: '/transactions/form',
          builder: (_, _) => const _Marker('editar lançamento'),
        ),
        GoRoute(
          path: '/automatic-transactions',
          builder: (_, _) => const _Marker('triagem'),
        ),
        GoRoute(path: '/missions', builder: (_, _) => const _Marker('semana')),
        GoRoute(path: '/coaching', builder: (_, _) => const _Marker('coach')),
      ],
    ),
    localizationsDelegates: arenaLocalizationDelegates,
    supportedLocales: arenaSupportedLocales,
    locale: const Locale('pt'),
  ),
);

class _Marker extends StatelessWidget {
  const _Marker(this.label);

  final String label;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(label)));
}

/// Monta a Arena e deixa a folha de sprites carregar.
///
/// O `runAsync` não é detalhe: o `decodeImageFromList` do Flame depende do
/// relógio de verdade, e o relógio falso do `flutter_test` nunca entrega o
/// resultado do codec. Sem ele o `onLoad` fica pendente para sempre, a cena
/// não monta e o teste falha por um motivo que não é o dele.
Future<void> pumpArena(
  WidgetTester tester, {
  ArenaState? state,
  Size size = const Size(400, 800),
  ThemeData? theme,
  bool reduceMotion = false,
  bool isBusiness = false,
  List<Override>? overrides,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.runAsync(() async {
    await tester.pumpWidget(
      arenaApp(
        state ?? arenaTestState(),
        theme: theme,
        reduceMotion: reduceMotion,
        isBusiness: isBusiness,
        overrides: overrides,
      ),
    );

    for (var i = 0; i < 12; i++) {
      await tester.pump(Duration.zero);
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
  });

  await arenaFrames(tester);
}

Future<void> arenaFrames(WidgetTester tester, {int count = 8}) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}
