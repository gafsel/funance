import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

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

/// Região das Cloud Functions do ambiente. Tem de ser a mesma que o servidor
/// usa (`functions/src/core/config/region.ts`): o projeto antigo fica em
/// `us-central1` e os do Funances 2 em São Paulo.
String get regiaoDasFunctions =>
    ambiente == 'legado' ? 'us-central1' : 'southamerica-east1';

/// Use isto no lugar de `FirebaseFunctions.instance`, que sempre aponta para
/// `us-central1`.
FirebaseFunctions get funcoesDoAmbiente =>
    FirebaseFunctions.instanceFor(region: regiaoDasFunctions);

/// Desenvolvimento local: `--dart-define=EMULADORES=true` liga o app aos
/// emuladores do Firebase nesta máquina (`firebase emulators:start --project
/// demo-funances`), com dados semeados por `functions/src/scripts/
/// semear_emulador.ts`. Nada sai para a internet.
const bool usarEmuladores = bool.fromEnvironment('EMULADORES');

const FirebaseOptions opcoesDosEmuladores = FirebaseOptions(
  apiKey: 'demo',
  appId: '1:1:web:demo',
  messagingSenderId: '1',
  projectId: 'demo-funances',
);

Future<void> conectarEmuladores() async {
  await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
  // Na web, uma sessão guardada faz o SDK falar com o servidor de verdade
  // antes de o emulador ser ligado, e aí o emulador é ignorado pelo resto da
  // sessão. Sem sessão guardada isso não acontece; o preço é entrar de novo
  // a cada recarga, só neste modo.
  if (kIsWeb) await FirebaseAuth.instance.setPersistence(Persistence.NONE);
  FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
  funcoesDoAmbiente.useFunctionsEmulator('127.0.0.1', 5001);
}
