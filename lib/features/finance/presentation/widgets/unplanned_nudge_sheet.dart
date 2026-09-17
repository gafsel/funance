import 'package:flutter/material.dart';
import 'package:funances/core/analytics/analytics_service.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/services/unplanned_nudge_service.dart';
import 'package:go_router/go_router.dart';

/// As respostas possíveis ao convite, como o analytics as vê.
abstract final class UnplannedNudgeAction {
  static const recurring = 'recurring';
  static const limit = 'limit';
  static const dismissed = 'dismissed';
}

/// O convite que aparece depois de um gasto fora do plano (F3.2).
///
/// Três saídas e nenhuma cobrança: virar recorrência (é todo mês), definir um
/// limite para a categoria, ou seguir a vida. A terceira existe porque a
/// maioria dos gastos avulsos é só isso — um gasto avulso — e um convite sem
/// saída fácil vira um pedágio.
class UnplannedNudgeSheet extends StatelessWidget {
  const UnplannedNudgeSheet({
    super.key,
    required this.nudge,
    required this.analytics,
  });

  final UnplannedNudge nudge;

  /// Recebido pronto, e não lido de um `ref`: o convite aparece DEPOIS que o
  /// formulário saiu da pilha, e o `WidgetRef` daquela tela já morreu nesse
  /// ponto.
  final AnalyticsService analytics;

  static Future<void> show(
    BuildContext context, {
    required UnplannedNudge nudge,
    required AnalyticsService analytics,
  }) async {
    // O "apareceu" é emitido aqui para nascer sempre pareado com a resposta:
    // logar no chamador deixaria o funil com respostas sem topo se alguém
    // esquecesse a chamada num caminho novo.
    try {
      await analytics.logUnplannedNudgeShown();
    } catch (_) {
      // Analytics não segura o convite.
    }

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) =>
          UnplannedNudgeSheet(nudge: nudge, analytics: analytics),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.locale;
    final theme = Theme.of(context);
    final suggestion = nudge.suggestedLimit;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppColors.successGold,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.unplannedNudgeTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.unplannedNudgeMessage(nudge.category.name),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            _Option(
              key: const ValueKey('nudge-recurring'),
              icon: Icons.event_repeat_rounded,
              title: l10n.unplannedNudgeRecurring,
              subtitle: l10n.unplannedNudgeRecurringDesc,
              onTap: () => _toRecurring(context),
            ),
            const SizedBox(height: 12),
            _Option(
              key: const ValueKey('nudge-limit'),
              icon: Icons.tune_rounded,
              title: l10n.unplannedNudgeLimit(nudge.category.name),
              subtitle: suggestion == null
                  ? l10n.unplannedNudgeLimitDescNoHistory
                  : l10n.unplannedNudgeLimitDesc(
                      suggestion.asCurrency(locale: locale),
                    ),
              onTap: () => _toLimit(context),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                key: const ValueKey('nudge-dismiss'),
                onPressed: () => _dismiss(context),
                child: Text(l10n.unplannedNudgeDismiss),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toRecurring(BuildContext context) {
    _log(UnplannedNudgeAction.recurring);

    // Agendamento, não realizado: a recorrência é um compromisso para frente.
    // O gasto que acabou de ser lançado continua de pé, sozinho.
    final uri = Uri(
      path: '/transactions/form',
      queryParameters: {
        'type': OrderType.expense.name,
        'status': InstallmentStatus.pending.name,
        'installmentType': InstallmentType.recurring.name,
        'amount': nudge.amount.toString(),
        // O dia da recorrência sai do vencimento do gasto que a inspirou.
        'date': nudge.dueDate.toIso8601String(),
        if (nudge.accountId != null) 'accountIdSource': nudge.accountId!,
      },
    );

    Navigator.of(context).pop();
    context.push(uri.toString(), extra: {'category': nudge.category});
  }

  void _toLimit(BuildContext context) {
    _log(UnplannedNudgeAction.limit);

    final suggestion = nudge.suggestedLimit;
    final uri = Uri(
      path: '/planning',
      queryParameters: {
        'type': nudge.category.type.name,
        'categoryId': nudge.category.id,
        if (suggestion != null) 'suggested': suggestion.toString(),
      },
    );

    Navigator.of(context).pop();
    context.push(uri.toString());
  }

  void _dismiss(BuildContext context) {
    _log(UnplannedNudgeAction.dismissed);
    Navigator.of(context).pop();
  }

  /// Analytics nunca pode derrubar a navegação: a falha morre aqui.
  void _log(String action) {
    analytics.logUnplannedNudgeConverted(action).catchError((_) {});
  }
}

class _Option extends StatelessWidget {
  const _Option({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: AppColors.deepTurquoise),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
