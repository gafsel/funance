import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/async/latched_events.dart';
import 'package:funances/core/exceptions/business_exception.dart';

/// O erro do login por redirect nasce no arranque do app, antes de a tela de
/// login montar. Com um `StreamController.broadcast()` comum ele era publicado
/// sem ouvinte e DESCARTADO — a tela reaparecia muda, que é exatamente o bug
/// que esse caminho existia para resolver.
void main() {
  group('evento publicado ANTES de alguém assinar', () {
    test('chega a quem assina depois', () async {
      final events = LatchedEvents<ErrorCode>();

      // Ninguém ouvindo ainda: é o gate do splash publicando.
      events.add(ErrorCode.signInUnauthorizedDomain);

      // Agora a tela de login montou.
      await expectLater(
        events.stream.first,
        completion(ErrorCode.signInUnauthorizedDomain),
      );
    });

    test('uma segunda assinatura NÃO recebe de novo', () async {
      final events = LatchedEvents<ErrorCode>();
      events.add(ErrorCode.signInUnauthorizedDomain);

      final primeiro = <ErrorCode>[];
      final sub = events.stream.listen(primeiro.add);
      await Future<void>.delayed(Duration.zero);

      expect(primeiro, [ErrorCode.signInUnauthorizedDomain]);

      // Voltar à tela de login não pode ressuscitar o erro da visita anterior.
      final segundo = <ErrorCode>[];
      final outra = events.stream.listen(segundo.add);
      await Future<void>.delayed(Duration.zero);

      expect(segundo, isEmpty);

      await sub.cancel();
      await outra.cancel();
    });

    test('guarda só o último: são avisos, não um histórico', () async {
      final events = LatchedEvents<ErrorCode>();

      events.add(ErrorCode.signInCancelled);
      events.add(ErrorCode.signInUnauthorizedDomain);

      final recebidos = <ErrorCode>[];
      final sub = events.stream.listen(recebidos.add);
      await Future<void>.delayed(Duration.zero);

      expect(recebidos, [ErrorCode.signInUnauthorizedDomain]);

      await sub.cancel();
    });
  });

  group('com alguém ouvindo', () {
    test('o evento é entregue na hora e não fica guardado', () async {
      final events = LatchedEvents<ErrorCode>();

      final recebidos = <ErrorCode>[];
      final sub = events.stream.listen(recebidos.add);
      await Future<void>.delayed(Duration.zero);

      events.add(ErrorCode.wrongPassword);
      await Future<void>.delayed(Duration.zero);

      expect(recebidos, [ErrorCode.wrongPassword]);

      // Nada retido: quem chegar depois não vê um erro já mostrado.
      final tardio = <ErrorCode>[];
      final outra = events.stream.listen(tardio.add);
      await Future<void>.delayed(Duration.zero);

      expect(tardio, isEmpty);

      await sub.cancel();
      await outra.cancel();
    });
  });

  test('clear esquece o que estava guardado', () async {
    // No logout: um erro de login do usuário anterior não é assunto do
    // próximo.
    final events = LatchedEvents<ErrorCode>();
    events.add(ErrorCode.signInUnauthorizedDomain);

    events.clear();

    final recebidos = <ErrorCode>[];
    final sub = events.stream.listen(recebidos.add);
    await Future<void>.delayed(Duration.zero);

    expect(recebidos, isEmpty);

    await sub.cancel();
  });
}
