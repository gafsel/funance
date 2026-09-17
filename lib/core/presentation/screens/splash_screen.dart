import 'dart:math';

import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_gradients.dart';

/// A primeira tela, enquanto o app decide para onde mandar o usuário.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppGradients.backgroundGradient,
        ),
        alignment: Alignment.center,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // A logo é horizontal e tinha só `height: 150`: numa janela
            // estreita ela estourava a largura e as pontas eram CORTADAS. O
            // teto de 360 mantém o tamanho de hoje em qualquer tela onde ele
            // já cabia; abaixo disso, ela encolhe em vez de sumir pelas
            // bordas.
            final maxWidth = min(360.0, constraints.maxWidth - 48);

            return ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: 150),
              child: Image.asset(
                'assets/logo/logo-horizontal.png',
                height: 150,
                fit: BoxFit.contain,
              ),
            );
          },
        ),
      ),
    );
  }
}
