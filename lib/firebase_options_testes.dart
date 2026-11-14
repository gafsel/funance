// Configuração do projeto Firebase de TESTES do Funances 2 (`funances2-testes`).
//
// Só a web está registrada neste projeto por enquanto. Android, iOS e macOS
// entram quando o app novo ganhar tela (etapa 3 do plano); até lá, pedir este
// ambiente numa dessas plataformas falha de propósito, em vez de cair em
// silêncio no projeto antigo.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class TestesFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      'O ambiente "testes" só está configurado para a web. '
      'Compile sem --dart-define=AMBIENTE=testes ou registre a plataforma '
      'em funances2-testes.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDgd0OYmWZhC5EpUOwBf-URWDDXGJIglIk',
    appId: '1:706799129395:web:20d792da551b69d509e446',
    messagingSenderId: '706799129395',
    projectId: 'funances2-testes',
    authDomain: 'funances2-testes.firebaseapp.com',
    storageBucket: 'funances2-testes.firebasestorage.app',
  );
}
