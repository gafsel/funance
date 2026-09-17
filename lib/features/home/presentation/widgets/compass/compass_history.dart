import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/presentation/retry.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/utils/error_messages.dart';
import 'package:funances/features/home/domain/models/financial_health_model.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:funances/features/home/presentation/widgets/compass/compass_labels.dart';
import 'package:funances/features/home/presentation/widgets/compass/compass_sparkline_painter.dart';

/// Os últimos meses do índice, no pé do sheet da Bússola: a linha e os dois
/// extremos.
///
/// Só a linha e os extremos — nunca os meses do meio. Com seis pontos num
/// espaço de celular, rotular todos vira uma fileira ilegível; o que o usuário
/// procura aqui é "de onde eu vim" e "onde eu estou".
class CompassHistory extends ConsumerWidget {
  const CompassHistory({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final async = ref.watch(JourneyViewProviders.healthHistory);

    if (async.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Falha de leitura NÃO é "ainda não há histórico": a segunda frase diz ao
    // usuário que ele não tem meses fechados, o que pode ser falso e não tem
    // o que fazer a respeito. Com o erro, a linha diz o que houve e oferece
    // tentar de novo.
    if (async.hasError) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              errorMessageFor(context, async.error),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Retry.healthHistory(ref),
            child: Text(l10n.retry),
          ),
        ],
      );
    }

    // Do mais antigo para o mais recente: a linha tem que andar para a
    // direita no tempo. O repositório entrega em ordem decrescente porque é
    // assim que a consulta limita aos últimos meses.
    final points = (async.valueOrNull ?? const <FinancialHealthPoint>[])
        .reversed
        .toList();

    if (points.length < 2) {
      return Text(
        l10n.compassHistoryEmpty,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 72,
          width: double.infinity,
          child: CustomPaint(
            key: const ValueKey('compass-sparkline'),
            painter: SparklinePainter(
              scores: points.map((p) => p.score).toList(),
              color: compassScoreColor(points.last.score),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Os dois extremos, cada um com o SEU mês e o SEU score empilhados.
        // Antes a linha era `06/2026   48 → 62   08/2026`: três textos do
        // mesmo tamanho e cor, em que os números soltos no meio não diziam a
        // qual mês pertenciam.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _HistoryEnd(point: points.first, alignEnd: false),
            Icon(
              Icons.arrow_right_alt_rounded,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            _HistoryEnd(point: points.last, alignEnd: true),
          ],
        ),
      ],
    );
  }

}

/// Um extremo do histórico: o mês em cima, pequeno e apagado; o score embaixo,
/// grande e na cor da faixa. Quem bate o olho lê o número; quem procura a
/// data acha logo acima dela.
class _HistoryEnd extends StatelessWidget {
  const _HistoryEnd({required this.point, required this.alignEnd});

  final FinancialHealthPoint point;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final month = monthLabel(point.monthKey);
    final score = point.score.round().toString();

    return Semantics(
      label: l10n.compassHistoryPoint(month, score),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: alignEnd
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            month,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            score,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: compassScoreColor(point.score),
            ),
          ),
        ],
      ),
    );
  }
}

/// `YYYY-MM` vira `MM/YYYY`. Sem `DateFormat` porque a chave já é a
/// identidade do mês e não precisa passar por um `DateTime`.
String monthLabel(String monthKey) {
  try {
    final (year, month) = DateTimeExtension.parseMonthKey(monthKey);
    return '${month.toString().padLeft(2, '0')}/$year';
  } catch (_) {
    return monthKey;
  }
}
