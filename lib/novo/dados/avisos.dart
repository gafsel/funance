import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/observability/app_logger.dart';
import '../../firebase_ambiente.dart';
import '../modelo/modelos.dart';
import 'provedores.dart';

/// Os tipos de aviso que a pessoa pode ligar e desligar, com o que cada um faz.
const tiposDeAviso = [
  ('vencimentos', 'Vencimentos do dia', 'Contas a pagar e a receber e faturas que vencem hoje. Às 8h.'),
  ('semLancar', 'Lembrete para lançar', 'Quando passa uma semana sem nenhum lançamento. Um por dia, às 8h.'),
  ('fimDeSemana', 'Limites antes do fim de semana', 'Sexta às 17h, se algo do estilo de vida está perto do limite ou passou.'),
];

/// Os últimos avisos do espaço, do mais novo para o mais antigo.
final avisosProvider = StreamProvider<List<Aviso>>((ref) {
  final espaco = ref.watch(espacoAtualProvider);
  if (espaco == null) return Stream.value(const []);
  return FirebaseFirestore.instance
      .collection('espacos')
      .doc(espaco.id)
      .collection('avisos')
      .orderBy('criadoEm', descending: true)
      .limit(30)
      .snapshots()
      .map((s) => [for (final d in s.docs) Aviso.deMapa(d.id, d.data())]);
});

DocumentReference<Mapa>? _usuario(String? uid) => uid == null ? null : FirebaseFirestore.instance.collection('usuarios').doc(uid);

/// O documento da pessoa: preferências de aviso, aparelhos e até quando leu.
final usuarioProvider = StreamProvider<Mapa>((ref) {
  final doc = _usuario(ref.watch(authProvider).valueOrNull?.uid);
  return doc == null ? Stream.value(const {}) : doc.snapshots().map((s) => s.data() ?? const {});
});

/// Quantos avisos chegaram depois da última vez que a pessoa abriu a lista.
final avisosNovosProvider = Provider<int>((ref) {
  final ate = instanteDe(ref.watch(usuarioProvider).valueOrNull?['avisosVistosEm']);
  final avisos = ref.watch(avisosProvider).valueOrNull ?? const <Aviso>[];
  return avisos.where((a) => a.criadoEm != null && (ate == null || a.criadoEm!.isAfter(ate))).length;
});

/// Liga ou desliga um tipo de aviso para a pessoa (em todos os espaços).
Future<void> definirAviso(String uid, String tipo, bool ligado) =>
    _usuario(uid)!.set({'avisos': {tipo: ligado}}, SetOptions(merge: true));

Future<void> marcarAvisosComoVistos(String uid) =>
    _usuario(uid)!.set({'avisosVistosEm': FieldValue.serverTimestamp()}, SetOptions(merge: true));

/// Como este aparelho está para receber notificações.
enum Aparelho { indisponivel, desligado, bloqueado, ligado }

/// Notificação fora do app, por enquanto, só existe na web (navegador ou app
/// instalado a partir dele). No modo local não há para onde registrar.
bool get _podeNotificar => kIsWeb && !usarEmuladores;

String _idDoAparelho(String token) => 'web-${token.hashCode.toUnsigned(32).toRadixString(16)}-${token.length}';

Future<Aparelho> situacaoDoAparelho(Mapa usuario) async {
  if (!_podeNotificar) return Aparelho.indisponivel;
  try {
    final permissao = (await FirebaseMessaging.instance.getNotificationSettings()).authorizationStatus;
    if (permissao == AuthorizationStatus.denied) return Aparelho.bloqueado;
    if (permissao != AuthorizationStatus.authorized) return Aparelho.desligado;
    final token = await FirebaseMessaging.instance.getToken();
    final aparelhos = usuario['aparelhos'];
    return token != null && aparelhos is Map && aparelhos.containsKey(_idDoAparelho(token)) ? Aparelho.ligado : Aparelho.desligado;
  } catch (erro, pilha) {
    AppLogger.error('Não deu para ver a permissão de notificação', erro, pilha);
    return Aparelho.indisponivel;
  }
}

/// Pede a permissão (se ainda não foi dada) e registra este aparelho para a
/// pessoa. Devolve como ficou.
Future<Aparelho> ligarAvisosNesteAparelho(String uid) async {
  if (!_podeNotificar) return Aparelho.indisponivel;
  try {
    final permissao = (await FirebaseMessaging.instance.requestPermission()).authorizationStatus;
    if (permissao == AuthorizationStatus.denied) return Aparelho.bloqueado;
    if (permissao != AuthorizationStatus.authorized) return Aparelho.desligado;
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return Aparelho.desligado;
    await _usuario(uid)!.set({
      'aparelhos': {
        _idDoAparelho(token): {'token': token, 'plataforma': 'web', 'em': FieldValue.serverTimestamp()},
      },
    }, SetOptions(merge: true));
    return Aparelho.ligado;
  } catch (erro, pilha) {
    AppLogger.error('Não deu para ligar as notificações neste aparelho', erro, pilha);
    return Aparelho.indisponivel;
  }
}

/// Tira este aparelho do cadastro: ele para de receber.
Future<void> desligarAvisosNesteAparelho(String uid) async {
  if (!_podeNotificar) return;
  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    await _usuario(uid)!.update({'aparelhos.${_idDoAparelho(token)}': FieldValue.delete()});
    await FirebaseMessaging.instance.deleteToken();
  } catch (erro, pilha) {
    AppLogger.error('Não deu para desligar as notificações neste aparelho', erro, pilha);
  }
}
