import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

import 'firebase_options.dart';
import 'firebase_options_testes.dart';

/// Projeto Firebase para o qual este build aponta, escolhido na compilação
/// com `--dart-define=AMBIENTE=<nome>`.
///
/// - `legado` (padrão): `funance-cef1b`, o projeto do app atual. É o padrão
///   porque é o único com Android, iOS e macOS registrados; um build local
///   sem parâmetro continua igual ao de antes.
/// - `testes`: `funances2-testes`, onde o CI publica. Só web por enquanto.
const String ambiente = String.fromEnvironment(
  'AMBIENTE',
  defaultValue: 'legado',
);

FirebaseOptions firebaseOptionsDoAmbiente() {
  switch (ambiente) {
    case 'legado':
      return DefaultFirebaseOptions.currentPlatform;
    case 'testes':
      return TestesFirebaseOptions.currentPlatform;
    default:
      throw ArgumentError.value(
        ambiente,
        'AMBIENTE',
        'Ambiente desconhecido. Use "legado" ou "testes".',
      );
  }
}
