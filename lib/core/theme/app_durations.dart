import 'package:flutter/widgets.dart';

/// Três durações e duas curvas. Nada além disso.
///
/// [micro] é a resposta ao toque — o usuário não deve *perceber* a animação,
/// só sentir que o controle respondeu. [normal] é a transição de estado
/// visível: barra que cresce, bloco que expande, cor que muda. [celebrate] é
/// a única duração longa, e só a conquista tem direito a ela.
abstract final class AppDurations {
  static const Duration micro = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 220);
  static const Duration celebrate = Duration(milliseconds: 420);

  /// Quanto tempo um [RewardToast] fica na tela antes de sair sozinho.
  static const Duration toastDwell = Duration(milliseconds: 2600);

  /// Curva padrão de tudo que não é conquista.
  static const Curve curve = Curves.easeOutCubic;

  /// Curva de entrada de recompensa. O leve ultrapasso é o que faz o selo
  /// "pousar"; fora de conquista, ele só parece frouxo.
  static const Curve curveReward = Curves.easeOutBack;

  /// Curva de saída.
  static const Curve curveExit = Curves.easeInCubic;

  /// Devolve [d] ou [Duration.zero] quando o usuário pediu menos movimento.
  ///
  /// Toda animação do design system passa por aqui. `MediaQuery.disableAnimations`
  /// é o que o iOS ("Reduzir movimento"), o Android ("Remover animações") e o
  /// macOS reportam ao Flutter.
  static Duration respectingMotion(BuildContext context, Duration d) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false ? Duration.zero : d;

  /// `true` quando o usuário pediu para reduzir movimento.
  static bool reduceMotion(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}
