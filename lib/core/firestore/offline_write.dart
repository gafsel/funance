import 'dart:async';

import 'package:funances/core/observability/crash_reporter.dart';

/// Quanto tempo damos ao servidor antes de considerar a escrita "guardada".
///
/// Curto o bastante para não parecer travamento e longo o bastante para que,
/// com rede normal, o botão ainda espere a confirmação de verdade e um erro de
/// permissão apareça na hora.
const Duration _serverGrace = Duration(seconds: 5);

/// Espera a escrita do Firestore, mas não para sempre.
///
/// O Firestore aplica a escrita no cache local no mesmo instante: o dado já
/// está salvo e já aparece nas telas. O `Future` que ele devolve, porém, só
/// completa quando o SERVIDOR confirma — offline, nunca. Como os botões do app
/// ficam girando enquanto esperam esse `Future`, uma escrita sem rede deixava o
/// botão em carregamento eterno, e o usuário achava que tinha perdido o que
/// digitou (quando na verdade já estava salvo e sincronizaria sozinho).
///
/// Aqui a espera tem prazo. Passado o prazo, seguimos como sucesso — porque é
/// isso mesmo que aconteceu do ponto de vista do app — e o indicador de
/// sincronização assume dali em diante: é ele quem diz que ainda falta subir.
///
/// Um erro que chegue DEPOIS do prazo não tem mais para onde voltar (a tela já
/// seguiu), então vai para o CrashReporter em vez de virar um `Future` sem
/// tratamento derrubando a zona do app.
Future<void> settleWrite(
  Future<void> write, {
  Duration grace = _serverGrace,
}) {
  final Completer<void> settled = Completer<void>();
  final Timer timer = Timer(grace, () {
    if (!settled.isCompleted) settled.complete();
  });

  write.then(
    (_) {
      timer.cancel();
      if (!settled.isCompleted) settled.complete();
    },
    onError: (Object error, StackTrace stack) {
      timer.cancel();

      if (!settled.isCompleted) {
        settled.completeError(error, stack);
        return;
      }

      CrashReporter.recordError(error, stack);
    },
  );

  return settled.future;
}
