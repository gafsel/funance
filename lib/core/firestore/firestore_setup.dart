import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:funances/core/observability/crash_reporter.dart';

/// Liga o cache local do Firestore explicitamente, em todas as plataformas.
///
/// Fora da web a persistência já vinha ligada por padrão; na web, não — e era
/// por isso que o app na web ficava em branco assim que a rede oscilava,
/// enquanto no celular continuava mostrando o que já tinha sido carregado.
///
/// Configurar de forma explícita também deixa o comportamento igual nos três
/// lugares, em vez de depender do padrão de cada plataforma.
Future<void> configureFirestorePersistence() async {
  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      // O cache guarda meses de lançamentos; um teto pequeno faria o Firestore
      // descartar justamente o histórico que as telas de período leem.
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (error, stack) {
    // Na web a persistência falha quando o app já está aberto em outra aba
    // (`failed-precondition`) ou quando o navegador está em janela anônima com
    // IndexedDB bloqueado. Nos dois casos o app funciona online; o que não
    // pode é deixar de abrir.
    CrashReporter.recordError(error, stack);
  }
}
