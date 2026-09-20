import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../theme/app_breakpoints.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A camada onde as conquistas aparecem.
///
/// Fica acima do `Navigator`, como a tarja de sincronização, para que XP
/// ganho dentro da Conciliação, do 50-30-20 ou do formulário de transação
/// seja visto — antes nada disso rendia toast, porque o único `ref.listen` do
/// app morava na `HomeScreen`.
///
/// Duas regras de posição, ambas aprendidas na tarja:
///
/// * **Alinhamento ao topo, abaixo da barra superior.** Uma camada colada
///   embaixo cobriria a barra inferior e o botão de lançar; foi por isso que
///   a tarja de sync empurra o conteúdo em vez de sobrepor. O toast é efêmero
///   e não pode empurrar nada, então sobe — mas colado no topo ele cobria a
///   `AppBar`, e com ela o nome do cofre, o selo de nível e o botão de voltar.
///   Ganhar uma badge no meio de um formulário tampava a saída da tela. Ele
///   desce [_appBarClearance] para ficar logo ABAIXO da barra.
/// * **Nada de `Tooltip` nem `ScaffoldMessenger` aqui dentro.** Os dois
///   precisam de um `Overlay`, que só existe abaixo do `Navigator`; usar um
///   derruba a tela inteira.
///
/// Quando a fila está vazia, devolve [child] sem embrulho nenhum.
class CelebrationOverlay extends StatelessWidget {
  const CelebrationOverlay({
    super.key,
    required this.child,
    required this.toasts,
    this.confetti,
  });

  final Widget child;

  /// Os toasts já montados e traduzidos, do mais antigo para o mais recente.
  final List<Widget> toasts;

  /// Confete das conquistas de peso. Antes existia em um lugar só — subir de
  /// nível, dentro da Home — e não acompanhava badge, missão nem patente.
  final ConfettiController? confetti;

  /// Altura de uma `AppBar` padrão.
  ///
  /// A camada mora acima do `Navigator` e não tem como perguntar se a rota
  /// corrente tem barra, nem qual a altura dela. `kToolbarHeight` é o valor
  /// que o `appBarTheme` do app usa em todas as telas; numa tela sem barra o
  /// toast apenas começa um pouco mais abaixo, que é um custo pequeno perto
  /// de tampar o botão de voltar.
  static const double _appBarClearance = kToolbarHeight;

  @override
  Widget build(BuildContext context) {
    if (toasts.isEmpty) return child;

    return Stack(
      children: [
        child,
        if (confetti != null)
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: confetti!,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 30,
              maxBlastForce: 40,
              minBlastForce: 10,
              emissionFrequency: 0.05,
              colors: const [
                AppColors.gold,
                AppColors.teal,
                AppColors.progressStart,
                AppColors.violet,
                AppColors.surfaceRaised,
              ],
            ),
          ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                _appBarClearance + AppSpacing.xs,
                AppSpacing.gutter,
                AppSpacing.xs,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppBreakpoints.medium,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      for (final toast in toasts)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: toast,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
