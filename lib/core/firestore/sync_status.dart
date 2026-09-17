import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/firestore/offline_write.dart';
import 'package:funances/core/firestore/write_failures.dart';

/// Como está a conversa do app com o servidor.
enum SyncStatus {
  /// Lendo e escrevendo no servidor. Nada a dizer ao usuário.
  online,

  /// Online, mas ainda há escrita local esperando confirmação.
  pendingWrites,

  /// Respondendo pelo cache. O app continua utilizável.
  offline,
}

/// Uid da sessão, como um fluxo.
///
/// Público para o teste poder trocar a sessão sem um FirebaseAuth vivo — é a
/// única costura por onde se verifica que o observador é REFEITO ao trocar de
/// conta, que era justamente o que estava quebrado.
///
/// A primeira versão disto lia `FirebaseAuth.instance.currentUser` UMA vez, no
/// primeiro frame — antes de a sessão salva ser restaurada. Resultado: o uid
/// era sempre nulo, o provider devolvia "online" fixo e ficava em cache para
/// sempre; a tarja nunca aparecia, nem depois do login. Trocar de conta também
/// deixava o observador preso ao uid antigo.
///
/// Observamos o `FirebaseAuth` direto, e não o provider de usuário da feature
/// de auth, por dois motivos: é a fonte real do uid (o outro é derivado dele) e
/// evita que `core` passe a depender de `features`.
final sessionUidProvider = StreamProvider<String?>((ref) {
  return FirebaseAuth.instance
      .authStateChanges()
      .map((user) => user?.uid)
      .distinct();
});

/// Esquece o que pertencia à sessão anterior.
///
/// Só roda de novo quando o uid MUDA — logout, login, troca de conta. Uma
/// escrita pendente, um estado de sincronização ou uma falha de escrita eram
/// do usuário que saiu: contá-los mostraria ao próximo uma tarja que não é
/// dele.
///
/// É um provider à parte, e não um trecho do [syncStatusProvider], porque
/// assim se verifica sozinho: o outro precisa de um Firestore vivo para
/// existir, este precisa só de um uid.
final sessionResetProvider = Provider<void>((ref) {
  ref.watch(sessionUidProvider);

  PendingWrites.reset();
  SyncStatusLatch.reset();
  WriteFailures.clear();
});

/// Estado de sincronização, lido do próprio Firestore.
///
/// Não usamos um pacote de conectividade: ter Wi-Fi não é a mesma pergunta que
/// "o Firestore está conseguindo falar com o servidor", e é a segunda que
/// importa aqui. O SDK já responde isso nos metadados de qualquer snapshot —
/// `isFromCache` quando a resposta veio do cache, `hasPendingWrites` quando
/// ainda há escrita local por subir.
///
/// O documento observado é o do próprio usuário: ele existe sempre que há
/// sessão, é minúsculo e as rules já o liberam para o dono. O `ref.watch` do
/// uid é o que faz o observador ser refeito a cada troca de sessão.
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final String? uid = ref.watch(sessionUidProvider).valueOrNull;

  ref.watch(sessionResetProvider);

  // Sem sessão não há o que sincronizar, e a tela de login não deve ganhar
  // uma tarja de "sem conexão".
  if (uid == null) return Stream<SyncStatus>.value(SyncStatus.online);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots(includeMetadataChanges: true)
      .map((snapshot) => syncStatusOf(snapshot.metadata))
      .distinct()
      // O `settleWrite` precisa saber se estamos offline para decidir quanto
      // tempo esperar pelo servidor, e ele roda nos repositórios, longe de um
      // `ref`. A trava guarda a última leitura para ele.
      .map((status) {
        SyncStatusLatch.update(status);
        return status;
      });
});

/// Quantas escritas foram dadas como pendentes e ainda não se resolveram.
///
/// Complementa o [syncStatusProvider]: os metadados do Firestore só falam do
/// documento observado, e a escrita pendente pode estar em qualquer coleção.
final pendingWriteCountProvider = StreamProvider<int>(
  (ref) => PendingWrites.changes,
);

/// Traduz os metadados de um snapshot para o estado que a tarja mostra.
///
/// Fica separado do provider para o teste poder exercitar as combinações sem
/// um Firestore vivo. A ordem importa: offline vence pendência, porque é a
/// informação acionável ("você está sem rede"); dizer "sincronizando" a quem
/// está sem rede seria prometer algo que não vai acontecer agora.
SyncStatus syncStatusOf(SnapshotMetadata metadata) {
  if (metadata.isFromCache) return SyncStatus.offline;
  if (metadata.hasPendingWrites) return SyncStatus.pendingWrites;

  return SyncStatus.online;
}

/// O que a tarja deve mostrar, juntando as duas fontes.
///
/// [fromMetadata] fala do documento observado; [pendingCount] cobre escritas
/// pendentes em qualquer outra coleção. Offline continua vencendo: é a
/// informação acionável.
SyncStatus effectiveSyncStatus(SyncStatus fromMetadata, int pendingCount) {
  if (fromMetadata != SyncStatus.online) return fromMetadata;

  return pendingCount > 0 ? SyncStatus.pendingWrites : SyncStatus.online;
}

/// Última leitura conhecida do estado de sincronização.
///
/// É um cache de algo observável, não uma segunda fonte de verdade: quem manda
/// é o [syncStatusProvider], e isto existe só porque `settleWrite` roda dentro
/// dos repositórios, onde não há `ref` para observar nada.
///
/// Fica em "online" enquanto ninguém tiver observado o provider. É o palpite
/// certo para errar: na dúvida, esperamos a confirmação do servidor em vez de
/// dar uma escrita como guardada.
abstract final class SyncStatusLatch {
  static SyncStatus _current = SyncStatus.online;

  static SyncStatus get current => _current;

  /// true quando o Firestore está respondendo pelo cache.
  static bool get isOffline => _current == SyncStatus.offline;

  static void update(SyncStatus status) => _current = status;

  /// Volta ao palpite inicial.
  ///
  /// Na troca de sessão: o estado de sincronização de uma conta não diz nada
  /// sobre a próxima.
  static void reset() => _current = SyncStatus.online;
}
