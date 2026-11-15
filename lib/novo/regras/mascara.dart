import 'package:flutter/services.dart';

/// Texto de um valor em reais a partir dos dígitos digitados, com os dois
/// últimos sempre como centavos: `1` → `0,01`, `1234` → `12,34`,
/// `123456` → `1.234,56`. Sem dígito (ou só zeros) fica vazio.
String mascararValor(String texto, {bool comSinal = false}) {
  final digitos = texto.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^0+'), '');
  // Até R$ 999.999.999,99: mais que isso é dedo preso na tecla.
  final uteis = digitos.length > 11 ? digitos.substring(0, 11) : digitos;
  if (uteis.isEmpty) {
    // Saldo zero é um valor válido nos campos com sinal: `0` vira `0,00`.
    // Apagar um caractere de `0,00` deixa dois zeros, e aí o campo esvazia.
    final zeros = texto.replaceAll(RegExp(r'\D'), '').length;
    return comSinal && zeros != 0 && zeros != 2 ? '0,00' : '';
  }
  final cheio = uteis.padLeft(3, '0');
  final reais = cheio.substring(0, cheio.length - 2);
  final comMilhar = reais.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  final negativo = comSinal && texto.contains('-');
  return '${negativo ? '-' : ''}$comMilhar,${cheio.substring(cheio.length - 2)}';
}

/// Máscara monetária para campos de valor: a pessoa só digita números e o
/// campo põe vírgula e pontos. Com [comSinal], um `-` em qualquer lugar deixa
/// o valor negativo (saldo de conta que começa devendo, por exemplo).
class MascaraDeValor extends TextInputFormatter {
  const MascaraDeValor({this.comSinal = false});
  final bool comSinal;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final texto = mascararValor(newValue.text, comSinal: comSinal);
    // O cursor fica sempre no fim: os dígitos entram pela direita.
    return TextEditingValue(text: texto, selection: TextSelection.collapsed(offset: texto.length));
  }
}
