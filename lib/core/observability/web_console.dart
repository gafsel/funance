/// Console do navegador, quando existe um.
///
/// A importação condicional é o que mantém `dart:js_interop` fora dos builds
/// de macOS/iOS/Android, onde ele não compila.
library;

export 'web_console_stub.dart'
    if (dart.library.js_interop) 'web_console_web.dart';
