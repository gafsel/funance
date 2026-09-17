import 'dart:js_interop';

@JS('console.error')
external void _consoleError(JSAny? label, JSAny? detail);

/// Escreve o erro no console do navegador, que é onde o dono do app vai
/// procurar quando algo quebrar na web.
///
/// `dart:developer`'s `log` não serve aqui: em release na web ele não deixa
/// rastro visível no DevTools, e era por isso que uma falha na web sumia sem
/// nenhuma linha no console — o caso do login com popup bloqueado.
void reportToBrowserConsole(String message, Object? error, StackTrace? stack) {
  final StringBuffer detail = StringBuffer();

  if (error != null) detail.writeln(error.toString());
  if (stack != null) detail.write(stack.toString());

  _consoleError('[funances] $message'.toJS, detail.toString().toJS);
}
