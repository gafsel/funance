import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../theme/app_breakpoints.dart';
import '../theme/app_colors.dart';
import '../theme/app_durations.dart';
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
/// Quando não há nada a mostrar — nem toast na fila, nem confete no ar —,
/// devolve [child] sem embrulho nenhum.
class CelebrationOverlay extends StatefulWidget {
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

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();

  /// Altura de uma `AppBar` padrão.
  ///
  /// A camada mora acima do `Navigator` e não tem como perguntar se a rota
  /// corrente tem barra, nem qual a altura dela. `kToolbarHeight` é o valor
  /// que o `appBarTheme` do app usa em todas as telas; numa tela sem barra o
  /// toast apenas começa um pouco mais abaixo, que é um custo pequeno perto
  /// de tampar o botão de voltar.
  static const double _appBarClearance = kToolbarHeight;
}

class _CelebrationOverlayState extends State<CelebrationOverlay> {
  /// O confete continua na tela depois que o toast sai.
  ///
  /// A camada inteira era montada por `toasts.isNotEmpty`, então dispensar o
  /// último toast — tocando nele, que é o que se faz quando a conquista leva
  /// a algum lugar — arrancava o `ConfettiWidget` da árvore no meio do voo.
  bool _confettiVisible = false;

  /// Uma coisa por vez: primeiro o fim da EMISSÃO, depois a folga para as
  /// partículas que já saíram terminarem de cair.
  Timer? _tail;

  @override
  void initState() {
    super.initState();
    widget.confetti?.addListener(_onConfetti);
    // O estado é SEMEADO do controller, não assumido como parado.
    //
    // Na ordem de produção o `play()` acontece ANTES deste widget existir:
    // quem toca o confete é o mesmo `_emit` que enfileira a conquista, e é a
    // fila que faz o host montar a camada. Na primeira conquista da sessão o
    // overlay nascia com `_confettiVisible = false` e nunca mais recebia um
    // `notifyListeners` — o confete da PRIMEIRA celebração, que é a que mais
    // importa, não desenhava nunca.
    _syncFrom(widget.confetti);
  }

  @override
  void didUpdateWidget(CelebrationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.confetti != widget.confetti) {
      oldWidget.confetti?.removeListener(_onConfetti);
      widget.confetti?.addListener(_onConfetti);
      _syncFrom(widget.confetti);
    }
  }

  @override
  void dispose() {
    _tail?.cancel();
    widget.confetti?.removeListener(_onConfetti);
    super.dispose();
  }

  void _syncFrom(ConfettiController? controller) {
    if (controller?.state != ConfettiControllerState.playing) return;
    _confettiVisible = true;
    _armStop(controller!);
  }

  void _onConfetti() {
    final controller = widget.confetti;
    if (controller == null) return;

    if (controller.state == ConfettiControllerState.playing) {
      _armStop(controller);
      if (!_confettiVisible) setState(() => _confettiVisible = true);
      return;
    }

    if (!_confettiVisible) return;
    _scheduleHide();
  }

  /// Marca o fim da emissão.
  ///
  /// `ConfettiController.play()` liga o estado e NÃO o desliga sozinho —
  /// quem parava era ninguém. Sem isto a camada ficava montada para sempre,
  /// com o `ConfettiWidget` e o ticker dele vivos pelo resto da sessão: além
  /// do custo, qualquer `pumpAndSettle` num teste que passasse por uma
  /// conquista nunca assentava.
  void _armStop(ConfettiController controller) {
    _tail?.cancel();
    _tail = Timer(controller.duration, () {
      if (!mounted) return;
      // `stop()` notifica, e é o `_onConfetti` acima que agenda o sumiço.
      controller.stop();
    });
  }

  /// A folga para as partículas que já saíram terminarem de cair.
  void _scheduleHide() {
    _tail?.cancel();
    _tail = Timer(AppDurations.celebrate, () {
      if (mounted) setState(() => _confettiVisible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final toasts = widget.toasts;
    final confetti = widget.confetti;
    final child = widget.child;

    if (toasts.isEmpty && !_confettiVisible) return child;

    return Stack(
      children: [
        child,
        if (confetti != null && _confettiVisible)
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: confetti,
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
        if (toasts.isNotEmpty)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  CelebrationOverlay._appBarClearance + AppSpacing.xs,
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
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.xs,
                            ),
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
