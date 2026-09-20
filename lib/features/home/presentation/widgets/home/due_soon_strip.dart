import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_durations.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/widgets/money_text.dart';
import 'package:funances/features/home/domain/models/due_soon_model.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:go_router/go_router.dart';

/// O que vence hoje e amanhã, em uma linha que expande.
///
/// É o bloco que faltava na Home. "Quanto sobra no mês" responde se dá para
/// gastar; ele não responde o que precisa ser resolvido HOJE — e era
/// exatamente isso que obrigava a abrir o Histórico e conferir conta por
/// conta. A janela é de dois dias porque o bloco existe para o que ainda dá
/// tempo de resolver antes de virar atraso; sete dias viram uma lista que
/// ninguém lê, e o que vence hoje se perde no meio dela.
///
/// Fechado, diz quantos compromissos e quanto somam. Aberto, lista cada um
/// com o dia e o valor. Quando não há nada, a linha SOME: um bloco que diz
/// "nada vence" todo dia gasta a única coisa que a Home não tem sobrando, que
/// é altura.
class DueSoonStrip extends ConsumerStatefulWidget {
  const DueSoonStrip({super.key, this.initiallyExpanded = false});

  final bool initiallyExpanded;

  @override
  ConsumerState<DueSoonStrip> createState() => _DueSoonStripState();
}

class _DueSoonStripState extends ConsumerState<DueSoonStrip> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final due = ref.watch(JourneyViewProviders.dueSoon).valueOrNull;

    // Enquanto carrega (ou se der erro) a linha não existe. Não há ação do
    // usuário que resolva, e um esqueleto cinza no topo da Home pesaria mais
    // do que a informação que ele promete.
    if (due == null || due.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final palette = context.palette;
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Container(
        decoration: BoxDecoration(
          color: palette.paper,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: palette.line),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              button: true,
              expanded: _expanded,
              label: l10n.dueSoonSemantics(due.items.length),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: AppRadius.brMd,
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.event_outlined,
                          size: 18,
                          color: palette.warningText,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            l10n.dueSoonTitle,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: palette.ink,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        MoneyText(
                          due.total,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: palette.ink,
                          ),
                        ),
                        AnimatedRotation(
                          turns: _expanded ? 0.25 : 0,
                          duration: AppDurations.respectingMotion(
                            context,
                            AppDurations.normal,
                          ),
                          curve: AppDurations.curve,
                          child: Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: palette.ink2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: _DueSoonList(due: due),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: AppDurations.respectingMotion(
                context,
                AppDurations.normal,
              ),
              sizeCurve: AppDurations.curve,
            ),
          ],
        ),
      ),
    );
  }
}

class _DueSoonList extends StatelessWidget {
  const _DueSoonList({required this.due});

  final DueSoon due;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        0,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in due.items)
            Padding(
              key: ValueKey(item.id),
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: InkWell(
                onTap: item.route == null
                    ? null
                    : () => context.push(item.route!),
                child: Row(
                  children: [
                    SizedBox(
                      width: 64,
                      child: Text(
                        item.day == DueDay.today
                            ? l10n.dueSoonToday
                            : l10n.dueSoonTomorrow,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: item.day == DueDay.today
                              ? palette.warningText
                              : palette.ink2,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.kind == DueKind.invoiceClosing
                            ? l10n.dueSoonInvoiceClosing(item.title)
                            : item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    MoneyText(
                      item.amount,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.ink2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
