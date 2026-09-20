import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';

void main() {
  _sinalDeVariacao();
  group('NumExtensions.asCurrency', () {
    test('preserva centavos em pt_BR', () {
      // O intl usa espaço não-quebrável (U+00A0) entre símbolo e valor.
      expect(45.99.asCurrency(locale: 'pt_BR'), 'R\$ 45,99');
      expect(1234.56.asCurrency(locale: 'pt_BR'), 'R\$ 1.234,56');
      expect(102.35.asCurrency(locale: 'pt_BR'), 'R\$ 102,35');
    });

    test('preserva centavos em en_US', () {
      expect(1234.56.asCurrency(locale: 'en_US'), '\$1,234.56');
    });
  });

  group('ColorExtension.asColor', () {
    test('converte #RRGGBB', () {
      expect('#FF0000'.asColor(), const Color(0xFFFF0000));
    });

    test('converte #AARRGGBB', () {
      expect('#80FF0000'.asColor(), const Color(0x80FF0000));
    });

    test('valores inválidos caem no fallback sem lançar', () {
      expect('blue'.asColor(), AppColors.surfaceDeep);
      expect('#FFF'.asColor(), AppColors.surfaceDeep);
      expect(''.asColor(), AppColors.surfaceDeep);
      expect('rgba(1,2,3,0.5)'.asColor(), AppColors.surfaceDeep);
    });

    test('fallback customizado é respeitado', () {
      expect('invalid'.asColor(orElse: Colors.red), Colors.red);
    });
  });
}

/// baixo — `asSignedCurrency(0)` escrevia "+R$ 0,00".
///
/// O `+` afirma que algo subiu, e "+R$ 0,00" afirma uma subida de nada: uma
/// semana sem movimento aparecia na Bússola como se tivesse rendido alguma
/// coisa. É a mesma regra de `AppPalette.moneyInk`, que trata zero como
/// neutro de propósito — um saldo zerado não é uma boa nem uma má notícia.
void _sinalDeVariacao() {
  group('asSignedCurrency', () {
    test('zero não leva sinal', () {
      expect(0.asSignedCurrency(locale: 'pt_BR'), isNot(startsWith('+')));
      expect(0.0.asSignedCurrency(locale: 'pt_BR'), isNot(startsWith('+')));
      expect(
        (-0.0).asSignedCurrency(locale: 'pt_BR'),
        isNot(startsWith('+')),
      );
    });

    test('positivo leva, negativo já vem com o dele', () {
      expect(12.5.asSignedCurrency(locale: 'pt_BR'), startsWith('+'));
      expect(
        (-12.5).asSignedCurrency(locale: 'pt_BR'),
        isNot(startsWith('+')),
      );
    });
  });
}
