import 'package:cloud_functions/cloud_functions.dart';
import 'package:funances/core/exceptions/business_exception.dart';

/// Mensagem a exibir para um erro vindo de um callable das Functions.
///
/// Três códigos trazem texto escrito para o usuário final e por isso vencem o
/// texto genérico da tela:
///
/// - `resource-exhausted`: limite diário de IA, com quantas análises restam e
///   quando a cota volta;
/// - `invalid-argument`: o servidor recusou o que foi enviado (arquivo grande
///   demais, formato não suportado, payload fora do contrato);
/// - `not-found`: o que a tela pediu não existe mais (conta, workspace,
///   documento de upload).
///
/// Qualquer outro código cai no [fallback] da própria tela: `internal`,
/// `unknown` e afins carregam detalhe de implementação, que não é mensagem
/// para o usuário.
///
/// [offlineMessage], quando informado, vence tudo se a chamada nem chegou ao
/// servidor. Um callable não tem o cache que as leituras do Firestore têm: sem
/// rede ele simplesmente falha, e o texto genérico da tela ("não foi possível
/// analisar o extrato") mandava o usuário tentar de novo sem dizer que o que
/// faltava era conexão.
String callableErrorMessage(
  Object error,
  String fallback, {
  String? offlineMessage,
}) {
  final functionsError = _asFunctionsException(error);
  if (functionsError == null) return fallback;

  if (offlineMessage != null && isOfflineCallable(functionsError)) {
    return offlineMessage;
  }

  if (!_userFacingCodes.contains(functionsError.code)) return fallback;

  final message = functionsError.message?.trim();
  if (message == null || message.isEmpty) return fallback;

  return message;
}

/// true quando a chamada não chegou ao servidor por falta de rede.
///
/// Os códigos diferem por plataforma: fora da web o SDK devolve `unavailable`,
/// e na web, onde por baixo é um `fetch`, a falha de rede chega como `internal`
/// sem mensagem do servidor. É por isso que `internal` só conta como offline
/// quando vem vazio — com texto, ele é erro de verdade do backend e deve cair
/// no fallback da tela.
bool isOfflineCallable(Object error) {
  final functionsError = _asFunctionsException(error);
  if (functionsError == null) return false;

  final String? message = functionsError.message?.trim();

  return switch (functionsError.code) {
    'unavailable' || 'deadline-exceeded' => true,
    'internal' => message == null || message.isEmpty,
    _ => false,
  };
}

/// true quando o erro é o limite diário de uso de IA estourado.
bool isQuotaExhausted(Object error) =>
    _asFunctionsException(error)?.code == _resourceExhausted;

/// O erro do callable por baixo.
///
/// Os repositórios convertem falhas em `BusinessException` para a camada de
/// domínio não conhecer o Firebase, mas guardam o erro original — é lá que
/// estão o código e a mensagem do servidor.
FirebaseFunctionsException? _asFunctionsException(Object error) {
  if (error is FirebaseFunctionsException) return error;

  if (error is BusinessException) {
    final original = error.originalError;
    if (original is FirebaseFunctionsException) return original;
  }

  return null;
}

const String _resourceExhausted = 'resource-exhausted';

const Set<String> _userFacingCodes = {
  _resourceExhausted,
  'invalid-argument',
  'not-found',
};
