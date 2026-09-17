import 'package:cloud_firestore/cloud_firestore.dart';

/// Liga o cache local do Firestore explicitamente, em todas as plataformas.
///
/// Fora da web a persistência já vinha ligada por padrão; na web, não — e era
/// por isso que o app na web ficava em branco assim que a rede oscilava,
/// enquanto no celular continuava mostrando o que já tinha sido carregado.
///
/// Configurar de forma explícita também deixa o comportamento igual nos três
/// lugares, em vez de depender do padrão de cada plataforma.
///
/// NA WEB O CACHE É DE UMA ABA SÓ. A primeira aba a abrir fica com o cache
/// persistente (IndexedDB); as outras seguem em memória, e o SDK registra um
/// `failed-precondition` no console do navegador. O app funciona nas duas
/// situações — a diferença aparece ao recarregar uma aba secundária, que volta
/// sem cache e precisa da rede para a primeira leitura.
///
/// Não há como o app saber que isso aconteceu: o setter de `settings` não
/// devolve nada e não lança — ele só guarda a configuração, e a tentativa de
/// abrir o cache acontece depois, dentro do SDK, na primeira operação. O
/// `cloud_firestore` não expõe esse resultado em nenhuma API. Por isso aqui
/// não há try/catch: ele daria a impressão de tratar um erro que nunca passa
/// por este código.
void configureFirestorePersistence() {
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    // O cache guarda meses de lançamentos; um teto pequeno faria o Firestore
    // descartar justamente o histórico que as telas de período leem.
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
}
