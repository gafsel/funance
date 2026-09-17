/// Estratégia de URL do navegador.
///
/// Importação condicional porque `flutter_web_plugins` não compila fora da
/// web.
library;

export 'url_strategy_stub.dart'
    if (dart.library.js_interop) 'url_strategy_web.dart';
