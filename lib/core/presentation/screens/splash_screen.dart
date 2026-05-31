import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_gradients.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.backgroundGradient
        ),
        alignment: Alignment.center,
        child: Image.asset(
          'assets/logo/logo-horizontal.png',
          height: 150,
        ),
      ),
    );
  }
}
