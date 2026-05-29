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

class Validations {
  final String? notEmptyMessage;
  final String? notNullMessage;
  final String? emailMessage;
  final String Function(int min)? lengthMinMessage;
  final String Function(int max)? lengthMaxMessage;

  Validations({
    this.notEmptyMessage,
    this.notNullMessage,
    this.emailMessage,
    this.lengthMinMessage,
    this.lengthMaxMessage,
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
}
