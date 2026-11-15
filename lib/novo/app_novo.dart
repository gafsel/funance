import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dados/provedores.dart';
import 'telas/casca.dart';
import 'telas/entrar.dart';
import 'tema/tema_novo.dart';

/// O app do Funances 2. Convive com o app antigo no mesmo código até a
/// virada: `main.dart` escolhe qual dos dois sobe pelo ambiente do build.
class AppNovo extends ConsumerWidget {
  const AppNovo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessao = ref.watch(authProvider);
    return MaterialApp(
      title: 'Funances',
      debugShowCheckedModeBanner: false,
      theme: temaNovo(Brightness.light),
      darkTheme: temaNovo(Brightness.dark),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: sessao.when(
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, _) => const TelaEntrar(),
        data: (usuario) => usuario == null ? const TelaEntrar() : const Casca(),
      ),
    );
  }
}
