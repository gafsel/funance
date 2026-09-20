import 'package:flutter/material.dart';
import 'package:funances/core/presentation/display_names.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/core/widgets/money_text.dart';
import 'package:funances/features/arena/domain/models/arena_state.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_payment_sheet.dart';
import 'package:intl/intl.dart';

/// O que o monstro guarda: **todos** os compromissos da semana.
///
/// Os pagos ficam na lista, e não somem: sumir com eles faria a soma da folha
/// divergir do HP inicial da barra, e tiraria da tela a única prova visível
/// de que a semana andou. Eles aparecem com a marca do jogo — espada, corte
/// diagonal por cima da linha, texto riscado e cor apagada.
///
/// O botão **não** escreve nada por conta própria: ele abre a
/// [TransactionPaymentSheet], que é o caminho de quitação que o app já tem.
/// Uma POC que inventasse a própria escrita de parcela estaria testando o
/// código dela, não o produto.
class ArenaMonsterSheet extends StatelessWidget {
  const ArenaMonsterSheet({
    super.key,
    required this.state,
    required this.isBusiness,
  });

  final ArenaState state;

  /// Cofre de empresa: "contas a pagar" no lugar de "compromissos".
  final bool isBusiness;

  /// Devolve o compromisso QUITADO, quando houve quitação. É esse retorno que
  /// a Arena transforma em golpe.
  static Future<InstallmentModel?> show(
    BuildContext context,
    ArenaState state, {
    bool isBusiness = false,
  }) {
    return showModalBottomSheet<InstallmentModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brSheet),
      builder: (context) =>
          ArenaMonsterSheet(state: state, isBusiness: isBusiness),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final l10n = context.l10n;
    final locale = context.locale;

    final nextBlow = state.nextBlow;

    return SafeArea(
      child: Padding(
        padding: AppSpacing.allMd,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isBusiness
                  ? l10n.arenaMonsterSheetTitleBusiness
                  : l10n.arenaMonsterSheetTitle,
              style: theme.textTheme.titleLarge,
            ),
            AppSpacing.gapXxs,
            Text(
              l10n.arenaMonsterSheetSummary(
                state.paidSoFar.asCurrency(locale: locale),
                state.monsterMaxHp.asCurrency(locale: locale),
                state.monsterHp.asCurrency(locale: locale),
              ),
              style: theme.textTheme.bodySmall?.copyWith(color: palette.ink2),
            ),
            // O "próximo golpe" é o que era a faixa de "vence hoje e amanhã"
            // na Home. Ele desceu para cá: é informação do monstro, e na Home
            // ocupava altura repetindo o que a barra já dizia.
            if (nextBlow.isNotEmpty) ...[
              AppSpacing.gapSm,
              _NextBlow(items: nextBlow),
            ],
            AppSpacing.gapSm,
            if (state.commitments.isEmpty)
              Padding(
                padding: AppSpacing.vMd,
                child: Text(
                  l10n.arenaNoCommitments,
                  style: theme.textTheme.bodyMedium,
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: state.commitments.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) =>
                      _CommitmentRow(commitment: state.commitments[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// "Próximo golpe": o que vence hoje e amanhã, em uma linha.
class _NextBlow extends StatelessWidget {
  const _NextBlow({required this.items});

  final List<ArenaCommitment> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final l10n = context.l10n;

    // O que ainda FALTA das linhas que vencem agora: uma fatura já paga pela
    // metade cobra só o resto.
    final total = items.fold<double>(0, (sum, item) => sum + item.remaining);

    return Container(
      key: const ValueKey('arena-next-blow'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: palette.warningText.withValues(alpha: 0.10),
        borderRadius: AppRadius.brMd,
        border: Border.all(color: palette.warningText.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt_outlined, size: 18, color: palette.warningText),
          AppSpacing.gapXs,
          Expanded(
            child: Text(
              l10n.arenaNextBlow(items.length),
              style: theme.textTheme.labelMedium?.copyWith(color: palette.ink),
            ),
          ),
          MoneyText(
            total,
            style: theme.textTheme.titleSmall?.copyWith(color: palette.ink),
          ),
        ],
      ),
    );
  }
}

class _CommitmentRow extends StatelessWidget {
  const _CommitmentRow({required this.commitment});

  final ArenaCommitment commitment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final l10n = context.l10n;
    final installment = commitment.installment;

    // TRÊS estados, não dois. O golpe agendado — pago, mas com data no futuro
    // — não é nem "resolvido" nem "a resolver": ele está marcado. Tratá-lo
    // como pago riscava hoje uma linha que só sai do caixa na sexta.
    final struck = commitment.isStruck;
    final scheduled = commitment.isScheduledStrike;

    final ink = struck ? palette.ink3 : palette.ink;

    final row = Padding(
      padding: AppSpacing.vXs,
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: struck || scheduled
                ? palette.line
                : installment.category?.color.asColor().withValues(
                        alpha: 0.16,
                      ) ??
                      palette.line,
            // A espada é a marca do golpe DADO. Ela substitui o ícone da
            // categoria de propósito: a linha paga deixou de ser um assunto
            // de orçamento e virou um placar.
            //
            // Desenhada, e não escolhida do Material: o conjunto não tem
            // espada nenhuma, e a alternativa mais próxima (o martelo do
            // juiz) diz outra coisa.
            //
            // O golpe AGENDADO leva relógio: ele está marcado, não dado.
            // O PARCIAL leva meia espada: houve golpe, e o bicho continua de
            // pé — a espada inteira ali seria a mesma mentira que a barra
            // contava antes.
            child: struck
                ? SwordMark(color: palette.ink3, size: 16)
                : commitment.isPartial
                ? SwordMark(color: palette.warningText, size: 16, half: true)
                : Icon(
                    scheduled
                        ? Icons.schedule
                        : installment.isInvoice
                        ? Icons.credit_card
                        : installment.category?.icon.asIcon() ?? Icons.category,
                    size: 16,
                    color: scheduled
                        ? palette.ink2
                        : installment.category?.color.asColor() ?? palette.ink2,
                  ),
          ),
          AppSpacing.gapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayOr(installment.description, l10n.noDescription),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: ink,
                    decoration: struck ? TextDecoration.lineThrough : null,
                    decorationColor: palette.ink3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _when(context),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: commitment.isBehind
                        ? palette.dangerText
                        : commitment.isDueToday
                        ? palette.warningText
                        : palette.ink2,
                  ),
                ),
                // O que já foi pago, quando não foi tudo. Sem esta linha, a
                // fatura de R$ 12.130,09 com R$ 1.000 pagos parecia intocada.
                if (commitment.isPartial)
                  Text(
                    l10n.arenaPartiallyPaid(
                      commitment.struck.asCurrency(locale: context.locale),
                      commitment.planned.asCurrency(locale: context.locale),
                      commitment.remaining.asCurrency(locale: context.locale),
                    ),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: palette.warningText,
                    ),
                  ),
                // Pagou a mais: o excedente não derruba o monstro além do que
                // ele tinha, mas some da tela seria pior.
                if (commitment.overpaid > 0)
                  Text(
                    l10n.arenaOverpaid(
                      commitment.overpaid.asCurrency(locale: context.locale),
                    ),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: palette.successText,
                    ),
                  ),
              ],
            ),
          ),
          AppSpacing.gapXs,
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MoneyText(
                commitment.planned,
                style: theme.textTheme.titleSmall?.copyWith(color: ink),
              ),
              // O botão é para o que está PENDENTE. Uma linha com pagamento
              // parcial já tem status `paid` na base, e o caminho de quitação
              // do app é para quitar pendente: reabri-lo ali seria inventar
              // um fluxo que esta POC não verificou. O resto se resolve pela
              // edição do lançamento, e a folha garante a leitura certa.
              if (!commitment.isPaid)
                TextButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final result = await TransactionPaymentSheet.show(
                      context,
                      installment,
                    );

                    if (result == null) return;
                    // Fecha a folha DEVOLVENDO o compromisso quitado: é o
                    // sinal de que a Arena precisa para animar o golpe com o
                    // valor certo, sem ficar adivinhando pelo estado que
                    // chega depois.
                    navigator.pop(result);
                  },
                  child: Text(l10n.arenaConfirmPaid),
                ),
            ],
          ),
        ],
      ),
    );

    if (!struck) {
      // Atrasado é atrasado: o que venceu na quarta e continua pendente pesa
      // igual ao que ficou da semana passada. O que a semana passada tem de
      // diferente é o direito de enfurecer o monstro, não o destaque na
      // lista.
      return commitment.isBehind
          ? ColoredBox(
              color: palette.dangerText.withValues(alpha: 0.08),
              child: row,
            )
          : row;
    }

    // O corte: uma diagonal por cima da linha inteira. É o que transforma
    // "linha cinza" em "isso já foi resolvido", sem precisar de legenda.
    return CustomPaint(
      foregroundPainter: _SlashPainter(palette.ink3),
      child: Opacity(opacity: 0.75, child: row),
    );
  }

  String _when(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.locale;
    final installment = commitment.installment;
    final due = DateFormat.MMMEd(locale).format(installment.dueDate);

    if (commitment.isScheduledStrike) {
      // A data que importa aqui é a do PAGAMENTO, não a do vencimento: é ela
      // que diz quando o dinheiro sai.
      final when = installment.paidDate;
      return l10n.arenaScheduledOn(
        when == null ? due : DateFormat.MMMEd(locale).format(when),
      );
    }
    if (commitment.isPaid) return l10n.arenaPaidOn(due);
    if (commitment.isBehind) {
      return l10n.arenaOverdueSince(due, -commitment.daysUntilDue);
    }
    if (commitment.isDueToday) return l10n.dueSoonToday;
    if (commitment.isDueTomorrow) return l10n.dueSoonTomorrow;
    return due;
  }
}

/// O corte de espada sobre a linha paga.
class _SlashPainter extends CustomPainter {
  const _SlashPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Da borda de baixo à esquerda para a de cima à direita, com uma folga
    // nas pontas: um traço que encosta nas bordas lê como separador de lista.
    canvas.drawLine(
      Offset(size.width * 0.04, size.height * 0.82),
      Offset(size.width * 0.96, size.height * 0.18),
      paint,
    );
  }

  @override
  bool shouldRepaint(_SlashPainter oldDelegate) => oldDelegate.color != color;
}

/// A espada do golpe dado: lâmina na diagonal, guarda e punho.
///
/// Doze linhas de `Canvas` em vez de um asset: ela aparece num tamanho só,
/// numa tela só, e um PNG a mais no pacote custaria mais do que isto.
///
/// [half] desenha a lâmina pela metade — o golpe PARCIAL. Uma fatura de
/// R$ 12.130,09 paga em R$ 1.000 levou golpe, mas não caiu; a espada inteira
/// ali contaria a mesma mentira que a barra contava antes desta rodada.
class SwordMark extends StatelessWidget {
  const SwordMark({
    super.key,
    required this.color,
    this.size = 16,
    this.half = false,
  });

  final Color color;
  final double size;
  final bool half;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _SwordPainter(color, half: half),
  );
}

class _SwordPainter extends CustomPainter {
  const _SwordPainter(this.color, {required this.half});

  final Color color;
  final bool half;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final paint = Paint()
      ..color = color
      ..strokeWidth = s * 0.14
      ..strokeCap = StrokeCap.round;

    // Lâmina: do canto de baixo à esquerda para o de cima à direita. Na meia
    // espada ela para no meio do caminho.
    canvas.drawLine(
      Offset(s * 0.22, s * 0.80),
      half ? Offset(s * 0.54, s * 0.48) : Offset(s * 0.86, s * 0.16),
      paint,
    );
    // Guarda: perpendicular, perto do punho.
    canvas.drawLine(
      Offset(s * 0.12, s * 0.52),
      Offset(s * 0.48, s * 0.88),
      paint..strokeWidth = s * 0.11,
    );
    // Punho: o toco que sobra abaixo da guarda.
    canvas.drawLine(
      Offset(s * 0.10, s * 0.90),
      Offset(s * 0.28, s * 0.72),
      paint,
    );
  }

  @override
  bool shouldRepaint(_SwordPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.half != half;
}
