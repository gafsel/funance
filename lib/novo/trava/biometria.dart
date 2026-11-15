/// Biometria do aparelho, para a trava de abertura.
///
/// Só existe na web, por enquanto, e passa pelo navegador (WebAuthn). Fora
/// da web tudo responde "indisponível", e o app abre direto.
library;

export 'biometria_stub.dart' if (dart.library.js_interop) 'biometria_web.dart';
