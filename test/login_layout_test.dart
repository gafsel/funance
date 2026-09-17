import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/exceptions/business_exception.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/features/auth/domain/repositories/auth_repository.dart';
import 'package:funances/features/auth/domain/services/auth_service.dart';
import 'package:funances/features/auth/presentation/providers.dart';
import 'package:funances/features/auth/presentation/screens/login_screen.dart';
import 'package:funances/features/user/domain/models/user_model.dart';
import 'package:funances/l10n/app_localizations.dart';

/// F-design/5 — a porta de entrada.
///
/// Três defeitos concretos moravam aqui, e nenhum tinha teste:
///
/// * em 800px o formulário não era centralizado na coluna dele — ficava
///   colado à esquerda, com um vazio de ~250px à direita;
/// * o slogan era ~11px cinza sobre o gradiente escuro, porque o tema escuro
///   daquele tempo não definia tamanho de fonte e o estilo caía no padrão do
///   Material;
/// * o corte entre coluna única e duas colunas era decidido por `MediaQuery`
///   global com faixas (600 e 900) que não existiam em nenhuma outra tela.
///
/// 800px é a largura exata onde os três apareciam juntos, e por isso é a
/// largura que estes testes usam.

class _FakeAuthRepository implements IAuthRepository {
  @override
  Stream<UserModel?> get authStateChanges => const Stream.empty();

  @override
  Stream<ErrorCode> get redirectErrors => const Stream.empty();

  @override
  Future<UserModel> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<UserModel> signInWithEmailAndPassword(String e, String p) =>
      throw UnimplementedError();

  @override
  Future<UserModel> signUpWithEmailAndPassword(String e, String p, String d) =>
      throw UnimplementedError();

  @override
  Future<void> signOut() async {}
}

Future<void> _abrir(WidgetTester tester, Size janela) async {
  tester.view.physicalSize = janela;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // Só o serviço: o provider do repositório é tipado na implementação
        // concreta e não aceita dublê. Quem a tela lê é o serviço.
        AuthDomainProviders.service.overrideWithValue(
          AuthService(repository: _FakeAuthRepository()),
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('pt'),
        home: LoginScreen(),
      ),
    ),
  );
  await tester.pump();
}

/// O slogan em português. Vem do ARB, não de um literal aqui — se alguém
/// reescrever a frase, o teste acompanha; se alguém APAGAR a chave, ele cai.
Future<String> _slogan() async {
  final l10n = await AppLocalizations.delegate.load(const Locale('pt'));
  return l10n.loginSubtitle;
}

/// Quantas vezes a marca do app aparece.
///
/// Casa o asset EXATO, e não `contains('logo')`: o botão do Google mora em
/// `assets/logo/google.png`, então um `contains` contaria o buscador como
/// marca do Funances.
int _logos(WidgetTester tester) => tester
    .widgetList<Image>(find.byType(Image))
    .where(
      (i) =>
          i.image is AssetImage &&
          (i.image as AssetImage).assetName ==
              'assets/logo/logo-horizontal.png',
    )
    .length;

/// O título do herói. Só a coluna escura o mostra, então ele é o sinal de
/// "esta tela abriu em duas colunas" — o slogan não serve mais para isso,
/// porque as duas montagens o exibem.
Future<String> _tituloHeroi() async {
  final l10n = await AppLocalizations.delegate.load(const Locale('pt'));
  return l10n.loginTitle;
}

void main() {
  group('LoginScreen em 800px', () {
    testWidgets('abre em duas colunas: herói e formulário', (tester) async {
      await _abrir(tester, const Size(800, 900));

      final campos = find.byType(TextFormField);
      expect(campos, findsWidgets);

      // O formulário vive na metade direita.
      final formX = tester.getCenter(campos.first).dx;
      expect(
        formX,
        greaterThan(400),
        reason:
            'em 800px a tela divide ao meio; o formulário é a coluna da '
            'direita',
      );
    });

    testWidgets('o formulário é centralizado NA COLUNA dele', (tester) async {
      await _abrir(tester, const Size(800, 900));

      final campo = find.byType(TextFormField).first;
      final caixa = tester.getRect(campo);

      // A coluna da direita vai de 400 a 800; seu centro é 600.
      expect(
        caixa.center.dx,
        closeTo(600, 1),
        reason:
            'era o defeito visível: o `Center` externo somado ao padding de '
            '32 e ao ConstrainedBox deixava o formulário colado à esquerda, '
            'com ~250px de vazio à direita',
      );
    });

    testWidgets('o slogan é legível, não uma linha de 11px', (tester) async {
      await _abrir(tester, const Size(800, 900));

      final texto = tester.widget<Text>(find.text(await _slogan()));

      expect(
        texto.style?.fontSize,
        greaterThanOrEqualTo(16),
        reason:
            'o slogan caía no padrão do Material (~11px) porque o tema '
            'escuro não definia escala; agora é bodyLarge',
      );
      expect(
        texto.style?.color,
        AppColors.inkInverse2,
        reason:
            'tinta secundária SOBRE superfície de jogo, não o cinza de '
            'papel — o fundo aqui é o gradiente do cofre',
      );
    });

    testWidgets('a marca aparece uma vez só', (tester) async {
      await _abrir(tester, const Size(800, 900));

      expect(
        _logos(tester),
        1,
        reason:
            'em duas colunas a logo é do herói; o formulário não repete ela',
      );
    });

    testWidgets('a promessa não é dita duas vezes', (tester) async {
      await _abrir(tester, const Size(800, 900));

      expect(
        find.text(await _slogan()),
        findsOneWidget,
        reason:
            'o herói e o formulário usavam a MESMA chave: em duas colunas a '
            'frase aparecia sob a marca e de novo sob o "Entrar"',
      );
    });
  });

  group('LoginScreen em coluna única', () {
    testWidgets('abaixo de 600px vira uma coluna com a marca em cima', (
      tester,
    ) async {
      await _abrir(tester, const Size(420, 900));

      expect(_logos(tester), 1);

      final campo = find.byType(TextFormField).first;
      expect(
        tester.getRect(campo).center.dx,
        closeTo(210, 1),
        reason: 'em coluna única o formulário centraliza na tela inteira',
      );
    });

    testWidgets('a promessa sobrevive ao corte, agora vinda do formulário', (
      tester,
    ) async {
      await _abrir(tester, const Size(420, 900));

      expect(
        find.text(await _slogan()),
        findsOneWidget,
        reason:
            'sem herói, é o formulário que carrega a marca — e com ela a '
            'promessa',
      );
    });
  });

  group('LoginScreen no corte', () {
    testWidgets('600px já é duas colunas', (tester) async {
      await _abrir(tester, const Size(600, 900));

      expect(find.text(await _tituloHeroi()), findsOneWidget);
    });

    testWidgets('599px ainda é uma', (tester) async {
      await _abrir(tester, const Size(599, 900));

      expect(
        find.text(await _tituloHeroi()),
        findsNothing,
        reason:
            'o corte é o `AppBreakpoints.medium` compartilhado, não as faixas '
            'de 600/900 que só esta tela conhecia',
      );
    });
  });
}
