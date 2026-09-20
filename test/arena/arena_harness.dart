import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/theme/app_theme.dart';
import 'package:funances/features/arena/domain/models/arena_state.dart';
import 'package:funances/features/arena/presentation/providers/arena_providers.dart';
import 'package:funances/features/arena/presentation/screens/arena_screen.dart';
import 'package:funances/features/auth/presentation/providers.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/user/domain/models/user_model.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

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
  amount: amount,
  description: description,
  dueDate: arenaTestDay.add(Duration(days: dayOffset)),
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
}) => ArenaCommitment(
  installment: arenaTestInstallment(
    id: id,
    description: description,
    amount: amount,
    dayOffset: dayOffset,
    status: paid ? InstallmentStatus.paid : InstallmentStatus.pending,
    paidDate: paid ? arenaTestDay : null,
  ),
  isPaid: paid,
  isOverdue: overdue,
  daysUntilDue: dayOffset,
);

/// Uma semana típica: dois heróis, caixa que começou em R$ 5.200 e está em
/// R$ 3.980, e R$ 1.380 de compromisso ainda de pé.
ArenaState arenaTestState({
  double initialBalance = 5200,
  double currentBalance = 3980,
  double commitmentsInitial = 1380,
  double commitmentsRemaining = 1380,
  double overdueAmount = 0,
  double healedThisWeek = 0,
  int extraMembers = 0,
  ArenaDay day = ArenaDay.wednesday,
  List<ArenaCommitment>? commitments,
  List<ArenaAccountLife>? accounts,
}) => ArenaState(
  weekId: '2026-W38',
  day: day,
  initialBalance: initialBalance,
  currentBalance: currentBalance,
  healedThisWeek: healedThisWeek,
  commitmentsInitial: commitmentsInitial,
  commitmentsRemaining: commitmentsRemaining,
  overdueAmount: overdueAmount,
  monsterSkin: MonsterSkin.spider,
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
  commitments:
      commitments ??
      [
        arenaTestCommitment(),
        arenaTestCommitment(
          id: 'luz',
          description: 'Luz',
          amount: 180,
          dayOffset: 2,
        ),
      ],
);

/// A Arena dentro de um router de verdade, para os toques terem para onde ir.
Widget arenaApp(
  ArenaState state, {
  ThemeData? theme,
  bool reduceMotion = false,
  bool isBusiness = false,
  Widget? home,
}) => ProviderScope(
  overrides: [
    ArenaViewProviders.state.overrideWith(
      (ref) => AsyncValue<ArenaState>.data(state),
    ),
    ArenaViewProviders.isBusiness.overrideWith((ref) => isBusiness),
    AuthDomainProviders.currentUser.overrideWith((ref) => arenaTestUser),
  ],
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
      initialLocation: '/arena',
      routes: [
        GoRoute(path: '/', builder: (_, _) => home ?? const _Marker('home')),
        GoRoute(path: arenaRoutePath, builder: (_, _) => const ArenaScreen()),
        GoRoute(
          path: '/accounts/:id/statement',
          builder: (_, _) => const _Marker('extrato'),
        ),
      ],
    ),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
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
