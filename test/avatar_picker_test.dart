import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/theme/app_theme.dart';
import 'package:funances/features/arena/domain/models/arena_state.dart';
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
  HeroSkin selected = HeroSkin.knight,
  Size size = const Size(400, 900),
}) async {
  final escolhas = <HeroSkin>[];

  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.runAsync(() async {
    await tester.pumpWidget(
      ProviderScope(
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

      final mago = tester.getSemantics(find.bySemanticsLabel('Mago'));
      expect(mago.hasFlag(SemanticsFlag.isSelected), isTrue);
      expect(mago.hasFlag(SemanticsFlag.isButton), isTrue);

      final curandeira = tester.getSemantics(
        find.bySemanticsLabel('Curandeira'),
      );
      expect(curandeira.hasFlag(SemanticsFlag.isSelected), isFalse);

      handle.dispose();
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

    test('quem nunca escolheu abre no cavaleiro, e não em branco', () {
      final users = _FakeUserRepository();
      final notifier = UserProfileNotifier(userService: UserService(users));

      notifier.load(
        UserModel(id: 'u1', email: 'a@b.c', createdAt: DateTime(2026)),
      );

      expect(notifier.state.avatar, HeroSkin.knight);
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
