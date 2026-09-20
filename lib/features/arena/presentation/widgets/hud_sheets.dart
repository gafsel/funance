import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/money/money.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/core/widgets/app_progress_bar.dart';
import 'package:funances/core/widgets/money_text.dart';
import 'package:funances/features/arena/domain/models/hud_state.dart';
import 'package:funances/features/arena/presentation/widgets/hud_format.dart';
import 'package:funances/features/arena/presentation/widgets/hud_glyph.dart';
import 'package:go_router/go_router.dart';

/// As quatro folhas de detalhe do rodapé mensal.
///
/// Todas abrem do mesmo jeito e pela mesma porta ([_HudSheet]), e isso é
/// produto e não economia de código: as quatro respondem à mesma pergunta —
/// "de onde saiu este ícone?" — e uma delas com layout próprio faria o
/// usuário reaprender a ler a cada toque.
///
/// A ordem de cada folha é sempre a mesma: **o número grande**, a **mini
/// explicação em três partes** — jogo, financeiro e XP — e só então as linhas
/// que compõem o número. A explicação vem ANTES da lista, e não depois: ela é
/// o que a folha existe para entregar na primeira vez, e uma lista de dezoito
/// aldeões empurraria as três frases para fora da tela justamente para quem
/// nunca as leu.
abstract final class HudSheets {
  static Future<void> potion(BuildContext context, HudState hud) {
    return _show(context, (context) => _PotionSheet(hud: hud));
  }

  static Future<void> village(
    BuildContext context,
    HudState hud, {
    required bool isBusiness,
  }) {
    return _show(
      context,
      (context) => _VillageSheet(hud: hud, isBusiness: isBusiness),
    );
  }

  static Future<void> egg(BuildContext context, HudState hud) {
    return _show(context, (context) => _EggSheet(hud: hud));
  }

  static Future<void> drop(BuildContext context, HudState hud) {
    return _show(context, (context) => _DropSheet(hud: hud));
  }

  static Future<void> _show(BuildContext context, WidgetBuilder builder) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brSheet),
      builder: builder,
    );
  }
}

/// O esqueleto de uma folha do HUD.
class _HudSheet extends StatelessWidget {
  const _HudSheet({
    required this.slot,
    required this.title,
    required this.headline,
    required this.color,
    required this.explanation,
    required this.children,
    this.subtitle,
    this.stage = 0,
    this.progress = 0,
  });

  final HudSlot slot;
  final String title;

  /// O número grande: o total, a razão, a contagem de aldeões.
  final Widget headline;

  final String? subtitle;
  final Color color;
  final int stage;
  final double progress;

  /// As três frases: jogo, financeiro e XP.
  final List<String> explanation;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return SafeArea(
      // A chave nomeia a folha para o golden: as quatro são a mesma classe,
      // e sem ela um PNG não sabe dizer qual delas fotografou.
      key: ValueKey('hud-sheet-${slot.name}'),
      child: Padding(
        padding: AppSpacing.allMd,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // O MESMO ícone da faixa, no mesmo estado. É o que liga o
                // toque ao que ele abriu: uma folha que começa com outro
                // desenho faz o usuário conferir se apertou o certo.
                HudRing(
                  progress: progress,
                  color: color,
                  size: 44,
                  stroke: 3.5,
                  child: HudGlyph(
                    slot: slot,
                    color: color,
                    size: 28,
                    stage: stage,
                  ),
                ),
                AppSpacing.gapSm,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleLarge),
                      DefaultTextStyle.merge(
                        style: theme.textTheme.titleMedium,
                        child: headline,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              AppSpacing.gapXxs,
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(color: palette.ink2),
              ),
            ],
            AppSpacing.gapSm,
            _Explanation(lines: explanation),
            AppSpacing.gapXs,
            // A lista rola; a explicação e o cabeçalho, não. O que muda de
            // tamanho entre uma folha e outra é o número de linhas, e é só
            // ele que pode empurrar conteúdo para fora da vista.
            Flexible(child: ListView(shrinkWrap: true, children: children)),
          ],
        ),
      ),
    );
  }
}

/// A mini explicação: jogo, financeiro e XP, nessa ordem e sempre as três.
///
/// As três linhas existem juntas porque cada uma responde a uma pessoa
/// diferente lendo a MESMA tela: quem está jogando, quem quer o número e quem
/// quer saber se isso rende. Tirar a de XP quando o ícone não dá XP seria
/// justamente esconder a resposta — "nenhum" é uma resposta.
class _Explanation extends StatelessWidget {
  const _Explanation({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return Container(
      key: const ValueKey('hud-explanation'),
      width: double.infinity,
      padding: AppSpacing.allSm,
      decoration: BoxDecoration(
        color: palette.paper2,
        borderRadius: AppRadius.brMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (index, line) in lines.indexed) ...[
            if (index > 0) AppSpacing.gapXxs,
            Text(
              line,
              style: theme.textTheme.bodySmall?.copyWith(
                color: index == 0 ? palette.ink : palette.ink2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A frase do denominador, ou o aviso de que ele não existe.
class _IncomeNote extends StatelessWidget {
  const _IncomeNote({required this.hud});

  final HudState hud;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final l10n = context.l10n;
    final income = hud.income;

    if (income == null) {
      return Container(
        key: const ValueKey('hud-no-income'),
        width: double.infinity,
        padding: AppSpacing.allSm,
        decoration: BoxDecoration(
          color: palette.warningText.withValues(alpha: 0.10),
          borderRadius: AppRadius.brMd,
        ),
        child: Text(
          l10n.hudNoIncome,
          style: theme.textTheme.bodySmall?.copyWith(color: palette.ink),
        ),
      );
    }

    final amount = income.amount.format(locale: context.locale);

    return Text(
      income.source == ExpectedIncomeSource.average
          ? l10n.hudIncomeSourceAverage(amount)
          : l10n.hudIncomeSourcePlanned(amount),
      style: theme.textTheme.bodySmall?.copyWith(color: palette.ink2),
    );
  }
}

/// Uma linha de detalhe: ícone colorido, nome, apoio e valor.
class _Line extends StatelessWidget {
  const _Line({
    super.key,
    required this.name,
    required this.value,
    this.support,
    this.supportColor,
    this.color,
    this.icon,
    this.onTap,
    this.footer,
  });

  final String name;
  final Money value;
  final String? support;

  /// O que vem ABAIXO da linha inteira, ocupando a largura toda: hoje, a
  /// barra de uso do limite do cartão. Fica fora da coluna do nome de
  /// propósito — uma barra espremida entre o nome e o valor mediria uns
  /// noventa pixels e não daria para ler onde ela termina.
  final Widget? footer;

  /// A tinta do apoio, quando ele é um AVISO e não uma legenda.
  final Color? supportColor;

  final String? color;
  final String? icon;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    final dot = color?.asColor(orElse: palette.ink3) ?? palette.ink3;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: AppSpacing.vXs,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: dot.withValues(alpha: 0.16),
                    borderRadius: AppRadius.brSm,
                  ),
                  child: Icon(
                    icon?.asIcon() ?? Icons.circle,
                    size: 16,
                    color: dot,
                  ),
                ),
                AppSpacing.gapXs,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (support != null)
                        Text(
                          support!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: supportColor ?? palette.ink2,
                            fontWeight: supportColor == null
                                ? null
                                : FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                AppSpacing.gapXs,
                MoneyText(value.toDouble(), style: theme.textTheme.titleSmall),
              ],
            ),
            if (footer != null) ...[AppSpacing.gapXxs, footer!],
          ],
        ),
      ),
    );
  }
}

/// Um título de seção dentro da folha.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text, this.hint});

  final String text;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: AppSpacing.xxs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: theme.textTheme.titleSmall),
          if (hint != null)
            Text(
              hint!,
              style: theme.textTheme.labelSmall?.copyWith(color: palette.ink2),
            ),
        ],
      ),
    );
  }
}

/// Texto simples para um estado vazio.
class _Empty extends StatelessWidget {
  const _Empty(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: AppSpacing.vMd,
      child: Text(message, style: theme.textTheme.bodyMedium),
    );
  }
}

// ── Poção ───────────────────────────────────────────────────────────────────

class _PotionSheet extends StatelessWidget {
  const _PotionSheet({required this.hud});

  final HudState hud;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.locale;
    final potion = hud.potion;

    return _HudSheet(
      slot: HudSlot.potion,
      title: l10n.hudPotionTitle,
      color: potion.isFilled ? AppColors.success : context.palette.ink3,
      progress: potion.ratio.fill,
      headline: Text(potion.total.format(locale: locale)),
      // A poção é a ÚNICA que mostra a classe: "gole/semi/regular/super/hiper"
      // foi o vocabulário que o dono pediu para o que se guarda.
      subtitle: potion.ratio.isUnknown
          ? null
          : '${hudTierLabel(l10n, potion.ratio)} · '
                '${hudRatioOfIncome(l10n, potion.ratio, locale)}',
      explanation: [
        l10n.hudPotionGame,
        l10n.hudPotionFinance,
        l10n.hudPotionXp,
      ],
      children: [
        _IncomeNote(hud: hud),
        if (potion.accounts.isEmpty)
          _Empty(l10n.hudPotionEmpty)
        else
          for (final account in potion.accounts)
            _Line(
              key: ValueKey('hud-potion-${account.id}'),
              name: account.name,
              value: account.amount,
              color: account.color,
              icon: 'savings',
              onTap: () => context.push('/accounts/${account.id}/statement'),
            ),
      ],
    );
  }
}

// ── Vila ────────────────────────────────────────────────────────────────────

class _VillageSheet extends StatelessWidget {
  const _VillageSheet({required this.hud, required this.isBusiness});

  final HudState hud;
  final bool isBusiness;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.locale;
    final palette = context.palette;
    final village = hud.village;

    final color = village.isEmpty ? palette.ink3 : hudVillageColor(village);

    return _HudSheet(
      slot: HudSlot.village,
      // "Vila" nos dois workspaces: o título é o nome do JOGO. Quem fala em
      // centro de custo é a linha financeira da mini explicação, logo abaixo.
      title: l10n.hudVillageTitle,
      color: color,
      progress: village.ring,
      headline: Text(
        l10n.hudVillageAliveCount(village.aliveCount, village.plannedCount),
      ),
      subtitle: village.isEmpty
          ? null
          : l10n.hudVillageSpent(
              village.actualTotal.format(locale: locale),
              village.plannedTotal.format(locale: locale),
            ),
      explanation: [
        isBusiness ? l10n.hudVillageGameBusiness : l10n.hudVillageGame,
        isBusiness ? l10n.hudVillageFinanceBusiness : l10n.hudVillageFinance,
        l10n.hudVillageXp,
      ],
      children: [
        if (village.isEmpty)
          _Empty(
            isBusiness ? l10n.hudVillageEmptyBusiness : l10n.hudVillageEmpty,
          )
        else ...[
          Text(
            village.plannedCount < hudVillageMinimum
                ? l10n.hudVillageNeedsThree
                : village.isAlive
                ? l10n.hudVillageAlive
                : l10n.hudVillageFallen,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: village.isAlive ? palette.successText : palette.dangerText,
            ),
          ),
          AppSpacing.gapXxs,
          Text(
            l10n.hudProjectedXp(village.projectedXp),
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: palette.rewardText),
          ),
          for (final villager in village.villagers)
            _Villager(
              key: ValueKey('hud-villager-${villager.categoryId}'),
              villager: villager,
            ),
        ],
        if (village.unprotected.isNotEmpty) ...[
          _SectionTitle(
            text: l10n.hudUnprotectedTitle,
            hint: l10n.hudUnprotectedHint,
          ),
          for (final item in village.unprotected)
            _Line(
              key: ValueKey('hud-unprotected-${item.id}'),
              name: item.name,
              value: item.amount,
              color: item.color,
              icon: item.icon,
              onTap: () => context.push('/category-details?type=expense'),
            ),
        ],
        _SectionTitle(text: l10n.hudHistoryTitle),
        if (village.history.isEmpty)
          _Empty(l10n.hudHistoryEmpty)
        else
          for (final report in village.history)
            _HistoryLine(
              key: ValueKey('hud-history-${report.monthKey}'),
              report: report,
            ),
      ],
    );
  }
}

/// Um aldeão: nome, barra de HP e o que sobra do orçamento.
class _Villager extends StatelessWidget {
  const _Villager({super.key, required this.villager});

  final HudVillager villager;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final l10n = context.l10n;
    final locale = context.locale;

    final color = villager.color.asColor(orElse: palette.ink3);
    final alive = villager.isAlive;

    return InkWell(
      onTap: () => context.push('/planning'),
      child: Padding(
        padding: AppSpacing.vXs,
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: AppRadius.brSm,
              ),
              child: Icon(villager.icon.asIcon(), size: 16, color: color),
            ),
            AppSpacing.gapXs,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          villager.name,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        alive
                            ? l10n.hudVillagerHp(
                                villager.hp.format(locale: locale),
                                villager.planned.format(locale: locale),
                              )
                            : l10n.hudVillagerOver(
                                (-villager.hp).format(locale: locale),
                              ),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: alive
                              ? palette.successText
                              : palette.dangerText,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapXxs,
                  // A barra de HP: o que SOBRA do orçamento. Um aldeão morto
                  // fica com a calha inteira à mostra, e é assim que a lista
                  // mostra a queda sem precisar de um rótulo "morto".
                  ClipRRect(
                    borderRadius: AppRadius.brPill,
                    child: LinearProgressIndicator(
                      // O MORTO tem a barra CHEIA em vermelho, e não vazia.
                      // Vazia, ele lia igual a um aldeão que ainda não tinha
                      // carregado: a calha inteira à mostra é a ausência de
                      // barra, não a presença de uma notícia ruim. Cheia de
                      // vermelho, a linha grita o que aconteceu ali.
                      value: alive ? villager.hpRatio : 1,
                      minHeight: 6,
                      backgroundColor: palette.line,
                      color: alive ? AppColors.success : AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryLine extends StatelessWidget {
  const _HistoryLine({super.key, required this.report});

  final HudMonthlyReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final l10n = context.l10n;

    return Padding(
      padding: AppSpacing.vXs,
      child: Row(
        children: [
          Icon(
            report.villageAlive ? Icons.shield : Icons.shield_outlined,
            size: 16,
            color: report.villageAlive
                ? palette.successText
                : palette.dangerText,
          ),
          AppSpacing.gapXs,
          Expanded(
            child: Text(
              _monthLabel(context, report.monthKey),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            l10n.hudHistoryLine(
              report.villagersAlive,
              report.villagersPlanned,
              report.xpAwarded,
            ),
            style: theme.textTheme.labelSmall?.copyWith(color: palette.ink2),
          ),
        ],
      ),
    );
  }
}

/// "2026-08" → "ago/2026" em português, "Aug 2026" em inglês.
///
/// A chave `YYYY-MM` é do BANCO. Ela é como o servidor nomeia o documento, e
/// mostrá-la crua na lista de meses fechados era o app pedindo ao usuário que
/// lesse o id de um registro.
///
/// O ponto das abreviações do português ("ago.") sai: a linha é uma etiqueta
/// curta ao lado de um escudo, e "ago./2026" tem pontuação demais para o que
/// ela é.
String _monthLabel(BuildContext context, String monthKey) {
  final (year, month) = DateTimeExtension.parseMonthKey(monthKey);

  return DateTime(year, month)
      .formated(context.l10n.hudHistoryMonthPattern, context.locale)
      .replaceAll('.', '');
}

// ── Incubados ───────────────────────────────────────────────────────────────

class _EggSheet extends StatelessWidget {
  const _EggSheet({required this.hud});

  final HudState hud;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.locale;
    final palette = context.palette;
    final egg = hud.egg;

    final color = egg.ratio.isUnknown ? palette.ink3 : hudEggRingColor(egg);

    return _HudSheet(
      slot: HudSlot.egg,
      // A FAIXA diz "Incubados", que é o que cabe embaixo de uma figura de
      // 30 px; a folha diz "Monstros incubados", que é a frase inteira. O
      // rótulo curto existe por largura, e não por conteúdo: quem abriu a
      // folha tem espaço para ouvir o nome completo do que está chocando ali.
      title: l10n.hudEggSheetTitle,
      color: color,
      stage: egg.stage,
      progress: egg.ratio.fill,
      headline: Text(egg.total.format(locale: locale)),
      // Sem classe: os incubados mostram a razão, e quem diz se ela é boa ou
      // ruim é a cor do anel e a mini explicação. "Gole" sobre R$ 20.187,80
      // em faturas elogiava o usuário pelo tamanho da dívida.
      subtitle: hudRatioOfIncome(l10n, egg.ratio, locale),
      explanation: [l10n.hudEggGame, l10n.hudEggFinance, l10n.hudEggXp],
      children: [
        _IncomeNote(hud: hud),
        if (egg.invoices.isEmpty)
          _Empty(l10n.hudEggEmpty)
        else
          for (final invoice in egg.invoices)
            _Line(
              key: ValueKey('hud-invoice-${invoice.accountId}'),
              name: invoice.name,
              value: invoice.amount,
              color: invoice.color,
              icon: 'credit_card',
              // A vencida diz que venceu, e diz em tinta de perigo. Ela
              // CONTINUA na soma do ovo (o contrato é Σ nextInvoice, e uma
              // fatura vencida é a mais devida de todas); o que faltava era
              // a linha não se parecer com a de quem vence daqui a um mês.
              support: invoice.isOverdue
                  ? l10n.hudInvoiceOverdue(invoice.overdueDays)
                  : invoice.isOpenCycle
                  ? l10n.hudInvoiceOpen(
                      invoice.closingDate.formated('dd/MM', locale),
                      invoice.dueDate.formated('dd/MM', locale),
                    )
                  : l10n.hudInvoiceClosed(
                      invoice.closingDate.formated('dd/MM', locale),
                      invoice.dueDate.formated('dd/MM', locale),
                    ),
              supportColor: invoice.isOverdue ? palette.dangerText : null,
              // A progressão de uso do limite, cartão a cartão — o dono
              // pediu "uma visão semelhante à da Visão Geral", e é a mesma
              // barra ([AppProgressBar] fina, na cor do cartão), não uma
              // cópia parecida.
              footer: _CardLimit(invoice: invoice),
              onTap: () => context.push(
                invoice.installmentId != null
                    ? '/invoices/${invoice.installmentId}'
                    : '/accounts/${invoice.accountId}/statement',
              ),
            ),
      ],
    );
  }
}

/// A barra de uso do limite de UM cartão.
///
/// É o mesmo componente e o mesmo desenho da Visão Geral — [AppProgressBar]
/// fina, na cor da conta, com o usado à esquerda e o livre à direita. Não é
/// uma barra parecida: o dono pediu "uma visão semelhante à usada na Visão
/// Geral", e duas barras que medem o MESMO dado com dois componentes
/// divergem — foi assim que este app chegou a ter catorze barras de
/// progresso diferentes.
///
/// O que a folha acrescenta é o que a Visão Geral não tinha espaço para
/// dizer: a PORCENTAGEM por extenso. Ela é a resposta à pergunta que faz o
/// usuário abrir esta folha — "quanto do cartão eu já comprometi?" — e ler
/// isso de uma barra a olho é adivinhar.
///
/// Cartão sem limite cadastrado não ganha barra nenhuma, e essa é a decisão
/// que importa: uma barra a 0% diria "o cartão está inteiro livre" onde o
/// app não sabe de nada. A frase honesta cabe no mesmo lugar.
class _CardLimit extends StatelessWidget {
  const _CardLimit({required this.invoice});

  final HudInvoice invoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final l10n = context.l10n;
    final locale = context.locale;

    final usage = invoice.limitUsage;
    final available = invoice.availableLimit;

    if (usage == null || available == null) {
      return Padding(
        padding: const EdgeInsets.only(left: 36),
        child: Text(
          l10n.hudCardLimitUnknown,
          key: ValueKey('hud-limit-unknown-${invoice.accountId}'),
          style: theme.textTheme.labelSmall?.copyWith(color: palette.ink3),
        ),
      );
    }

    final color = invoice.color?.asColor(orElse: palette.ink3) ?? palette.ink3;

    return Padding(
      // Alinhado com o NOME do cartão, e não com o ícone: a barra fala
      // daquela conta, e começar embaixo do quadradinho colorido a faria
      // parecer uma segunda linha da lista.
      padding: const EdgeInsets.only(left: 36),
      child: Column(
        key: ValueKey('hud-limit-${invoice.accountId}'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppProgressBar(
            value: usage,
            size: AppProgressSize.thin,
            color: color,
            semanticLabel: l10n.hudCardLimitLabel,
          ),
          AppSpacing.gapXxs,
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.hudCardLimitUsage((usage * 100).round()),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: palette.ink2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AppSpacing.gapXs,
              Flexible(
                child: Text(
                  l10n.hudCardLimitFigures(
                    invoice.used.format(locale: locale),
                    available.format(locale: locale),
                  ),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: palette.ink3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Veneno ──────────────────────────────────────────────────────────────────

class _DropSheet extends StatelessWidget {
  const _DropSheet({required this.hud});

  final HudState hud;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.locale;
    final drop = hud.drop;

    return _HudSheet(
      slot: HudSlot.drop,
      title: l10n.hudDropTitle,
      color: drop.isBlinking ? AppColors.violet : context.palette.ink3,
      progress: drop.ratio.fill,
      headline: Text(drop.total.format(locale: locale)),
      // Sem classe, pela mesma razão dos incubados: o que se DEVE não se
      // mede na escala do que se guarda.
      subtitle: hudRatioOfIncome(l10n, drop.ratio, locale),
      explanation: [l10n.hudDropGame, l10n.hudDropFinance, l10n.hudDropXp],
      children: [
        _IncomeNote(hud: hud),
        if (drop.debts.isEmpty)
          _Empty(l10n.hudDropEmpty)
        else
          for (final debt in drop.debts)
            _Line(
              key: ValueKey('hud-debt-${debt.accountId}'),
              name: debt.name,
              value: debt.balance,
              color: debt.color,
              icon: 'account_balance',
              support: debt.installment == null
                  ? l10n.hudDebtNoInstallment
                  : l10n.hudDebtInstallment(
                      debt.installment!.format(locale: locale),
                      debt.nextDueDate!.formated('dd/MM', locale),
                    ),
              onTap: () =>
                  context.push('/accounts/${debt.accountId}/statement'),
            ),
      ],
    );
  }
}
