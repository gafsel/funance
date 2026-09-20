import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

final DateTime arenaTestDay = DateTime(2026, 9, 21, 10);

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
}) => InstallmentModel(
  id: id,
  orderId: 'o-$id',
  amount: amount,
  description: description,
  dueDate: arenaTestDay.add(Duration(days: dayOffset)),
  status: InstallmentStatus.pending,
  type: OrderType.expense,
  installmentType: InstallmentType.single,
);

/// Uma semana típica: dois heróis, caixa de R$ 5.000, duas parcelas e um
/// orçamento de R$ 550.
ArenaState arenaTestState({
  double liquidBalance = 5000,
  double installmentsInitial = 1380,
  double installmentsRemaining = 1380,
  double budgetInitial = 550,
  double budgetRemaining = 550,
  double overdueAmount = 0,
  double healedThisWeek = 0,
  double damageThisWeek = 0,
  double? invoiceAmount,
  int extraMembers = 0,
  List<InstallmentModel>? pending,
}) => ArenaState(
  weekId: '2026-W38',
  liquidBalance: liquidBalance,
  healedThisWeek: healedThisWeek,
  damageThisWeek: damageThisWeek,
  installmentsInitial: installmentsInitial,
  installmentsRemaining: installmentsRemaining,
  budgetInitial: budgetInitial,
  budgetRemaining: budgetRemaining,
  overdueAmount: overdueAmount,
  monsterSkin: MonsterSkin.spider,
  invoiceAmount: invoiceAmount,
  invoiceInstallmentId: invoiceAmount == null ? null : 'inv-1',
  extraMembers: extraMembers,
  heroes: const [
    ArenaHero(userId: 'u1', name: 'Gabriel', skin: HeroSkin.knight),
    ArenaHero(userId: 'u2', name: 'Ana', skin: HeroSkin.mage),
  ],
  pendingInstallments:
      pending ??
      [
        arenaTestInstallment(),
        arenaTestInstallment(
          id: 'luz',
          description: 'Luz',
          amount: 180,
          dayOffset: 3,
        ),
      ],
);

/// A Arena dentro de um router de verdade, para os toques terem para onde ir.
Widget arenaApp(
  ArenaState state, {
  ThemeData? theme,
  bool reduceMotion = false,
}) => ProviderScope(
  overrides: [
    ArenaViewProviders.state.overrideWith(
      (ref) => AsyncValue<ArenaState>.data(state),
    ),
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
        GoRoute(path: '/', builder: (_, _) => const _Marker('home')),
        GoRoute(path: arenaRoutePath, builder: (_, _) => const ArenaScreen()),
        GoRoute(path: '/planning', builder: (_, _) => const _Marker('plano')),
        GoRoute(
          path: '/invoices/:id',
          builder: (_, _) => const _Marker('fatura'),
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
