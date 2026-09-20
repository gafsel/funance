import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_theme.dart';
import 'package:funances/core/widgets/error_view.dart';
import 'package:funances/features/arena/domain/models/arena_state.dart';
import 'package:funances/features/arena/presentation/game/arena_sprites.dart';
import 'package:funances/features/arena/presentation/providers/arena_sprites_provider.dart';
import 'package:funances/features/user/domain/models/user_model.dart';
import 'package:funances/features/user/domain/repositories/user_repository.dart';
import 'package:funances/features/user/domain/services/user_service.dart';
import 'package:funances/features/user/presentation/controller/user_profile_notifier.dart';
import 'package:funances/features/user/presentation/widgets/avatar_picker.dart';
import 'package:funances/l10n/app_localizations.dart';

/// O seletor de avatar — a única tela nova do pacote `wp/avatar`.
///
/// O que ele precisa provar não é "desenha oito quadrados": é que a ESCOLHA
/// chega a quem salva e que um leitor de tela consegue fazê-la. A grade é
/// pixel art de 16 px; sem semântica ela seria uma parede de imagens mudas.

/// Monta o seletor de verdade, com a folha de sprites carregada.
///
/// `runAsync` porque a folha é decodificada por `decodeImageFromList`, que
/// depende do relógio REAL — dentro do relógio falso do `testWidgets` o
/// `Future` nunca completa e a grade apareceria sem boneco nenhum.
Future<List<HeroSkin>> _pump(
  WidgetTester tester, {
  HeroSkin? selected = HeroSkin.knight,
  Size size = const Size(400, 900),
  List<Override> overrides = const [],
}) async {
  final escolhas = <HeroSkin>[];

  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.runAsync(() async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('pt'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: AvatarPicker(
                selected: selected,
                onSelected: escolhas.add,
              ),
            ),
          ),
        ),
      ),
    );

    for (var i = 0; i < 6; i++) {
      await tester.pump(Duration.zero);
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
  });

  await tester.pump();
  return escolhas;
}

mixin _NaoUsado {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} não usado no teste');
}

class _FakeUserRepository with _NaoUsado implements IUserRepository {
  final List<(String, Map<String, dynamic>)> escritas = [];

  @override
  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    escritas.add((id, data));
  }
}

void main() {
  group('o modelo do usuário', () {
    test('sobrevive à ida e volta COM avatar', () {
      final user = UserModel(
        id: 'u1',
        email: 'a@b.c',
        avatar: 'healer',
        createdAt: DateTime(2026, 3, 15),
      );

      expect(UserModel.fromJson(user.toJson()), user);
      expect(user.toJson()['avatar'], 'healer');
    });

    test('um documento SEM o campo continua legível', () {
      final user = UserModel.fromJson({
        'id': 'u1',
        'email': 'a@b.c',
        'createdAt': DateTime(2026, 3, 15).toIso8601String(),
      });

      expect(user.avatar, isNull);
      // E o round-trip não inventa o campo de volta com um valor.
      expect(UserModel.fromJson(user.toJson()).avatar, isNull);
    });

    test('o nome guardado vira skin; o desconhecido vira o cavaleiro', () {
      expect(HeroSkin.fromName('barbarian'), HeroSkin.barbarian);
      expect(HeroSkin.fromName('necromante'), HeroSkin.knight);
      expect(HeroSkin.fromName(null), HeroSkin.knight);
    });
  });

  group('o seletor', () {
    testWidgets('mostra o catálogo inteiro, um tile por avatar', (
      tester,
    ) async {
      await _pump(tester);

      for (final skin in HeroSkin.values) {
        expect(
          find.byKey(ValueKey('avatar_${skin.name}')),
          findsOneWidget,
          reason: 'faltou o tile de ${skin.name}',
        );
      }
    });

    testWidgets('tocar num boneco devolve a skin dele', (tester) async {
      final escolhas = await _pump(tester);

      expect(escolhas, isEmpty, reason: 'montar a grade não é escolher');

      await tester.tap(find.byKey(const ValueKey('avatar_ranger')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('avatar_smith')));
      await tester.pump();

      expect(escolhas, [HeroSkin.ranger, HeroSkin.smith]);
    });

    testWidgets('o leitor de tela ouve o NOME e o que está marcado', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, selected: HeroSkin.mage);

      // O nome do personagem, e não "imagem": é a única pista que resta a
      // quem não enxerga a pixel art.
      expect(
        find.bySemanticsLabel('Mago'),
        findsOneWidget,
        reason: 'o tile precisa se anunciar pelo nome do personagem',
      );
      expect(find.bySemanticsLabel('Curandeira'), findsOneWidget);

      expect(
        tester.getSemantics(find.bySemanticsLabel('Mago')),
        isSemantics(isButton: true, isSelected: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Curandeira')),
        isSemantics(isButton: true, isSelected: false),
      );

      handle.dispose();
    });

    testWidgets('sem escolha, nenhum tile fica marcado', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, selected: null);

      for (final skin in HeroSkin.values) {
        expect(
          tester.getSemantics(find.byKey(ValueKey('avatar_${skin.name}'))),
          isSemantics(isSelected: false),
          reason: '${skin.name} não deveria estar marcado',
        );
      }

      handle.dispose();
    });

    testWidgets('o leitor de tela consegue ATIVAR um tile', (tester) async {
      final handle = tester.ensureSemantics();
      final escolhas = await _pump(tester);

      // Sem a ação, o nó anunciava "botão, Mago" e não tinha o que acionar:
      // a grade existia para o leitor de tela e era inescolhível por ele.
      expect(
        tester.getSemantics(find.bySemanticsLabel('Mago')),
        isSemantics(hasTapAction: true),
      );

      // E a ação ACONTECE: o teste aciona o nó pela semântica, que é
      // exatamente o caminho do leitor de tela — não um toque na tela.
      tester.semantics.performAction(
        find.semantics.byLabel('Mago'),
        SemanticsAction.tap,
      );
      await tester.pump();

      expect(escolhas, [HeroSkin.mage]);
      handle.dispose();
    });

    testWidgets('a folha que não abriu vira erro com "tentar de novo"', (
      tester,
    ) async {
      var tentativas = 0;

      await _pump(
        tester,
        overrides: [
          arenaSpritesProvider.overrideWith((ref) {
            tentativas++;
            return Future<ArenaSprites>.error(
              Exception('folha indisponível'),
              StackTrace.current,
            );
          }),
        ],
      );

      // Erro NÃO é carregando: sem este ramo ficavam oito quadros escuros e
      // vazios na tela para sempre, sem dizer o que houve.
      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.byKey(const ValueKey('avatar_knight')), findsNothing);

      expect(tentativas, 1);
      await tester.tap(find.byType(OutlinedButton));
      await tester.pump();

      expect(tentativas, 2, reason: 'o botão recarrega a folha de verdade');
    });

    testWidgets('o foco do teclado desenha um realce na frente do cartão', (
      tester,
    ) async {
      await _pump(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // O ouro do ESCOLHIDO não serve de realce de foco: ele já significa
      // outra coisa e some contra o próprio anel de seleção. O realce é a
      // tinta principal do tema, que é o maior contraste que o design system
      // tem contra o fundo da tela.
      final molduras = tester
          .widgetList<Container>(find.byType(Container))
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .where(
            (d) => d.border is Border && (d.border! as Border).top.width == 2,
          )
          .toList();

      expect(
        molduras.map((d) => (d.border! as Border).top.color),
        contains(AppPalette.light.ink),
      );
    });

    testWidgets('cabe em 400 px sem estourar a largura', (tester) async {
      await _pump(tester, size: const Size(400, 900));

      expect(tester.takeException(), isNull);
    });

    testWidgets('e em 1300 px continua uma grade, não uma coluna', (
      tester,
    ) async {
      await _pump(tester, size: const Size(1300, 900));

      final primeiro = tester.getTopLeft(
        find.byKey(const ValueKey('avatar_knight')),
      );
      final ultimo = tester.getTopLeft(
        find.byKey(const ValueKey('avatar_smith')),
      );

      // Os oito na MESMA linha: no desktop o catálogo inteiro se vê de uma
      // vez, que é o ponto de uma grade.
      expect(ultimo.dy, primeiro.dy);
      expect(ultimo.dx, greaterThan(primeiro.dx));
    });
  });

  group('a edição de perfil', () {
    test('um avatar fora do catálogo não marca nada, e avisa', () {
      final users = _FakeUserRepository();
      final notifier = UserProfileNotifier(userService: UserService(users));

      notifier.load(
        UserModel(
          id: 'u1',
          email: 'a@b.c',
          avatar: 'necromante',
          createdAt: DateTime(2026),
        ),
      );

      // Marcar o cavaleiro aqui seria afirmar uma escolha que não existe —
      // e a Arena, para o mesmo documento, desenha o boneco da ordem de
      // entrada. As duas telas agora contam a mesma história.
      expect(notifier.state.avatar, isNull);
      expect(notifier.state.avatarUnknown, isTrue);
    });

    test('salvar SÓ o nome não grava avatar nenhum', () async {
      final users = _FakeUserRepository();
      final notifier = UserProfileNotifier(userService: UserService(users));

      notifier.load(
        UserModel(id: 'u1', email: 'a@b.c', createdAt: DateTime(2026)),
      );
      notifier.updateDisplayName('Gabriel');
      await notifier.submit();

      // É a AUSÊNCIA do campo que mantém o cavaleiro e o mago da ordem de
      // entrada: gravar `knight` numa edição de nome derrubaria o mago da
      // parceira para fazer dela um segundo cavaleiro.
      expect(users.escritas.single.$2.containsKey('avatar'), isFalse);
      expect(users.escritas.single.$2['displayName'], 'Gabriel');
    });

    test('quem já tinha avatar o mantém ao editar só o nome', () async {
      final users = _FakeUserRepository();
      final notifier = UserProfileNotifier(userService: UserService(users));

      notifier.load(
        UserModel(
          id: 'u1',
          email: 'a@b.c',
          avatar: 'healer',
          createdAt: DateTime(2026),
        ),
      );
      notifier.updateDisplayName('Gabriel');
      await notifier.submit();

      expect(users.escritas.single.$2['avatar'], 'healer');
    });

    test('o usuário entra no estado INICIAL, sem um quadro de atraso', () {
      final users = _FakeUserRepository();
      final notifier = UserProfileNotifier(
        userService: UserService(users),
        user: UserModel(
          id: 'u1',
          email: 'a@b.c',
          displayName: 'Gabriel',
          avatar: 'monk',
          createdAt: DateTime(2026),
        ),
      );

      // Sem `load()` nenhum: é o que a tela desenha no PRIMEIRO quadro.
      expect(notifier.state.id, 'u1');
      expect(notifier.state.displayName, 'Gabriel');
      expect(notifier.state.avatar, HeroSkin.monk);
    });

    test('abre com o avatar que está gravado', () {
      final users = _FakeUserRepository();
      final notifier = UserProfileNotifier(userService: UserService(users));

      notifier.load(
        UserModel(
          id: 'u1',
          email: 'a@b.c',
          displayName: 'Gabriel',
          avatar: 'monk',
          createdAt: DateTime(2026),
        ),
      );

      expect(notifier.state.avatar, HeroSkin.monk);
    });

    test('quem nunca escolheu abre sem marca e sem aviso', () {
      final users = _FakeUserRepository();
      final notifier = UserProfileNotifier(userService: UserService(users));

      notifier.load(
        UserModel(id: 'u1', email: 'a@b.c', createdAt: DateTime(2026)),
      );

      expect(notifier.state.avatar, isNull);
      expect(notifier.state.avatarUnknown, isFalse);
    });

    test('salvar o perfil grava o avatar junto com o nome', () async {
      final users = _FakeUserRepository();
      final notifier = UserProfileNotifier(userService: UserService(users));

      notifier.load(
        UserModel(
          id: 'u1',
          email: 'a@b.c',
          displayName: 'Gabriel',
          createdAt: DateTime(2026),
        ),
      );
      notifier.updateAvatar(HeroSkin.warrior);
      await notifier.submit();

      expect(users.escritas.single.$1, 'u1');
      expect(users.escritas.single.$2['avatar'], 'warrior');
      // E não perde o resto do perfil no caminho.
      expect(users.escritas.single.$2['displayName'], 'Gabriel');
    });
  });
}
