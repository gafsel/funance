import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/core/widgets/money_text.dart';
import 'package:funances/core/presentation/display_names.dart';
import 'package:funances/features/arena/domain/models/arena_state.dart';
import 'package:funances/features/arena/presentation/widgets/hud_account_logo.dart';
import 'package:go_router/go_router.dart';

/// De onde vem a vida dos heróis: conta por conta, do domingo até agora.
///
/// A folha existe para responder à única pergunta que a barra provoca —
/// "por que eu perdi vida?". Cada linha mostra o saldo de PARTIDA, o de
/// AGORA e a diferença; o rodapé fecha a conta com o comprometido e o que
/// sobra livre, que é o número que o cabeçalho da Jornada mostrava antes de a
/// Arena tomar o lugar dele.
class ArenaHeroesSheet extends StatelessWidget {
  const ArenaHeroesSheet({super.key, required this.state});

  final ArenaState state;

  static Future<void> show(BuildContext context, ArenaState state) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brSheet),
      builder: (context) => ArenaHeroesSheet(state: state),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final l10n = context.l10n;
    final locale = context.locale;

    return SafeArea(
      child: Padding(
        padding: AppSpacing.allMd,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.arenaHeroesSheetTitle, style: theme.textTheme.titleLarge),
            AppSpacing.gapXxs,
            Text(
              l10n.arenaHeroesSheetSubtitle(
                state.initialBalance.asCurrency(locale: locale),
              ),
              style: theme.textTheme.bodySmall?.copyWith(color: palette.ink2),
            ),
            AppSpacing.gapSm,
            if (state.accounts.isEmpty)
              Padding(
                padding: AppSpacing.vMd,
                child: Text(
                  l10n.arenaNoAccounts,
                  style: theme.textTheme.bodyMedium,
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: state.accounts.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) =>
                      _AccountRow(life: state.accounts[index]),
                ),
              ),
            const Divider(),
            _Total(
              label: l10n.arenaHeroLife,
              value: state.currentBalance,
              strong: true,
            ),
            _Total(label: l10n.arenaCommitted, value: -state.committed),
            // "Livre −R\$ 9.007,31" é uma contradição em dois caracteres: o
            // que é livre não é negativo. Quando o caixa não cobre os
            // compromissos, o rótulo muda de nome e o número vira positivo —
            // é uma FALTA, e falta se mede para cima.
            if (state.freeBalance < 0)
              _Total(
                label: l10n.arenaShortfallLabel,
                value: -state.freeBalance,
                strong: true,
                tone: palette.dangerText,
              )
            else
              _Total(
                label: l10n.arenaFree,
                value: state.freeBalance,
                strong: true,
              ),
            if (state.healedThisWeek > 0)
              _Total(label: l10n.arenaHealed, value: state.healedThisWeek),
            // A CAUSA. Um rombo sem culpado manda a pessoa procurar sozinha
            // em quatro telas; a linha abaixo já entrega o nome, o valor e o
            // atraso do compromisso que mais pesa.
            if (state.freeBalance < 0) ...[
              AppSpacing.gapXs,
              _Cause(state: state),
            ],
          ],
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.life});

  final ArenaAccountLife life;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final locale = context.locale;

    final delta = life.delta;
    final deltaColor = delta > 0
        ? palette.successText
        : delta < 0
        ? palette.dangerText
        : palette.ink2;

    return InkWell(
      // O extrato é a tela de detalhe que a conta tem hoje — a mesma que a
      // lista de contas da Visão Geral abre.
      onTap: () => context.push('/accounts/${life.accountId}/statement'),
      child: Padding(
        padding: AppSpacing.vXs,
        child: Row(
          children: [
            // A MESMA marca da Visão Geral: logo do banco e os donos. É a
            // lista que define o HP dos heróis, e reconhecer a conta pelo
            // desenho é mais rápido do que ler o nome dela.
            HudAccountLogo(accountId: life.accountId),
            AppSpacing.gapXs,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    life.name,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    // "5.200,00 → 3.980,00": a seta é a semana inteira em um
                    // caractere.
                    '${life.initial.asCurrency(locale: locale)} → '
                    '${life.current.asCurrency(locale: locale)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: palette.ink2,
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapXs,
            MoneyText.delta(
              delta,
              style: theme.textTheme.titleSmall?.copyWith(color: deltaColor),
            ),
          ],
        ),
      ),
    );
  }
}

/// A frase que explica o rombo.
class _Cause extends StatelessWidget {
  const _Cause({required this.state});

  final ArenaState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final l10n = context.l10n;
    final locale = context.locale;

    final maior = state.largestPending;
    if (maior == null) return const SizedBox.shrink();

    final nome = displayOr(maior.installment.description, l10n.noDescription);
    final valor = maior.remaining.asCurrency(locale: locale);
    final atraso = -maior.daysUntilDue;

    return Container(
      key: const ValueKey('arena-shortfall-cause'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: palette.dangerText.withValues(alpha: 0.08),
        borderRadius: AppRadius.brMd,
      ),
      child: Text(
        maior.isBehind && atraso > 0
            ? l10n.arenaShortfallCauseOverdue(nome, valor, atraso)
            : l10n.arenaShortfallCause(nome, valor),
        style: theme.textTheme.bodySmall?.copyWith(color: palette.ink),
      ),
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({
    required this.label,
    required this.value,
    this.strong = false,
    this.tone,
  });

  final String label;
  final double value;
  final bool strong;

  /// Cor explícita, para quando o assunto da linha é o problema.
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    final base = strong
        ? theme.textTheme.titleSmall
        : theme.textTheme.bodySmall?.copyWith(color: palette.ink2);
    final style = tone == null ? base : base?.copyWith(color: tone);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          MoneyText(value, style: style),
        ],
      ),
    );
  }
}
