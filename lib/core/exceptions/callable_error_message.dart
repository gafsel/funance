import 'package:cloud_functions/cloud_functions.dart';

/// Mensagem a exibir para um erro vindo de um callable das Functions.
///
/// O servidor aplica limite diário nos recursos de IA e responde
/// `resource-exhausted` com uma mensagem já em português, dizendo quantas
/// análises restam e quando a cota volta. Essa mensagem é útil e específica,
/// então ela vence o texto genérico da tela.
///
/// Para qualquer outro código o comportamento não muda: cai no [fallback] da
/// própria tela, porque mensagens de erro internas do servidor não são feitas
/// para o usuário final.
String callableErrorMessage(Object error, String fallback) {
  if (error is! FirebaseFunctionsException) return fallback;
  if (error.code != _resourceExhausted) return fallback;

  final message = error.message?.trim();
  if (message == null || message.isEmpty) return fallback;

  return message;
}

/// true quando o erro é o limite diário de uso de IA estourado.
bool isQuotaExhausted(Object error) =>
    error is FirebaseFunctionsException && error.code == _resourceExhausted;

const String _resourceExhausted = 'resource-exhausted';
