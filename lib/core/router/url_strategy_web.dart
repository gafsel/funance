import 'package:flutter_web_plugins/url_strategy.dart';

/// Tira o `#` da URL: `/planning` em vez de `/#/planning`.
///
/// O `firebase.json` já reescreve `**` para `/index.html`, que é a condição
/// para isto funcionar — sem o rewrite, recarregar uma rota profunda daria
/// 404. Um servidor estático simples (`python3 -m http.server`) não reescreve
/// nada, então lá só a raiz abre.
void configureUrlStrategy() => usePathUrlStrategy();
