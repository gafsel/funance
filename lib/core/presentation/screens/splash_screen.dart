import 'dart:math';

import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_gradients.dart';

/// A primeira tela, enquanto o app decide para onde mandar o usuário.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  /// Altura da logo. É o tamanho que a tela sempre teve, e o que vale em
  /// qualquer tela onde ele cabe.
  static const double logoHeight = 150;

  /// Respiro lateral mínimo, somando os dois lados.
  static const double _sideGutter = 48;

  /// Largura natural da logo nessa altura: o arquivo é 2400x902, então
  /// `150 * 2400 / 902` ≈ 399. Abaixo de `399 + 48` a tela é estreita demais
  /// e a logo precisa encolher.
  static const double naturalLogoWidth = logoHeight * 2400 / 902;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppGradients.background,
        ),
        alignment: Alignment.center,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // A logo é horizontal e tinha só `height: 150`. Ao contrário do
            // que a auditoria supôs, ela NÃO era cortada — `paintImage` já
            // reduz a escala para caber. O que faltava era o respiro: numa
            // tela estreita ela encostava nas duas bordas.
            //
            // O teto é só isso, um respiro: em qualquer tela a partir de
            // ~448px a logo mantém exatamente os 150 de altura e os ~399 de
            // largura de sempre. Um teto fixo mais baixo encolheria a logo em
            // tela larga, que é o oposto do que se quer.
            final maxWidth = max(0.0, constraints.maxWidth - _sideGutter);

            return ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Image.asset(
                'assets/logo/logo-horizontal.png',
                height: logoHeight,
                fit: BoxFit.contain,
              ),
            );
          },
        ),
      ),
    );
  }
}
