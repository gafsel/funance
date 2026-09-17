import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/firestore/offline_write.dart';
import 'package:funances/core/firestore/sync_status.dart';

/// O provider de sincronização lia o uid UMA vez, no primeiro frame — antes de
/// a sessão salva ser restaurada — e ficava em cache para sempre. A tarja
/// nunca aparecia, e trocar de conta deixava o observador preso ao uid antigo.
///
/// Aqui a sessão é dirigida pelo teste: é a única forma de verificar que o
/// observador é REFEITO, sem um FirebaseAuth vivo.
///
/// O que NÃO dá para verificar daqui é o `.distinct()` do `sessionUidProvider`
/// — ele vive dentro da implementação real, e o override que torna este teste
/// possível é justamente o que o substitui.
/// Deixa o Riverpod propagar a mudança do fluxo de sessão.
Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  late StreamController<String?> sessao;
  late List<String?> observados;

  setUp(() {
    sessao = StreamController<String?>();
    observados = <String?>[];
    PendingWrites.reset();
    SyncStatusLatch.reset();
  });

  tearDown(() => sessao.close());

  /// Um container em que o observador de sincronização apenas ANOTA o uid que
  /// recebeu, em vez de falar com o Firestore.
  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: [
        sessionUidProvider.overrideWith((ref) => sessao.stream),
        syncStatusProvider.overrideWith((ref) {
          final uid = ref.watch(sessionUidProvider).valueOrNull;
          observados.add(uid);

          return Stream<SyncStatus>.value(
            uid == null ? SyncStatus.online : SyncStatus.offline,
          );
        }),
      ],
    );
    addTearDown(container.dispose);

    return container;
  }

  test(
    'a sessão que chega DEPOIS do primeiro frame refaz o observador',
    () async {
      final container = buildContainer();
      final sub = container.listen(syncStatusProvider, (_, _) {});
      addTearDown(sub.close);

      await _settle();
      expect(observados, [null], reason: 'ainda sem sessão restaurada');

      // A restauração da sessão acontece aqui — depois do primeiro frame.
      sessao.add('u1');
      await _settle();

      expect(observados, [null, 'u1']);
    },
  );

  test('trocar de conta não deixa o observador no uid antigo', () async {
    final container = buildContainer();
    final sub = container.listen(syncStatusProvider, (_, _) {});
    addTearDown(sub.close);

    sessao.add('u1');
    await _settle();

    sessao.add('u2');
    await _settle();

    expect(observados.last, 'u2');
  });

  group('troca de sessão esquece o que era da anterior', () {
    /// Só o uid é dirigido; o reset se verifica sem Firestore nenhum.
    ProviderContainer buildResetContainer() {
      final container = ProviderContainer(
        overrides: [sessionUidProvider.overrideWith((ref) => sessao.stream)],
      );
      addTearDown(container.dispose);

      return container;
    }

    test('sair zera a contagem de pendentes e o estado de rede', () async {
      final container = buildResetContainer();
      final sub = container.listen(sessionResetProvider, (_, _) {});
      addTearDown(sub.close);

      sessao.add('u1');
      await _settle();

      PendingWrites.add();
      SyncStatusLatch.update(SyncStatus.offline);

      sessao.add(null);
      await _settle();

      expect(PendingWrites.count, 0);
      expect(SyncStatusLatch.isOffline, isFalse);
    });

    test('trocar de conta também zera', () async {
      final container = buildResetContainer();
      final sub = container.listen(sessionResetProvider, (_, _) {});
      addTearDown(sub.close);

      sessao.add('u1');
      await _settle();

      PendingWrites.add();

      sessao.add('u2');
      await _settle();

      expect(PendingWrites.count, 0);
    });
  });
}
