import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/model/core_models.dart';
import 'package:funances/core/theme/app_theme.dart';
import 'package:funances/core/time/clock.dart';
import 'package:funances/features/auth/presentation/providers.dart';
import 'package:funances/features/coaching/domain/models/coaching_model.dart';
import 'package:funances/features/coaching/domain/repositories/coaching_repository.dart';
import 'package:funances/features/coaching/presentation/providers.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/automatic_transaction_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/repositories/account_repository.dart';
import 'package:funances/features/finance/domain/repositories/automatic_transaction_repository.dart';
import 'package:funances/features/finance/domain/repositories/finance_repository.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/goal/domain/models/goal_model.dart';
import 'package:funances/features/goal/domain/repositories/goal_repository.dart';
import 'package:funances/features/goal/presentation/provider.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:funances/features/workspace/domain/repositories/category_repository.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';

import 'journey_fakes.dart';

/// Monta a Home de verdade num teste de widget.
///
/// A Jornada puxa oito blocos, cada um com o seu provider e o seu Firebase.
/// Sem um lugar comum para os dublês, cada teste da Home recomeçaria do zero
/// — e foi exatamente por isso que a ORDEM dos blocos, que é a decisão
/// principal da tela, nunca teve teste nenhum.

/// Dia fixo. A Home fala de "hoje" e "amanhã" em três blocos.
final homeToday = DateTime(2026, 3, 15, 9);

mixin _NaoUsado {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} não usado na Home');
}

class _FinanceFake with _NaoUsado implements IFinanceRepository {
  _FinanceFake(this.installments);

  final List<InstallmentModel> installments;

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
  }) => Stream.value(installments);

  @override
  Future<QueryChunk<InstallmentModel>> queryInstallments(
    String workspaceId, {
    int? limit,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    OrderType? type,
    String? description,
    double? minAmount,
    double? maxAmount,
    InstallmentStatus? status,
    bool descending = true,
    dynamic chunkRef,
  }) async => QueryChunk(items: installments);
}

class _AccountsFake with _NaoUsado implements IAccountRepository {
  _AccountsFake(this.accounts);

  final List<AccountModel> accounts;

  @override
  Stream<List<AccountModel>> getAccounts(
    String workspaceId, {
    AccountType? type,
  }) => Stream.value(
    type == null ? accounts : accounts.where((a) => a.type == type).toList(),
  );
}

class _CategoriesFake with _NaoUsado implements ICategoryRepository {}

class _AutomaticFake implements IAutomaticTransactionRepository {
  @override
  Future<List<AutomaticTransactionModel>> getPendingTransactions(
    String workspaceId,
  ) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _GoalsFake with _NaoUsado implements IGoalRepository {
  _GoalsFake(this.goals);

  final List<GoalModel> goals;

  @override
  Stream<List<GoalModel>> watchGoals(String workspaceId) => Stream.value(goals);
}

class _CoachingFake with _NaoUsado implements ICoachingRepository {
  _CoachingFake(this.last);

  final CoachingModel? last;

  @override
  Future<CoachingModel?> getLastInsight(String workspaceId) async => last;
}

/// Uma parcela pendente com vencimento em [dueDate].
InstallmentModel homeInstallment({
  String id = 'i1',
  String description = 'Aluguel',
  double amount = 1800,
  required DateTime dueDate,
  InstallmentStatus status = InstallmentStatus.pending,
}) => InstallmentModel(
  id: id,
  orderId: 'o-$id',
  amount: amount,
  description: description,
  dueDate: dueDate,
  status: status,
  type: OrderType.expense,
  installmentType: InstallmentType.single,
);

Widget homeApp(Widget home, {required List<Override> overrides}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt'),
        home: Scaffold(body: home),
      ),
    );

List<Override> homeOverrides({
  List<InstallmentModel> installments = const [],
  List<AccountModel> accounts = const [],
  List<GoalModel> goals = const [],
  CoachingModel? lastInsight,
  List<Override> extra = const [],
}) => [
  clockProvider.overrideWithValue(() => homeToday),
  WorkspaceViewProviders.currentWorkspaceId.overrideWithValue('ws-home'),
  WorkspaceViewProviders.workspace.overrideWith(
    (ref) => TestWorkspaceNotifier(workspaceStateFor()),
  ),
  WorkspaceDomainProviders.repository.overrideWithValue(
    FakeWorkspaceRepository(),
  ),
  AuthDomainProviders.currentUser.overrideWithValue(null),
  JourneyDomainProviders.repository.overrideWithValue(FakeJourneyRepository()),
  FinanceDomainProviders.repository.overrideWithValue(
    _FinanceFake(installments),
  ),
  AccountDomainProviders.repository.overrideWithValue(_AccountsFake(accounts)),
  CategoryDomainProviders.repository.overrideWithValue(_CategoriesFake()),
  AutomaticTransactionDomainProviders.repository.overrideWithValue(
    _AutomaticFake(),
  ),
  GoalDomainProvider.repository.overrideWithValue(_GoalsFake(goals)),
  CoachingDomainProviders.repository.overrideWithValue(
    _CoachingFake(lastInsight),
  ),
  ...extra,
];

/// Monta [home] e deixa os streams assentarem.
Future<void> pumpHome(
  WidgetTester tester,
  Widget home, {
  required List<Override> overrides,
  Size size = const Size(420, 2600),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(homeApp(home, overrides: overrides));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}
