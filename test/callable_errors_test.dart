import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/exceptions/business_exception.dart';
import 'package:funances/core/exceptions/callable_error_message.dart';
import 'package:funances/features/finance/domain/services/statement_upload_limits.dart';

FirebaseFunctionsException _callableError(String code, String message) =>
    FirebaseFunctionsException(code: code, message: message);

/// Como os repositórios passaram a embrulhar a falha do callable: o erro
/// original vai junto, para o código e a mensagem do servidor sobreviverem.
BusinessException _wrapped(FirebaseFunctionsException error) =>
    BusinessException(
      ErrorCode.unknown,
      message: error.message,
      originalError: error,
    );

void main() {
  group('callableErrorMessage', () {
    test('mostra a mensagem do servidor em resource-exhausted', () {
      expect(
        callableErrorMessage(
          _callableError('resource-exhausted', 'Restam 0 análises hoje.'),
          'genérica',
        ),
        'Restam 0 análises hoje.',
      );
    });

    test('mostra a mensagem do servidor em invalid-argument', () {
      expect(
        callableErrorMessage(
          _callableError('invalid-argument', 'Arquivo maior que 10 MB.'),
          'genérica',
        ),
        'Arquivo maior que 10 MB.',
      );
    });

    test('mostra a mensagem do servidor em not-found', () {
      expect(
        callableErrorMessage(
          _callableError('not-found', 'Conta não encontrada.'),
          'genérica',
        ),
        'Conta não encontrada.',
      );
    });

    test('erro interno continua caindo no texto da tela', () {
      expect(
        callableErrorMessage(
          _callableError('internal', 'TypeError: cannot read property x'),
          'genérica',
        ),
        'genérica',
      );
    });

    test('mensagem vazia cai no texto da tela', () {
      expect(
        callableErrorMessage(_callableError('invalid-argument', '   '), 'genérica'),
        'genérica',
      );
    });

    test('atravessa o BusinessException que o repositório levanta', () {
      final error = _wrapped(
        _callableError('invalid-argument', 'Arquivo maior que 10 MB.'),
      );

      expect(
        callableErrorMessage(error, 'genérica'),
        'Arquivo maior que 10 MB.',
        reason: 'antes a tela mostrava "ErrorCode.unknown"',
      );
    });

    test('BusinessException sem erro de callable por baixo usa o fallback', () {
      expect(
        callableErrorMessage(BusinessException(ErrorCode.unknown), 'genérica'),
        'genérica',
      );
    });

    test('isQuotaExhausted enxerga o erro embrulhado', () {
      expect(
        isQuotaExhausted(_wrapped(_callableError('resource-exhausted', 'x'))),
        isTrue,
      );
      expect(
        isQuotaExhausted(_wrapped(_callableError('invalid-argument', 'x'))),
        isFalse,
      );
    });
  });

  group('StatementUploadLimits', () {
    test('o limite é 10 MB', () {
      expect(StatementUploadLimits.maxBytes, 10 * 1024 * 1024);
      expect(StatementUploadLimits.maxMegabytes, 10);
    });

    test('arquivo exatamente no limite passa', () {
      expect(
        StatementUploadLimits.isWithinLimit(StatementUploadLimits.maxBytes),
        isTrue,
      );
    });

    test('um byte acima do limite não passa', () {
      expect(
        StatementUploadLimits.isWithinLimit(StatementUploadLimits.maxBytes + 1),
        isFalse,
      );
    });

    test('extensão é comparada sem diferenciar maiúsculas', () {
      expect(
        StatementUploadLimits.isAllowedExtension('Extrato.PDF', ['pdf', 'ofx']),
        isTrue,
      );
    });

    test('extensão fora da lista não passa', () {
      expect(
        StatementUploadLimits.isAllowedExtension('extrato.xlsx', ['pdf', 'ofx']),
        isFalse,
      );
    });

    test('nome sem extensão não passa', () {
      expect(
        StatementUploadLimits.isAllowedExtension('extrato', ['pdf']),
        isFalse,
      );
      expect(
        StatementUploadLimits.isAllowedExtension('extrato.', ['pdf']),
        isFalse,
      );
    });

    test('ponto no meio do nome não confunde a extensão', () {
      expect(
        StatementUploadLimits.isAllowedExtension(
          'extrato.janeiro.2026.ofx',
          ['pdf', 'ofx'],
        ),
        isTrue,
      );
    });
  });
}
