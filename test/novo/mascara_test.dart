import 'package:flutter_test/flutter_test.dart';
import 'package:funances/novo/regras/formatos.dart';
import 'package:funances/novo/regras/mascara.dart';

void main() {
  test('os dígitos entram pela direita, como centavos', () {
    expect(mascararValor('1'), '0,01');
    expect(mascararValor('12'), '0,12');
    expect(mascararValor('123'), '1,23');
    expect(mascararValor('123456'), '1.234,56');
    expect(mascararValor('123456789'), '1.234.567,89');
  });

  test('aceita o que já vem formatado e o que vem colado', () {
    expect(mascararValor('119,90'), '119,90');
    expect(mascararValor('1.234,56'), '1.234,56');
    expect(mascararValor(r'R$ 45,9'), '4,59');
    expect(mascararValor('abc'), '');
  });

  test('zeros à esquerda somem e apagar tudo esvazia o campo', () {
    expect(mascararValor('0,05'), '0,05');
    expect(mascararValor('0,00'), '');
    expect(mascararValor(''), '');
  });

  test('sinal só onde o campo permite', () {
    expect(mascararValor('-12345'), '123,45');
    expect(mascararValor('-12345', comSinal: true), '-123,45');
    expect(mascararValor('123-45', comSinal: true), '-123,45');
  });

  test('saldo zero cabe nos campos com sinal e dá para apagar', () {
    expect(mascararValor('0', comSinal: true), '0,00');
    expect(mascararValor('0,00', comSinal: true), '0,00');
    expect(mascararValor('0,0', comSinal: true), '');
    expect(mascararValor('0'), '');
  });

  test('o que a máscara escreve é lido de volta como o mesmo valor', () {
    for (final centavos in [1, 99, 100, 11990, 123456, 99999999999]) {
      expect(lerCentavos(mascararValor('$centavos')), centavos);
    }
  });

  test('no campo: digitar e apagar mantêm o cursor no fim', () {
    const mascara = MascaraDeValor();
    TextEditingValue digitar(String texto) =>
        mascara.formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: texto));
    expect(digitar('4590').text, '45,90');
    expect(digitar('4590').selection.baseOffset, 5);
    // Apagar o último dígito de "45,90" deixa "45,9", que vira 4,59.
    expect(digitar('45,9').text, '4,59');
  });
}
