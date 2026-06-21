import 'package:flutter/widgets.dart';

FormFieldValidator<T> _validate<T>(List<FormFieldValidator<T>> validators) {
  return (T? valor) {
    for (FormFieldValidator<T> val in validators) {
      var msg = val(valor);
      if (msg != null) {
        return msg;
      }
    }

    return null;
  };
}

extension FormFieldValidatorOps<T> on FormFieldValidator<T> {
  FormFieldValidator<T> and(FormFieldValidator<T> other) {
    return _validate([this, other]);
  }
}

class Validations {
  final String? notEmptyMessage;
  final String? notNullMessage;
  final String? emailMessage;
  final String Function(int min)? lengthMinMessage;
  final String Function(int max)? lengthMaxMessage;
  final String? securePasswordAtLeast8Characters;
  final String? securePasswordAtMost50Characters;
  final String? securePasswordDontUseSpaces;
  final String? securePasswordAtLeast1Uppercase;
  final String? securePasswordAtLeast1Lowercase;
  final String? securePasswordAtLeast1Number;

  Validations({
    this.notEmptyMessage,
    this.notNullMessage,
    this.emailMessage,
    this.lengthMinMessage,
    this.lengthMaxMessage,
    this.securePasswordAtLeast8Characters,
    this.securePasswordAtMost50Characters,
    this.securePasswordDontUseSpaces,
    this.securePasswordAtLeast1Uppercase,
    this.securePasswordAtLeast1Lowercase,
    this.securePasswordAtLeast1Number,
  });

  FormFieldValidator<T> all<T>(List<FormFieldValidator<T>> validators) {
    return _validate(validators);
  }

  FormFieldValidator<String> notEmpty({String? mensagem}) {
    return (String? valor) {
      if (valor == null || valor.isEmpty) {
        return mensagem ?? notEmptyMessage ?? "Campo obrigatório.";
      }

      return null;
    };
  }

  FormFieldValidator<T> notNull<T>({String? mensagem}) {
    return (T? valor) {
      if (valor == null) {
        return mensagem ?? notNullMessage ?? "Campo obrigatório.";
      }

      return null;
    };
  }

  FormFieldValidator<String> email({String? mensagem}) {
    return (String? valor) {
      if (valor != null &&
          valor.isNotEmpty &&
          !RegExp("^.+@.+\$").hasMatch(valor)) {
        return mensagem ?? emailMessage ?? "E-mail inválido.";
      }

      return null;
    };
  }

  FormFieldValidator<String> length({
    int? max,
    int? min,
    String? mensagemMax,
    String? mensagemMin,
  }) {
    return (String? valor) {
      if (valor != null && valor.isNotEmpty) {
        if (min != null && min > valor.length) {
          return mensagemMin ??
              lengthMinMessage?.call(min) ??
              "Deve possuir no mínimo $min caracteres.";
        }

        if (max != null && max < valor.length) {
          return mensagemMax ??
              lengthMaxMessage?.call(max) ??
              "Deve possuir no máximo $max caracteres.";
        }
      }

      return null;
    };
  }

  FormFieldValidator<String> securePassword() {
    return (value) {
      if (value != null) {
        if (value.length < 8) {
          return securePasswordAtLeast8Characters ??
              "Use ao menos 8 caracteres.";
        }

        if (value.length > 50) {
          return securePasswordAtMost50Characters ??
              "Use no máximo 50 caracteres.";
        }

        if (value.contains(' ')) {
          return securePasswordDontUseSpaces ?? "Não utilize espaços.";
        }

        if (!RegExp("[A-Z]").hasMatch(value)) {
          return securePasswordAtLeast1Uppercase ??
              "Use ao menos um caractere maiúsculo.";
        }

        if (!RegExp("[a-z]").hasMatch(value)) {
          return securePasswordAtLeast1Lowercase ??
              "Use ao menos um caractere minúsculo.";
        }

        if (!RegExp("[0-9]").hasMatch(value)) {
          return securePasswordAtLeast1Number ?? "Use ao menos um número.";
        }
      }

      return null;
    };
  }
}
