import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Como está a conversa do app com o servidor.
enum SyncStatus {
  /// Lendo e escrevendo no servidor. Nada a dizer ao usuário.
  online,

  /// Online, mas ainda há escrita local esperando confirmação.
  pendingWrites,

  /// Respondendo pelo cache. O app continua utilizável.
  offline,
}

/// Estado de sincronização, lido do próprio Firestore.
///
/// Não usamos um pacote de conectividade: ter Wi-Fi não é a mesma pergunta que
/// "o Firestore está conseguindo falar com o servidor", e é a segunda que
/// importa aqui. O SDK já responde isso nos metadados de qualquer snapshot —
/// `isFromCache` quando a resposta veio do cache, `hasPendingWrites` quando
/// ainda há escrita local por subir.
///
/// O documento observado é o do próprio usuário: ele existe sempre que há
/// sessão, é minúsculo e as rules já o liberam para o dono.
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  // Sem sessão não há o que sincronizar, e a tela de login não deve ganhar
  // uma tarja de "sem conexão".
  if (uid == null) return Stream<SyncStatus>.value(SyncStatus.online);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots(includeMetadataChanges: true)
      .map((snapshot) => syncStatusOf(snapshot.metadata))
      .distinct();
});

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
