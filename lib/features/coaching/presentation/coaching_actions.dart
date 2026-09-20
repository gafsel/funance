import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/analytics/analytics_providers.dart';
import 'package:funances/core/exceptions/callable_error_message.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/widgets/loading_modal.dart';
import 'package:funances/features/coaching/domain/models/coaching_model.dart';
import 'package:funances/features/coaching/presentation/providers.dart';
import 'package:funances/features/finance/presentation/widgets/analysis_loading_view.dart';
import 'package:go_router/go_router.dart';

/// Abrir o coach. Só isso — não é mais um widget.
///
/// Era o `CoachingInsightCard`: um cartão de 120px na Home, com uma variante
/// compacta de uma linha, e estas duas ações penduradas nele como `static`.
/// Quando a primeira aba virou a cena do jogo, o cartão e a linha deixaram de
/// ser montados em qualquer lugar; o que continuou vivo foram as ações, que
/// agora saem do ícone do coach na cena.
///
/// Um widget que ninguém renderiza é o pior tipo de código morto: ele
/// compila, tem teste, e no dia em que alguém procurar "onde fica o
/// coaching?" vai achar 400 linhas de cartão que a tela não usa. Restou a
/// decisão, sem a moldura.
sealed class CoachingActions {
  /// A última análise, quando ela ainda vale, ou uma nova.
  ///
  /// A regra estava escrita dentro da linha compacta da Home. Ela saiu de lá
  /// quando o ícone do coach apareceu na cena da Arena: duas portas para o
  /// coach com duas cópias da mesma decisão ("análise velha é análise que não
  /// serve") divergiriam na primeira vez que alguém mexesse numa delas.
  static Future<void> open(
    BuildContext context,
    WidgetRef ref,
    CoachingModel? insight,
  ) {
    if (insight != null && !insight.isDeprecated) {
      _logOpened(ref);
      return context.push('/coaching?id=${insight.id}');
    }

    return generateAndOpen(context, ref);
  }

  /// Gera uma análise nova e abre, com o modal de espera e o tratamento de
  /// falha.
  static Future<void> generateAndOpen(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final coaching = await showLoadingModal(
        context,
        ref.read(CoachingDomainProviders.service).generateCoaching(),
        child: AnalysisLoadingView(
          title: l10n.coachingConsulting,
          description: l10n.coachingConsultingDesc,
        ),
      );

      ref.invalidate(CoachingViewProviders.lastInsight);
      ref.invalidate(CoachingViewProviders.insightsHistory);

      if (context.mounted) {
        _logOpened(ref);
        unawaited(context.push('/coaching?id=${coaching.id}'));
      }
    } catch (e) {
      // Sem isso a falha era silenciosa: o modal fechava e nada acontecia
      // após minutos de espera.
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            callableErrorMessage(
              e,
              l10n.coachingError,
              offlineMessage: l10n.errorOfflineCallable,
            ),
          ),
        ),
      );
    }
  }

  /// Dispara o evento de funil sem bloquear a navegação nem deixar uma falha
  /// de analytics impedir o usuário de abrir o coaching.
  static void _logOpened(WidgetRef ref) {
    unawaited(
      ref.read(analyticsServiceProvider).logCoachingOpened().catchError((_) {}),
    );
  }
}
