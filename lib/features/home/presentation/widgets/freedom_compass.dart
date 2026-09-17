import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/home/domain/models/financial_health_model.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:funances/l10n/app_localizations.dart';

/// Nome de cada componente, do vocabulário do produto.
String compassComponentLabel(AppLocalizations l10n, FreedomComponent c) =>
    switch (c) {
      FreedomComponent.folego => l10n.compassFolego,
      FreedomComponent.poupanca => l10n.compassPoupanca,
      FreedomComponent.disciplina => l10n.compassDisciplina,
      FreedomComponent.alivio => l10n.compassAlivio,
    };

String compassComponentDescription(
  AppLocalizations l10n,
  FreedomComponent c,
) => switch (c) {
  FreedomComponent.folego => l10n.compassFolegoDesc,
  FreedomComponent.poupanca => l10n.compassPoupancaDesc,
  FreedomComponent.disciplina => l10n.compassDisciplinaDesc,
  FreedomComponent.alivio => l10n.compassAlivioDesc,
};

String compassTierLabel(AppLocalizations l10n, FreedomTier tier) =>
    switch (tier) {
      FreedomTier.aprendiz => l10n.compassTierAprendiz,
      FreedomTier.guardiao => l10n.compassTierGuardiao,
      FreedomTier.estrategista => l10n.compassTierEstrategista,
      FreedomTier.mestre => l10n.compassTierMestre,
      FreedomTier.livre => l10n.compassTierLivre,
      FreedomTier.unknown => l10n.compassTierUnknown,
    };

IconData compassComponentIcon(FreedomComponent c) => switch (c) {
  FreedomComponent.folego => Icons.air_rounded,
  FreedomComponent.poupanca => Icons.savings_rounded,
  FreedomComponent.disciplina => Icons.rule_rounded,
  FreedomComponent.alivio => Icons.self_improvement_rounded,
};

/// Cor pela faixa do score. Não é decoração: é a leitura rápida de "vai bem"
/// ou "precisa de atenção" sem obrigar ninguém a interpretar o número.
Color compassScoreColor(double score) {
  if (score >= 75) return AppColors.success;
  if (score >= 50) return AppColors.vibrantTeal;
  if (score >= 25) return AppColors.antiqueGold;
  return AppColors.coralOrange;
}

/// A Bússola da Liberdade na Jornada.
///
/// Lê `workspaces/{w}.financialHealth`, que é calculado no servidor. Enquanto
/// o índice não existir (workspace novo, ou backend ainda não publicado), o
/// card diz que a bússola está sendo calibrada — não some e não quebra.
class FreedomCompassCard extends ConsumerWidget {
  const FreedomCompassCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(JourneyViewProviders.financialHealth);

    // Erro (regra do Firestore ainda não publicada, por exemplo) cai no mesmo
    // estado de "calibrando": não há ação do usuário que resolva, e uma tela
    // de erro só assustaria.
    final health = async.valueOrNull;

    if (health == null) {
      return _CompassShell(
        child: async.isLoading
            ? const _CompassLoading()
            : const _CompassCalibrating(),
      );
    }

    return _CompassShell(
      onTap: () => FreedomCompassSheet.show(context, health),
      child: _CompassContent(health: health),
    );
  }
}

class _CompassShell extends StatelessWidget {
  const _CompassShell({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.3,
        ),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _CompassLoading extends StatelessWidget {
  const _CompassLoading();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          context.l10n.compassTitle,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ],
    );
  }
}

class _CompassCalibrating extends StatelessWidget {
  const _CompassCalibrating();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Row(
      children: [
        const Icon(
          Icons.explore_outlined,
          color: AppColors.vibrantTeal,
          size: 32,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.compassCalibratingTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.compassCalibratingMessage,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompassContent extends StatelessWidget {
  const _CompassContent({required this.health});

  final FinancialHealth health;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final color = compassScoreColor(health.score);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              height: 56,
              width: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 56,
                    width: 56,
                    child: CircularProgressIndicator(
                      value: health.fraction,
                      strokeWidth: 6,
                      backgroundColor: color.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                  Text(
                    health.score.round().toString(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.compassTitle,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    compassTierLabel(l10n, health.tier),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
        const SizedBox(height: 16),
        for (final component in FreedomComponent.values)
          _ComponentBar(score: health.componentOf(component), kind: component),
      ],
    );
  }
}

class _ComponentBar extends StatelessWidget {
  const _ComponentBar({required this.kind, required this.score});

  final FreedomComponent kind;
  final FreedomComponentScore? score;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final value = score;
    final color = value == null
        ? theme.colorScheme.outlineVariant
        : compassScoreColor(value.score);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(compassComponentIcon(kind), size: 16, color: color),
          const SizedBox(width: 8),
          SizedBox(
            width: 82,
            child: Text(
              compassComponentLabel(l10n, kind),
              style: theme.textTheme.labelMedium,
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: value?.fraction ?? 0,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 28,
            child: Text(
              value == null ? '—' : value.score.round().toString(),
              textAlign: TextAlign.end,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A explicação de cada componente e o histórico dos últimos meses.
class FreedomCompassSheet extends ConsumerWidget {
  const FreedomCompassSheet({super.key, required this.health});

  final FinancialHealth health;

  static Future<void> show(BuildContext context, FinancialHealth health) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => FreedomCompassSheet(health: health),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.compassTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.compassScoreOf(
                health.score.round().toString(),
                compassTierLabel(l10n, health.tier),
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            for (final component in FreedomComponent.values)
              _ComponentExplanation(
                kind: component,
                score: health.componentOf(component),
              ),
            const SizedBox(height: 16),
            Text(
              l10n.compassHistoryTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const _CompassHistory(),
          ],
        ),
      ),
    );
  }
}

class _ComponentExplanation extends StatelessWidget {
  const _ComponentExplanation({required this.kind, required this.score});

  final FreedomComponent kind;
  final FreedomComponentScore? score;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.locale;
    final theme = Theme.of(context);
    final value = score;
    final color = value == null
        ? theme.colorScheme.outlineVariant
        : compassScoreColor(value.score);

    final detail = value == null ? null : _detail(l10n, locale, value);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(compassComponentIcon(kind), color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        compassComponentLabel(l10n, kind),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      value == null ? '—' : value.score.round().toString(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  compassComponentDescription(l10n, kind),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: theme.textTheme.labelMedium?.copyWith(color: color),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// A legenda com a unidade do componente. Cada um tem a sua, e só aparece
  /// quando o servidor publicou o número — sem ele, fica só a explicação.
  String? _detail(
    AppLocalizations l10n,
    String locale,
    FreedomComponentScore value,
  ) {
    return switch (kind) {
      FreedomComponent.folego =>
        value.months == null
            ? null
            : l10n.compassFolegoDetail(
                value.months!.toStringAsFixed(1),
              ),
      FreedomComponent.poupanca =>
        value.rate == null
            ? null
            : l10n.compassPoupancaDetail(
                value.rate!.asPercent(locale: locale),
              ),
      FreedomComponent.disciplina =>
        value.within == null || value.total == null
            ? null
            : l10n.compassDisciplinaDetail(value.within!, value.total!),
      FreedomComponent.alivio =>
        value.delta == null
            ? null
            : l10n.compassAlivioDetail(
                value.delta!.asSignedCurrency(locale: locale),
              ),
    };
  }
}

class _CompassHistory extends ConsumerWidget {
  const _CompassHistory();

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
            painter: _SparklinePainter(
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

/// Sparkline do índice. Sem biblioteca nova: são seis pontos e uma linha.
class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.scores, required this.color});

  final List<double> scores;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.length < 2) return;

    // Escala fixa de 0 a 100: o índice tem faixa conhecida, e escalar pelo
    // mínimo e máximo dos pontos transformaria uma oscilação de dois pontos
    // num gráfico dramático.
    double x(int i) => size.width * (i / (scores.length - 1));
    double y(double score) =>
        size.height * (1 - (score / 100).clamp(0.0, 1.0));

    final path = Path()..moveTo(x(0), y(scores.first));
    for (var i = 1; i < scores.length; i++) {
      path.lineTo(x(i), y(scores[i]));
    }

    final fill = Path.from(path)
      ..lineTo(x(scores.length - 1), size.height)
      ..lineTo(x(0), size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()..color = color.withValues(alpha: 0.12),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawCircle(
      Offset(x(scores.length - 1), y(scores.last)),
      4,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) =>
      oldDelegate.color != color || !_sameScores(oldDelegate.scores, scores);

  static bool _sameScores(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
