import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/model/core_models.dart';
import 'package:funances/core/presentation/screens/splash_screen.dart';
import 'package:funances/features/auth/presentation/providers.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/repositories/account_repository.dart';
import 'package:funances/features/finance/domain/repositories/finance_repository.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/screens/account_selection_screen.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_list_view.dart';
import 'package:funances/features/user/domain/models/user_model.dart';
import 'package:funances/features/workspace/domain/repositories/category_repository.dart';
import 'package:funances/features/workspace/domain/repositories/workspace_repository.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';

/// F4.8 §1.5 — os bugs de responsividade que são estruturais.
///
/// O app inteiro decide layout por `LayoutBuilder`; duas telas eram a exceção
/// e liam o `MediaQuery` global, que não sabe do `NavigationRail`. E uma
/// terceira dividia a largura por 2 fixo, sem olhar quanto espaço tinha.

mixin _NaoUsado {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} não usado no teste');
}

class _ParcelasFake with _NaoUsado implements IFinanceRepository {
  _ParcelasFake(this.itens);

  final List<InstallmentModel> itens;

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
  }) async => QueryChunk(items: itens);
}

class _ContasFake with _NaoUsado implements IAccountRepository {
  _ContasFake(this.contas);

  final List<AccountModel> contas;

  @override
  Stream<List<AccountModel>> getAccounts(
    String workspaceId, {
    AccountType? type,
  }) => Stream.value(contas);
}

class _CategoriasFake with _NaoUsado implements ICategoryRepository {}

class _WorkspaceFake with _NaoUsado implements IWorkspaceRepository {
  @override
  Future<List<UserModel>> getWorkspaceMembers(String workspaceId) async => [];
}

AccountModel _conta(String id) => AccountModel.checking(
  id: id,
  name: 'Conta $id',
  icon: 'account_balance',
  color: '#1565C0',
  initialBalanceDate: DateTime(2026, 1, 1),
);

InstallmentModel _parcela(String id) => InstallmentModel(
  id: id,
  orderId: 'o-$id',
  amount: 100,
  description: 'Lançamento $id',
  dueDate: DateTime(2026, 3, 10),
  status: InstallmentStatus.paid,
  type: OrderType.expense,
  installmentType: InstallmentType.single,
);

Widget _app(Widget home, {List<Override> overrides = const []}) => ProviderScope(
  overrides: [
    WorkspaceViewProviders.currentWorkspaceId.overrideWithValue('ws'),
    WorkspaceDomainProviders.repository.overrideWithValue(_WorkspaceFake()),
    AuthDomainProviders.currentUser.overrideWithValue(null),
    CategoryDomainProviders.repository.overrideWithValue(_CategoriasFake()),
    ...overrides,
  ],
  child: MaterialApp(
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

Future<void> _janela(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  group('lista de transações: tabela ou cartões', () {
    Widget lista({required double largura}) => _app(
      Center(
        child: SizedBox(
          width: largura,
          child: TransactionListView(provider: FinanceViewProviders.history),
        ),
      ),
      overrides: [
        FinanceDomainProviders.repository.overrideWithValue(
          _ParcelasFake([_parcela('i1')]),
        ),
        AccountDomainProviders.repository.overrideWithValue(_ContasFake([])),
      ],
    );

    testWidgets(
      'painel estreito numa janela larga mostra CARTÕES, não a tabela',
      (tester) async {
        // Este é o bug: janela de 1200, painel real de 700 (o
        // `NavigationRail` estendido come 200, mais margens). Lendo o
        // `MediaQuery` global a tela dizia "desktop" e desenhava a tabela num
        // espaço que não a comporta.
        await _janela(tester, const Size(1200, 900));
        await tester.pumpWidget(lista(largura: 700));
        await tester.pumpAndSettle();

        final l10n = await AppLocalizations.delegate.load(const Locale('pt'));
        expect(find.text(l10n.historyFilterDescriptionLabel), findsNothing);
      },
    );

    testWidgets('com espaço de verdade, a tabela aparece', (tester) async {
      await _janela(tester, const Size(1400, 900));
      await tester.pumpWidget(lista(largura: 1200));
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(const Locale('pt'));
      expect(find.text(l10n.historyFilterDescriptionLabel), findsOneWidget);
    });
  });

  group('seleção de conta: colunas pela largura, não `/2` fixo', () {
    Future<double> larguraDoCartao(
      WidgetTester tester,
      double larguraDisponivel,
    ) async {
      await _janela(tester, Size(larguraDisponivel + 100, 900));
      await tester.pumpWidget(
        _app(
          Center(
            child: SizedBox(
              width: larguraDisponivel,
              child: AccountSelectionScreen(
                title: 'Escolha',
                onAccountSelected: (_) {},
              ),
            ),
          ),
          overrides: [
            AccountDomainProviders.repository.overrideWithValue(
              _ContasFake([_conta('a'), _conta('b'), _conta('c')]),
            ),
            FinanceDomainProviders.repository.overrideWithValue(
              _ParcelasFake(const []),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final wrap = tester.widget<Wrap>(find.byType(Wrap).first);
      final primeiro = wrap.children.first as SizedBox;
      return primeiro.width!;
    }

    testWidgets('num celular continuam DUAS colunas, como hoje', (
      tester,
    ) async {
      final largura = await larguraDoCartao(tester, 400);
      // (400 - 24 - 12) / 2 = 182: exatamente o que a conta antiga dava.
      expect(largura, closeTo(182, 0.5));
    });

    testWidgets('num painel largo a grade ganha colunas em vez de esticar', (
      tester,
    ) async {
      final largura = await larguraDoCartao(tester, 1400);
      // Com o `/2` fixo eram DOIS cartões de ~676px. Agora são três de
      // ~445 — nenhum cartão de conta precisa de 676 pixels.
      expect(largura, lessThan(500));
      expect(largura, greaterThan(250));
    });
  });

  group('splash', () {
    testWidgets('a logo horizontal não é cortada numa tela estreita', (
      tester,
    ) async {
      // Só `height: 150` fazia a logo estourar a largura e perder as pontas.
      await _janela(tester, const Size(320, 640));
      await tester.pumpWidget(_app(const SplashScreen()));
      await tester.pump();

      final imagem = tester.getSize(find.byType(Image));
      expect(imagem.width, lessThanOrEqualTo(320 - 48));
      expect(tester.takeException(), isNull);
    });

    testWidgets('numa tela larga continua com os 150 de altura de hoje', (
      tester,
    ) async {
      await _janela(tester, const Size(1200, 900));
      await tester.pumpWidget(_app(const SplashScreen()));
      await tester.pump();

      expect(tester.getSize(find.byType(Image)).height, 150);
    });
  });
}
