/// Fora da web não há console de navegador: o Crashlytics é quem recebe o
/// erro, e o `dart:developer` cobre o desenvolvimento.
void reportToBrowserConsole(String message, Object? error, StackTrace? stack) {}
