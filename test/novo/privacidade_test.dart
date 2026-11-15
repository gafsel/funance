import 'package:flutter_test/flutter_test.dart';
import 'package:funances/novo/regras/formatos.dart';
import 'package:funances/novo/regras/trava.dart';

void main() {
  tearDown(() => valoresOcultos = false);

  test('com o olho fechado os valores em reais somem', () {
    expect(reais(123456), r'R$ 1.234,56');
    valoresOcultos = true;
    expect(reais(123456), valorOculto);
    expect(reais(-500), valorOculto);
    expect(reaisCurtos(41200), valorOculto);
  });

  test('o que vai para dentro de um campo e o que a pessoa está digitando continuam visíveis', () {
    valoresOcultos = true;
    expect(reais(11990, comSimbolo: false), '119,90');
    expect(reais(11990, sempre: true), r'R$ 119,90');
  });

  test('a trava volta depois de cinco minutos fora, e só se estiver ligada', () {
    final saiu = DateTime(2026, 11, 16, 10, 0);
    DateTime depois(int minutos) => saiu.add(Duration(minutes: minutos));
    expect(deveTravarAoVoltar(travaLigada: true, saiuEm: saiu, agora: depois(4)), isFalse);
    expect(deveTravarAoVoltar(travaLigada: true, saiuEm: saiu, agora: depois(5)), isTrue);
    expect(deveTravarAoVoltar(travaLigada: false, saiuEm: saiu, agora: depois(60)), isFalse);
    expect(deveTravarAoVoltar(travaLigada: true, saiuEm: null, agora: depois(60)), isFalse);
  });
}
