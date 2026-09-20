import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/widgets/compass_strip.dart';
import 'package:funances/features/home/domain/models/financial_health_model.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:funances/features/home/presentation/widgets/compass/compass_labels.dart';
import 'package:funances/features/home/presentation/widgets/compass/freedom_compass_sheet.dart';

/// A Bússola na Home, em uma linha.
///
/// O bloco grande da Bússola continua existindo — ele abre ao tocar na linha,
/// e é onde moram os quatro componentes com explicação, o histórico e a
/// próxima patente. O que mudou é que ele deixou de pagar aluguel diário: o
/// índice muda uma vez por mês e ocupava um cartão inteiro da tela que o
/// usuário abre todo dia.
///
/// Enquanto o índice não existir (cofre novo, ou servidor que ainda não
/// publicou), a linha mostra um travessão e a patente "Em avaliação" — não
/// some e não vira erro, porque não há ação do usuário que resolva.
class CompassStripView extends ConsumerWidget {
  const CompassStripView({super.key, this.onGame = false});

  final bool onGame;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final health = ref.watch(JourneyViewProviders.financialHealth).valueOrNull;
    final history = ref
        .watch(JourneyViewProviders.healthHistory)
        .valueOrNull;

    final delta = _delta(health, history);

    return CompassStrip(
      title: l10n.compassStripTitle,
      score: health?.score,
      tierLabel: compassTierLabel(l10n, health?.tier ?? FreedomTier.unknown),
      delta: delta,
      deltaLabel: delta == null
          ? null
          : l10n.compassStripDelta(_signed(delta)),
      onGame: onGame,
      components: [
        for (final component
            in health?.components ?? const <FreedomComponentScore>[])
          CompassComponentData(
            label: compassComponentLabel(l10n, component.component),
            icon: compassComponentIcon(component.component),
            fraction: component.fraction,
          ),
      ],
      onOpenDetails: health == null
          ? null
          : () => FreedomCompassSheet.show(context, health),
      openDetailsLabel: l10n.compassStripOpen,
    );
  }

  /// Variação em pontos desde o ponto anterior do histórico — ou seja, desde
  /// o MÊS passado.
  ///
  /// `healthHistory` é uma série mensal (`monthKey`) e vem do mais recente
  /// para o mais antigo. Não há série semanal do índice: quando houver, é
  /// aqui e no texto do rótulo que o período muda, e não no widget, que não
  /// calcula período nenhum.
  ///
  /// Com menos de dois pontos não há variação a mostrar — e escrever "0" ali
  /// seria afirmar que nada mudou, o que é diferente de ainda não saber.
  static double? _delta(
    FinancialHealth? health,
    List<FinancialHealthPoint>? history,
  ) {
    if (health == null || history == null || history.length < 2) return null;
    final previous = history[1].score;
    final change = health.score - previous;
    return change.abs() < 0.5 ? null : change;
  }

  static String _signed(double value) =>
      '${value > 0 ? '+' : '−'}${value.abs().round()}';
}
