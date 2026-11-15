import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'rotas.dart';
import 'telas/casca.dart';
import 'tema/tema_novo.dart';

/// O app do Funances 2. Convive com o app antigo no mesmo código até a
/// virada: `main.dart` escolhe qual dos dois sobe pelo ambiente do build.
class AppNovo extends ConsumerStatefulWidget {
  const AppNovo({super.key});

  @override
  ConsumerState<AppNovo> createState() => _AppNovoState();
}

class _AppNovoState extends ConsumerState<AppNovo> {
  late final _observador = ObservadorDeRotas(() => ref.read(secaoProvider));

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Funances',
      debugShowCheckedModeBanner: false,
      theme: temaNovo(Brightness.light),
      darkTheme: temaNovo(Brightness.dark),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // Cada seção e cada tela de detalhe tem endereço: recarregar a página
      // volta ao mesmo lugar (ver `rotas.dart`).
      onGenerateRoute: gerarRota,
      onGenerateInitialRoutes: rotasIniciais,
      navigatorObservers: [_observador],
    );
  }
}
