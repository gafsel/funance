import 'dart:async';

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
  const UnplannedNudgeSheet({super.key, required this.nudge});

  final UnplannedNudge nudge;

  /// Abre o convite e resolve o que o usuário escolheu.
  ///
  /// Todo o efeito colateral mora AQUI, e não nos botões, por dois motivos:
  ///
  /// 1. Fechar pelo scrim ou arrastando para baixo é uma resposta como
  ///    qualquer outra — e era a única que não emitia evento nenhum, o que
  ///    inflava artificialmente a taxa de conversão do funil. O sheet devolve
  ///    a ação escolhida, e a ausência de resposta É `dismissed`.
  /// 2. A navegação usa o contexto de QUEM ABRIU, que continua montado. Um
  ///    `context.push` a partir do contexto do sheet já desativado procura o
  ///    `InheritedGoRouter` num elemento morto.
  ///
  /// Devolve `true` se o sheet chegou a ser exibido — é o que autoriza o
  /// chamador a marcar a categoria como já convidada hoje.
  static Future<bool> show(
    BuildContext context, {
    required UnplannedNudge nudge,
    required AnalyticsService analytics,
  }) async {
    if (!context.mounted) return false;

    // O "apareceu" é emitido aqui para nascer sempre pareado com a resposta.
    await _log(analytics.logUnplannedNudgeShown());

    if (!context.mounted) return false;

    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => UnplannedNudgeSheet(nudge: nudge),
    );

    final chosen = action ?? UnplannedNudgeAction.dismissed;
    await _log(analytics.logUnplannedNudgeConverted(chosen));

    if (!context.mounted) return true;

    // `push` só completa quando a tela de destino for fechada; o convite não
    // espera por isso.
    switch (chosen) {
      case UnplannedNudgeAction.recurring:
        unawaited(context.push(_recurringRoute(nudge)));
      case UnplannedNudgeAction.limit:
        unawaited(context.push(_limitRoute(nudge)));
    }

    return true;
  }

  /// Agendamento, não realizado: a recorrência é um compromisso para frente.
  /// O gasto que acabou de ser lançado continua de pé, sozinho.
  static String _recurringRoute(UnplannedNudge nudge) {
    return Uri(
      path: '/transactions/form',
      queryParameters: {
        'type': OrderType.expense.name,
        'status': InstallmentStatus.pending.name,
        'installmentType': InstallmentType.recurring.name,
        'amount': nudge.amount.toString(),
        // A categoria vai pelo id: o formulário a carrega pelo provider, e o
        // endereço continua reabrindo a mesma tela depois de um refresh.
        'categoryId': nudge.category.id,
        // O dia da recorrência sai do vencimento do gasto que a inspirou.
        'date': nudge.dueDate.toIso8601String(),
        if (nudge.accountId != null) 'accountIdSource': nudge.accountId!,
      },
    ).toString();
  }

  static String _limitRoute(UnplannedNudge nudge) {
    final suggestion = nudge.suggestedLimit;

    return Uri(
      path: '/planning',
      queryParameters: {
        'type': nudge.category.type.name,
        'categoryId': nudge.category.id,
        if (suggestion != null) 'suggested': suggestion.toString(),
      },
    ).toString();
  }

  /// Analytics nunca pode derrubar nem segurar o convite.
  static Future<void> _log(Future<void> event) async {
    try {
      await event;
    } catch (_) {
      // Silencioso de propósito.
    }
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
              onTap: () => _choose(context, UnplannedNudgeAction.recurring),
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
              onTap: () => _choose(context, UnplannedNudgeAction.limit),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                key: const ValueKey('nudge-dismiss'),
                onPressed: () =>
                    _choose(context, UnplannedNudgeAction.dismissed),
                child: Text(l10n.unplannedNudgeDismiss),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Devolve a escolha para o [show], que é quem registra e navega.
  void _choose(BuildContext context, String action) {
    Navigator.of(context).pop(action);
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
