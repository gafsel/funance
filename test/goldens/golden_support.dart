import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/analytics/analytics_service.dart';
import 'package:funances/core/model/core_models.dart';
import 'package:funances/core/theme/app_theme.dart';
import 'package:funances/core/time/clock.dart';
import 'package:funances/features/auth/presentation/providers.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/repositories/account_repository.dart';
import 'package:funances/features/finance/domain/repositories/finance_repository.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/user/domain/models/user_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/domain/repositories/category_repository.dart';
import 'package:funances/features/workspace/domain/repositories/workspace_repository.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';

/// F4.8 — rede de segurança das telas gigantes.
///
/// Cada tela quebrada em widgets tem um golden gerado NO COMMIT ANTERIOR à
/// quebra. Se a extração mudar um pixel — uma margem esquecida, um `Padding`
/// que virou `Container`, uma ordem de blocos trocada — o golden quebra. O
/// refactor é estrutural: a árvore renderizada tem de ser a mesma.
///
/// Os goldens rodam no comparador local do `flutter_test`. As fontes são as
/// EMPACOTADAS do app, carregadas por [loadAppFonts] — ver o porquê lá.

/// Carrega Fredoka e Inter de `assets/fonts/` no ambiente de teste.
///
/// Sem isto, `flutter test` desenha tudo com a fonte de teste (aqueles blocos
/// pretos) e o golden fica cego justamente para a maior mudança visual deste
/// pacote: a tipografia. Como os .ttf estão versionados no repositório e não
/// dependem de nada instalado na máquina, carregá-los mantém o golden
/// determinístico entre máquinas — que é a razão de existir da fonte de teste.
///
/// Lê do disco em vez de `rootBundle` porque o bundle de asset do `flutter
/// test` não inclui as fontes declaradas no `pubspec`.
Future<void> loadAppFonts() async {
  if (_fontsLoaded) return;
  _fontsLoaded = true;

  const families = <String, List<String>>{
    'Fredoka': ['Fredoka-Medium', 'Fredoka-SemiBold', 'Fredoka-Bold'],
    'Inter': ['Inter-Regular', 'Inter-Medium', 'Inter-SemiBold', 'Inter-Bold'],
  };

  for (final entry in families.entries) {
    final loader = FontLoader(entry.key);
    for (final file in entry.value) {
      // Leitura SÍNCRONA de propósito: dentro de `testWidgets` o relógio é
      // falso e um `await` de I/O real nunca completa — o golden travava.
      final bytes = File('assets/fonts/$file.ttf').readAsBytesSync();
      loader.addFont(
        Future<ByteData>.value(ByteData.sublistView(bytes)),
      );
    }
    await loader.load();
  }
}

bool _fontsLoaded = false;

/// Dia fixo. Nenhum golden pode depender de quando o teste roda.
final goldenToday = DateTime(2026, 3, 15);

mixin NaoUsado {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} não usado no golden');
}

class FakeAnalytics with NaoUsado implements AnalyticsService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class FakeFinanceRepository with NaoUsado implements IFinanceRepository {
  FakeFinanceRepository({this.installments = const []});

  final List<InstallmentModel> installments;

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

class FakeAccountRepository with NaoUsado implements IAccountRepository {
  FakeAccountRepository({this.accounts = const []});

  final List<AccountModel> accounts;

  @override
  Stream<List<AccountModel>> getAccounts(String workspaceId, {AccountType? type}) =>
      Stream.value(
        type == null
            ? accounts
            : accounts.where((a) => a.type == type).toList(),
      );
}

class FakeCategoryRepository with NaoUsado implements ICategoryRepository {
  FakeCategoryRepository({this.categories = const []});

  final List<CategoryModel> categories;

  @override
  Stream<List<CategoryModel>> getCategories(String workspaceId) =>
      Stream.value(categories);
}

class FakeWorkspaceRepository with NaoUsado implements IWorkspaceRepository {
  @override
  Future<List<UserModel>> getWorkspaceMembers(String workspaceId) async => [];
}

List<Override> goldenOverrides({
  List<AccountModel> accounts = const [],
  List<CategoryModel> categories = const [],
  List<InstallmentModel> installments = const [],
  List<Override> extra = const [],
}) => [
  WorkspaceViewProviders.currentWorkspaceId.overrideWithValue('ws-golden'),
  WorkspaceDomainProviders.repository.overrideWithValue(
    FakeWorkspaceRepository(),
  ),
  AuthDomainProviders.currentUser.overrideWithValue(null),
  clockProvider.overrideWithValue(() => goldenToday),
  FinanceDomainProviders.repository.overrideWithValue(
    FakeFinanceRepository(installments: installments),
  ),
  AccountDomainProviders.repository.overrideWithValue(
    FakeAccountRepository(accounts: accounts),
  ),
  CategoryDomainProviders.repository.overrideWithValue(
    FakeCategoryRepository(categories: categories),
  ),
  ...extra,
];

/// Host comum: mesmo tema, mesmo locale e mesmas delegates em todos os
/// goldens, para que a única variável seja a tela.
Widget goldenApp(Widget home, {List<Override> overrides = const []}) {
  return ProviderScope(
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
      home: home,
    ),
  );
}

/// Fixa o tamanho da superfície: um golden feito em 800x600 e conferido em
/// outro tamanho compararia duas telas diferentes.
Future<void> setGoldenSurface(WidgetTester tester, Size size) async {
  await loadAppFonts();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

CategoryModel goldenCategory({
  required String id,
  required String name,
  String icon = 'shopping_cart',
  String color = '#FF5722',
  CategoryType type = CategoryType.expense,
  CategoryAllocation allocation = CategoryAllocation.essential,
}) => CategoryModel(
  id: id,
  name: name,
  icon: icon,
  color: color,
  type: type,
  allocation: allocation,
);

AccountModel goldenAccount({
  String id = 'acc-1',
  String name = 'Conta Corrente',
}) => AccountModel.checking(
  id: id,
  name: name,
  icon: 'account_balance',
  color: '#1565C0',
  initialBalanceDate: DateTime(2026, 1, 1),
);
