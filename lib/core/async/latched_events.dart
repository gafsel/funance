import 'dart:async';

/// Um canal de eventos que não se perde quando ninguém está ouvindo.
///
/// Um `StreamController.broadcast()` descarta o que é publicado sem ouvinte, e
/// é justamente isso que acontece nos dois casos em que este canal é usado: o
/// evento nasce ANTES de existir tela para mostrá-lo.
///
/// No erro de login por redirect, o retorno é lido no arranque do app, antes
/// de a tela de login montar — o erro caía no vazio e a tela reaparecia muda.
/// Numa falha tardia de escrita é a mesma história se a tarja ainda não tiver
/// sido construída.
///
/// Então: sem ouvinte, o evento fica guardado; o próximo a assinar o recebe.
/// E é CONSUMIDO ao ser entregue — uma segunda assinatura não vê de novo,
/// senão o mesmo erro reapareceria a cada visita à tela.
///
/// Guarda só o último. Estes eventos são avisos, não um histórico: mostrar uma
/// fila de erros antigos ao abrir a tela seria pior do que mostrar o mais
/// recente.
class LatchedEvents<T extends Object> {
  final StreamController<T> _controller = StreamController<T>.broadcast();

  T? _held;

  /// Assinar entrega primeiro o que ficou guardado, se houver.
  Stream<T> get stream {
    return Stream<T>.multi((controller) {
      final T? held = _held;

      if (held != null) {
        // Consumido: quem assinar depois não recebe de novo.
        _held = null;
        controller.add(held);
      }

      final StreamSubscription<T> subscription = _controller.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );

      controller.onCancel = subscription.cancel;
    });
  }

  /// Publica — para quem estiver ouvindo, ou para quem chegar depois.
  void add(T event) {
    if (_controller.hasListener) {
      _controller.add(event);
      return;
    }

    _held = event;
  }

  /// Esquece o que estiver guardado.
  ///
  /// Usado quando o evento perdeu o dono — um erro de login do usuário
  /// anterior não deve aparecer para o próximo.
  void clear() => _held = null;
}
