import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/core/widgets/money_text.dart';
import 'package:funances/features/arena/domain/models/arena_state.dart';
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
            _Total(
              label: l10n.arenaFree,
              value: state.freeBalance,
              strong: true,
            ),
            if (state.healedThisWeek > 0)
              _Total(label: l10n.arenaHealed, value: state.healedThisWeek),
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

class _Total extends StatelessWidget {
  const _Total({required this.label, required this.value, this.strong = false});

  final String label;
  final double value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    final style = strong
        ? theme.textTheme.titleSmall
        : theme.textTheme.bodySmall?.copyWith(color: palette.ink2);

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
