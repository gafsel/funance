import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/exceptions/business_exception.dart';
import 'package:funances/features/auth/data/repositories/auth_repository_impl.dart';

/// Na web o Firebase Auth fala uma família de códigos que o app nunca tratou
/// (`popup-blocked`, `unauthorized-domain`, `popup-closed-by-user`): todos
/// caíam no `default` e viravam "Ocorreu um erro inesperado.", que não diz ao
/// dono do app se ele precisa liberar pop-up, autorizar o domínio ou ligar o
/// provedor no console.
void main() {
  group('o que é falha e o que não é', () {
    test('desistir de entrar não é erro', () {
      // Fechar a janela do Google é uma decisão do usuário. Isso subia como
      // exceção e virava snackbar vermelha dizendo que algo deu errado.
      expect(ErrorCode.signInCancelled.isInformational, isTrue);
    });

    test('estar a caminho do Google também não é', () {
      expect(ErrorCode.signInRedirecting.isInformational, isTrue);
    });

    test('recusa de verdade continua sendo falha', () {
      expect(ErrorCode.signInUnauthorizedDomain.isInformational, isFalse);
      expect(ErrorCode.wrongPassword.isInformational, isFalse);
      expect(ErrorCode.signInPopupBlocked.isInformational, isFalse);
      expect(ErrorCode.unknown.isInformational, isFalse);
    });
  });

  group('códigos de popup da web', () {
    test('popup bloqueado tem código próprio, e não "erro inesperado"', () {
      expect(authErrorCode('popup-blocked'), ErrorCode.signInPopupBlocked);
    });

    test('navegador sem suporte a popup entra no mesmo caminho', () {
      // É o código que navegadores embutidos (WebView de app, in-app browser)
      // devolvem; para o usuário o efeito é o mesmo de um popup bloqueado.
      expect(
        authErrorCode('operation-not-supported-in-this-environment'),
        ErrorCode.signInPopupBlocked,
      );
      expect(
        authErrorCode('web-storage-unsupported'),
        ErrorCode.signInPopupBlocked,
      );
    });

    test('fechar a janela é desistência, não falha', () {
      expect(authErrorCode('popup-closed-by-user'), ErrorCode.signInCancelled);
      expect(
        authErrorCode('cancelled-popup-request'),
        ErrorCode.signInCancelled,
      );
      expect(authErrorCode('user-cancelled'), ErrorCode.signInCancelled);
    });
  });

  group('erros de configuração do console', () {
    test('domínio não autorizado aponta para Authorized domains', () {
      expect(
        authErrorCode('unauthorized-domain'),
        ErrorCode.signInUnauthorizedDomain,
      );
    });

    test('provedor desligado tem mensagem própria', () {
      // Antes isto virava ErrorCode.unknown e o dono não tinha como saber que
      // faltava habilitar o provedor em Sign-in method.
      expect(
        authErrorCode('operation-not-allowed'),
        ErrorCode.signInProviderDisabled,
      );
    });

    test('mesmo e-mail em outro provedor deixou de ser genérico', () {
      expect(
        authErrorCode('account-exists-with-different-credential'),
        ErrorCode.accountExistsWithDifferentCredential,
      );
    });
  });

  group('códigos que já existiam continuam onde estavam', () {
    test('e-mail e senha', () {
      expect(authErrorCode('user-not-found'), ErrorCode.userNotFound);
      expect(authErrorCode('user-disabled'), ErrorCode.userNotFound);
      expect(authErrorCode('wrong-password'), ErrorCode.wrongPassword);
      expect(authErrorCode('invalid-credential'), ErrorCode.wrongPassword);
      expect(
        authErrorCode('email-already-in-use'),
        ErrorCode.emailAlreadyInUse,
      );
      expect(authErrorCode('weak-password'), ErrorCode.weakPassword);
      expect(authErrorCode('invalid-email'), ErrorCode.invalidEmail);
      expect(
        authErrorCode('network-request-failed'),
        ErrorCode.networkRequestFailed,
      );
    });

    test('keychain do iOS continua sendo lido da mensagem', () {
      expect(
        authErrorCode('internal-error', message: 'keychain-error: -34018'),
        ErrorCode.keychainError,
      );
    });

    test('código desconhecido ainda cai no genérico', () {
      expect(authErrorCode('algo-que-o-firebase-inventou'), ErrorCode.unknown);
    });
  });
}
