import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Ponto único de pergunta "em que plataforma estou".
///
/// Existe por causa de uma armadilha: na web `Platform.isAndroid` não devolve
/// `false`, ele estoura `UnsupportedError`. Todo `if (Platform.isAndroid)`
/// espalhado pelo app era, na web, uma exceção — e como boa parte deles mora
/// em `build()` e em construtores de notifier, o erro derrubava a tela em vez
/// de apenas esconder um recurso que não existe ali.
///
/// A guarda `kIsWeb` vem primeiro de propósito: ela é constante de compilação,
/// então o `Platform` nem chega a ser avaliado no bundle web.
abstract final class AppPlatform {
  /// Roda no navegador.
  static const bool isWeb = kIsWeb;

  /// Roda no Android — e não na web.
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// Roda no iOS — e não na web.
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  /// Roda no macOS — e não na web.
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  /// Tem um sistema de arquivos com caminhos utilizáveis (`File(path)`).
  ///
  /// Na web não tem: o que o seletor de arquivos devolve é um blob, e
  /// `File('blob:...')` não abre nada. Quem envia arquivo decide por aqui se
  /// pode falar em caminho ou se precisa trabalhar com bytes.
  static const bool hasFileSystem = !kIsWeb;
}
