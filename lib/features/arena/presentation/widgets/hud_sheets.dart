import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/money/money.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/core/widgets/app_chip.dart';
import 'package:funances/core/widgets/app_progress_bar.dart';
import 'package:funances/core/widgets/app_ring.dart';
import 'package:funances/core/widgets/money_text.dart';
import 'package:funances/features/arena/domain/models/hud_state.dart';
import 'package:funances/features/arena/presentation/providers/hud_intro_store.dart';
import 'package:funances/features/arena/presentation/widgets/hud_account_logo.dart';
import 'package:funances/features/arena/presentation/widgets/hud_explanation.dart';
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
/// A ordem de cada folha é sempre a mesma: **o número grande**, o chip e as
/// linhas curtas que o qualificam, e logo em seguida os DADOS — os envelopes,
/// a grade de aldeões, as faturas, as dívidas.
///
/// A mini explicação em três partes — jogo, financeiro e XP — não está mais
/// no meio do caminho. Ela vinha entre o número e a lista, e o dono mediu o
/// resultado: *"a descrição ocupa muito espaço e o que importa fica espremido
/// num scroll na parte de baixo da tela"*. Agora ela mora atrás do ícone de
/// informação do cabeçalho ([HudExplanationButton]) e se apresenta sozinha na
/// primeira abertura de cada folha — ver [HudIntroStore].
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
class _HudSheet extends ConsumerStatefulWidget {
  const _HudSheet({
    required this.slot,
    required this.title,
    required this.howItWorks,
    required this.headline,
    required this.color,
    required this.explanation,
    required this.children,
    this.subtitles = const [],
    this.chip,
    this.stage = 0,
    this.progress = 0,
  });

  final HudSlot slot;
  final String title;

  /// "Como funciona a Poção". É o tooltip e o rótulo de leitor de tela do
  /// ícone de informação — a frase INTEIRA, porque um "i" sozinho não diz
  /// de que ele é a explicação.
  final String howItWorks;

  /// O número grande: o total, a razão, a contagem de aldeões.
  final Widget headline;

  /// As linhas logo abaixo do número grande. São uma lista porque a vila
  /// tem DOIS envelopes para mostrar — despesa e investimento —, e é a
  /// comparação entre as duas linhas que explica uma vila caída com as
  /// despesas em dia.
  final List<String> subtitles;

  /// A pílula logo abaixo do número grande. Hoje só a poção tem uma: os
  /// "meses de pé". Fica fora das [subtitles] porque não é uma frase — é um
  /// número com unidade, e ele se lê de relance.
  final String? chip;

  final Color color;
  final int stage;
  final double progress;

  /// As três frases: jogo, financeiro e XP.
  final List<String> explanation;

  final List<Widget> children;

  @override
  ConsumerState<_HudSheet> createState() => _HudSheetState();
}

class _HudSheetState extends ConsumerState<_HudSheet> {
  /// Onde o balão do desktop se ancora.
  final GlobalKey _infoKey = GlobalKey();

  /// A apresentação automática acontece UMA vez por montagem da folha, e o
  /// campo é o que garante isso: `addPostFrameCallback` roda por quadro, e
  /// sem ele um rebuild abriria um segundo painel por cima do primeiro.
  bool _introduced = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeIntroduce());
  }

  /// A primeira abertura desta folha mostra a explicação sozinha.
  ///
  /// A pergunta ao disco vem ANTES de qualquer espera de animação: quem já
  /// leu não pode pagar nem um quadro de atraso por causa de quem nunca leu.
  Future<void> _maybeIntroduce() async {
    if (_introduced) return;
    _introduced = true;

    final store = ref.read(HudIntroProviders.store);
    if (await store.wasSeen(widget.slot)) return;
    if (!mounted) return;

    // Esperar a folha TERMINAR de subir é o que tira o piscar: um painel que
    // aparece enquanto a folha ainda desliza mostra as duas em movimento e
    // faz o usuário achar que apertou duas vezes.
    await _entered();
    if (!mounted) return;

    await _openExplanation();
    await store.markSeen(widget.slot);
  }

  /// Completa quando a folha parou de entrar.
  Future<void> _entered() {
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || animation.isCompleted) return Future<void>.value();

    final completer = Completer<void>();

    void listener(AnimationStatus status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        animation.removeStatusListener(listener);
        if (!completer.isCompleted) completer.complete();
      }
    }

    animation.addStatusListener(listener);
    return completer.future;
  }

  Future<void> _openExplanation() {
    return showHudExplanation(
      context,
      lines: widget.explanation,
      anchor: _anchor(),
    );
  }

  /// O retângulo do ícone na tela, para o balão do desktop nascer colado
  /// nele. Sem render box — folha ainda não medida — o painel cai no formato
  /// de folha modal, que não depende de âncora.
  Rect? _anchor() {
    final box = _infoKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;

    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return SafeArea(
      // A chave nomeia a folha para o golden: as quatro são a mesma classe,
      // e sem ela um PNG não sabe dizer qual delas fotografou.
      key: ValueKey('hud-sheet-${widget.slot.name}'),
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
                  progress: widget.progress,
                  color: widget.color,
                  size: 44,
                  stroke: 3.5,
                  child: HudGlyph(
                    slot: widget.slot,
                    color: widget.color,
                    size: 28,
                    stage: widget.stage,
                  ),
                ),
                AppSpacing.gapSm,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: theme.textTheme.titleLarge),
                      DefaultTextStyle.merge(
                        style: theme.textTheme.titleMedium,
                        child: widget.headline,
                      ),
                    ],
                  ),
                ),
                // A porta da explicação, no canto do cabeçalho: longe do
                // número grande, que é o que a folha existe para mostrar, e
                // no mesmo lugar nas quatro folhas.
                HudExplanationButton(
                  key: _infoKey,
                  label: widget.howItWorks,
                  onPressed: _openExplanation,
                ),
              ],
            ),
            if (widget.chip != null) ...[
              AppSpacing.gapXs,
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: StatusPill(
                  key: const ValueKey('hud-potion-months'),
                  label: widget.chip!,
                  tone: StatusTone.info,
                  icon: Icons.hourglass_bottom_outlined,
                  dense: true,
                ),
              ),
            ],
            for (final linha in widget.subtitles) ...[
              AppSpacing.gapXxs,
              Text(
                linha,
                style: theme.textTheme.bodySmall?.copyWith(color: palette.ink2),
              ),
            ],
            AppSpacing.gapSm,
            // Os DADOS começam aqui, e é a mudança inteira deste pacote: o
            // que era o topo da lista ficava abaixo de três parágrafos e só
            // aparecia rolando. A lista rola; o cabeçalho, não.
            Flexible(
              child: ListView(shrinkWrap: true, children: widget.children),
            ),
          ],
        ),
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
    this.accountId,
    this.support,
    this.supportColor,
    this.color,
    this.icon,
    this.onTap,
    this.footer,
  });

  /// A conta de onde a linha saiu, quando ela é de uma CONTA.
  ///
  /// Com ele a linha ganha a logo do banco e os donos, como na Visão Geral;
  /// sem ele — a categoria sem proteção da vila — fica o ícone da leitura.
  /// Uma categoria não tem banco nem proprietário.
  final String? accountId;

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
                if (accountId case final id?)
                  HudAccountLogo(accountId: id, color: color, icon: icon)
                else
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
      howItWorks: l10n.hudPotionHowItWorks,
      color: potion.isFilled ? AppColors.success : context.palette.ink3,
      progress: potion.ratio.fill,
      headline: Text(potion.total.format(locale: locale)),
      // A poção é a ÚNICA que mostra a classe: "semi/regular/super/hiper" foi
      // o vocabulário que o dono pediu para o que se guarda. Abaixo de meio
      // mês de receita não há classe nenhuma — fica só a razão, e o chip de
      // meses de pé diz o resto.
      // A razão SAI quando ela é "< 0,1": o chip logo acima já diz
      // "< 0,1 mês de pé", e as duas linhas empilhadas repetiam o mesmo
      // número com duas unidades — "< 0,1 mês de pé" sobre "< 0,1× da
      // receita prevista do mês" lê como gagueira, e a segunda não acrescenta
      // nada que o chip e a nota de receita (logo abaixo, com o valor
      // inteiro) já não digam. Acima do primeiro décimo as duas convivem: aí
      // a linha carrega também a CLASSE, que o chip não diz.
      subtitles: potion.ratio.isUnknown || _razaoMinuscula(potion.ratio, locale)
          ? const []
          : [
              [
                hudTierLabel(l10n, potion.ratio),
                hudRatioOfIncome(l10n, potion.ratio, locale),
              ].nonNulls.join(' · '),
            ],
      // O chip de MESES DE PÉ, logo abaixo do valor: a razão dita na unidade
      // que o dono quis ver no lugar da palavra que saiu — "quantos meses eu
      // aguento". É a mesma conta do anel; o que muda é que "1,5 meses de
      // pé" se entende sem saber o que um "×" significa.
      chip: hudPotionMonths(l10n, potion.ratio, locale),
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
              accountId: account.id,
              color: account.color,
              icon: 'savings',
              onTap: () => context.push('/accounts/${account.id}/statement'),
            ),
      ],
    );
  }
}

/// A razão é pequena demais para ter dois dígitos: ela sai como "< 0,1".
///
/// Quem decide é o mesmo texto que vai para a tela, e não um limiar escrito
/// à mão — duas regras para o mesmo corte divergem.
bool _razaoMinuscula(HudRatio ratio, String locale) =>
    hudRatioValue(ratio, locale)?.startsWith('<') ?? false;

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
      // centro de custo é a linha financeira da mini explicação, atrás do
      // ícone de informação.
      title: l10n.hudVillageTitle,
      howItWorks: l10n.hudVillageHowItWorks,
      color: color,
      progress: village.ring,
      headline: Text(
        l10n.hudVillageAliveCount(village.aliveCount, village.plannedCount),
      ),
      // Os DOIS envelopes, uma linha cada. É o que explica uma vila caída
      // com as despesas em dia: sem a segunda linha, o usuário lê "R\$
      // 14.912,20 de R\$ 22.020,00 gastos" ao lado de "a vila caiu" e conclui
      // que o app errou a conta. A linha de investimento só aparece quando
      // existe envelope de investimento — vila sem meta de aporte não tem o
      // que mostrar, e uma linha "R\$ 0,00 de R\$ 0,00" é ruído.
      subtitles: village.isEmpty
          ? const []
          : [
              l10n.hudVillageEnvelopeExpense(
                village.expenseActualTotal.format(locale: locale),
                village.expensePlannedTotal.format(locale: locale),
              ),
              if (village.hasInvestmentEnvelope)
                l10n.hudVillageEnvelopeInvestment(
                  village.investmentActualTotal.format(locale: locale),
                  village.investmentPlannedTotal.format(locale: locale),
                ),
            ],
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
                // EM RISCO é o meio do mês: as despesas couberam e só falta
                // aportar. No fechamento não há meio-termo, e o retrato do
                // servidor grava vivo ou caído.
                : village.isAtRisk
                ? l10n.hudVillageAtRisk
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
          // A vila é uma GRADE, e não uma lista. O dono pediu "uma visão
          // semelhante à da Party": dezoito linhas empilhadas obrigam a
          // rolar para saber quantos caíram, e a resposta a essa pergunta
          // é o que a folha existe para dar. Numa grade de anéis ela se lê
          // de relance — e os dois grupos a dizem sem contar nada.
          _VillagerGroup(
            key: const ValueKey('hud-village-fallen'),
            title: l10n.hudVillageFallenGroup(village.fallenCount),
            // Os CAÍDOS primeiro, do estouro mais fundo para o mais raso.
            // É o que o dono pediu — "separe o grupo dos mortos do grupo dos
            // vivos" —, e é também a ordem da Party (crítico, atenção,
            // estável), que foi a visão que ele mandou imitar. Com treze
            // vivos, quatro tiles por linha empurrariam os caídos para baixo
            // da dobra de um celular de 400 px, e é o caído que o usuário
            // precisa ver para fazer alguma coisa a respeito.
            villagers: village.villagers.where((v) => v.isFallen),
          ),
          _VillagerGroup(
            key: const ValueKey('hud-village-at-risk'),
            title: l10n.hudVillageAtRiskGroup(village.atRiskCount),
            // EM RISCO é o terceiro estado, e ele nasceu com a categoria de
            // investimento: o aldeão que ainda não aportou a meta não está
            // morto — o mês não acabou. Fica entre os dois grupos porque é
            // exatamente aí que ele está: pior que de pé, e ainda salvável.
            //
            // Ele é um GRUPO, e não uma marca dentro dos vivos, porque os
            // títulos carregam contagem: "Vivos (13)" com um âmbar no meio
            // diria treze de pé onde há doze e um devendo.
            villagers: village.villagers.where((v) => v.isAtRisk),
          ),
          _VillagerGroup(
            key: const ValueKey('hud-village-alive'),
            title: l10n.hudVillageAliveGroup(village.aliveCount),
            // Os vivos vêm do calculador já ordenados por FRAÇÃO de HP
            // crescente: quem está mais perto de cair aparece primeiro, e
            // folga em reais não é risco.
            villagers: village.villagers.where((v) => v.isAlive),
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

/// Um GRUPO de aldeões: o título com a contagem e a grade de anéis.
///
/// Grupo vazio não desenha nada — nem o título. "Caídos (0)" numa vila
/// inteira de pé é um título procurando conteúdo, e ele empurraria o
/// histórico para baixo sem dizer nada que o número grande já não diga.
class _VillagerGroup extends StatelessWidget {
  const _VillagerGroup({
    super.key,
    required this.title,
    required this.villagers,
  });

  final String title;
  final Iterable<HudVillager> villagers;

  @override
  Widget build(BuildContext context) {
    final items = villagers.toList(growable: false);
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(text: title),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.sm,
          children: [
            for (final villager in items)
              _Villager(
                key: ValueKey('hud-villager-${villager.categoryId}'),
                villager: villager,
              ),
          ],
        ),
      ],
    );
  }
}

/// Um ALDEÃO na grade: o anel de HP, o ícone da categoria, o nome e o que
/// sobra — ou o que estourou.
///
/// O ANEL é o mesmo componente da Party ([AppRing]) e mede a mesma coisa que
/// a barra que ele substituiu: a fração de HP que resta. O caído fica com o
/// anel CHEIO em vermelho, e não vazio: vazio ele lia como um aldeão que
/// ainda não tinha carregado — a calha inteira à mostra é a ausência de
/// barra, não a presença de uma notícia ruim.
///
/// A cor do MIOLO é a da categoria, e não a do estado. Se as duas fossem a
/// mesma, a grade inteira ficaria verde ou vermelha e o usuário perderia a
/// única pista de qual aldeão é qual antes de ler o nome.
class _Villager extends StatelessWidget {
  const _Villager({super.key, required this.villager});

  final HudVillager villager;

  /// A largura de um aldeão na grade.
  ///
  /// Oitenta e quatro pixels dão quatro por linha num celular de 400 px
  /// depois da margem da folha (4 x 84 + 3 x 4 = 348 dentro de 368), e é a
  /// largura em que "Supermercado" — a categoria de nome mais longo numa
  /// palavra só do cofre real — cabe inteira numa linha. Abaixo disso o nome
  /// vira reticências em quase toda categoria, e um aldeão sem nome é um
  /// ponto colorido.
  static const double largura = 84;

  /// Quantas linhas o nome pode ocupar: duas quando ele tem espaço para
  /// quebrar, uma quando é palavra única. Ver o comentário no [Text].
  static int _linhasDoNome(String nome) =>
      nome.trim().contains(RegExp(r'\s')) ? 2 : 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final l10n = context.l10n;
    final locale = context.locale;

    final color = villager.color.asColor(orElse: palette.ink3);

    // A tinta do ANEL diz o estado, e são três: verde de pé, âmbar em risco
    // (investimento abaixo da meta, mês correndo) e vermelho caído. O âmbar
    // é o mesmo do "perto do limite" do resto do app — é a cor de "ainda dá
    // tempo", e é isso que um aldeão de investimento em risco é.
    final anel = switch (villager.state) {
      HudVillagerState.standing => AppColors.success,
      HudVillagerState.atRisk => AppColors.warning,
      HudVillagerState.fallen => AppColors.danger,
    };

    // O que o leitor de tela ouve. O aldeão de investimento diz a META e o
    // que falta para ela: "R$ 150,00 de R$ 200,00 investidos — faltam
    // R$ 50,00 para o aldeão ficar de pé". Sem isso ele ouviria um número
    // solto e a regra invertida ficaria invisível justamente para quem não
    // vê a cor do anel.
    final estado = switch (villager.state) {
      HudVillagerState.atRisk => l10n.hudVillagerMissing(
        villager.actual.format(locale: locale),
        villager.planned.format(locale: locale),
        villager.missing.format(locale: locale),
      ),
      HudVillagerState.standing when villager.isInvestment =>
        l10n.hudVillagerGoal(
          villager.actual.format(locale: locale),
          villager.planned.format(locale: locale),
        ),
      HudVillagerState.standing => l10n.hudVillagerHp(
        villager.hp.format(locale: locale),
        villager.planned.format(locale: locale),
      ),
      HudVillagerState.fallen => l10n.hudVillagerOver(
        (-villager.hp).format(locale: locale),
      ),
    };

    // O número do tile: o que falta aportar, no aldeão em risco; o que sobra
    // do orçamento, na despesa de pé; o tamanho do estouro, no caído.
    final (Money valor, Color tinta) = switch (villager.state) {
      HudVillagerState.atRisk => (villager.missing, palette.warningText),
      HudVillagerState.fallen => (-villager.hp, palette.dangerText),
      HudVillagerState.standing => (villager.hp, palette.successText),
    };

    return Semantics(
      button: true,
      // A semântica diz o valor EXATO, e não o compacto: "R$ 1,5 mil" é uma
      // concessão à largura do tile, e quem ouve a tela não tem largura
      // nenhuma para economizar.
      label: l10n.hudVillagerSemantics(villager.name, estado),
      child: InkWell(
        borderRadius: AppRadius.brMd,
        onTap: () => context.push('/planning'),
        child: ExcludeSemantics(
          child: SizedBox(
            width: largura,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppRing.icon(
                  // O caído fica CHEIO de vermelho; os outros dois mostram a
                  // fração — que na despesa é o HP que resta e no
                  // investimento é o caminho já andado até a meta.
                  value: villager.isFallen ? 1 : villager.hpRatio,
                  color: anel,
                  // A CALHA do aldeão em risco é âmbar forte, e não a tinta
                  // a 20% de todo mundo: o aldeão que ainda não aportou nada
                  // tem arco de tamanho zero, e com a calha padrão o anel
                  // dele ficava quase branco — lia como um tile que ainda
                  // não carregou, que é o mesmo defeito do caído vazio.
                  trackColor: villager.isAtRisk
                      ? AppColors.warning.withValues(alpha: 0.35)
                      : null,
                  icon: villager.icon.asIcon(),
                  iconColor: color,
                  size: 44,
                ),
                AppSpacing.gapXxs,
                Text(
                  villager.name,
                  style: theme.textTheme.labelSmall,
                  textAlign: TextAlign.center,
                  // Nome de UMA palavra fica em uma linha; o de duas ou mais
                  // pode usar duas.
                  //
                  // O defeito que isso corrige: "Supermercado" não cabe em
                  // 84 px, e o Flutter só quebra DENTRO de uma palavra
                  // quando ela sozinha estoura a linha — o tile mostrava
                  // "Supermerca/do", que parecem duas palavras e nenhuma
                  // delas é uma. Com uma linha só, o corte vira reticências
                  // no fim ("Supermercad…"), que o olho lê como palavra
                  // cortada e não como palavra errada.
                  maxLines: _linhasDoNome(villager.name),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  hudCompactMoney(valor, locale),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: tinta,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
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
      howItWorks: l10n.hudEggHowItWorks,
      color: color,
      stage: egg.stage,
      progress: egg.ratio.fill,
      headline: Text(egg.total.format(locale: locale)),
      // Sem classe: os incubados mostram a razão, e quem diz se ela é boa ou
      // ruim é a cor do anel e a mini explicação. "Gole" sobre R$ 20.187,80
      // em faturas elogiava o usuário pelo tamanho da dívida.
      subtitles: [?hudRatioOfIncome(l10n, egg.ratio, locale)],
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
              accountId: invoice.accountId,
              color: invoice.color,
              icon: 'credit_card',
              // A vencida diz que venceu, e diz em tinta de perigo. Ela
              // CONTINUA na soma dos incubados (o contrato é Σ nextInvoice, e uma
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
/// isso de uma barra a olho é adivinhar. Em troca sai o valor USADO, que a
/// porcentagem e a barra já dizem duas vezes: os dois pares não cabiam em
/// 400 px e o segundo saía cortado no meio.
///
/// Cartão ESTOURADO não diz "100% · R$ 0,00 até o limite". Os dois números
/// estariam certos e a soma deles seria uma mentira: "está no talo" e
/// "furou o teto em R$ 812,00" são dois fatos diferentes, e só o segundo se
/// pode resolver. Ele diz a porcentagem REAL (109%), pinta a barra cheia em
/// tinta de perigo e troca a folga pelo tamanho do furo.
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
    final over = invoice.overLimit;
    final percent = invoice.limitPercent;

    if (usage == null || available == null || percent == null) {
      return Padding(
        padding: const EdgeInsets.only(left: 36),
        child: Text(
          l10n.hudCardLimitUnknown,
          key: ValueKey('hud-limit-unknown-${invoice.accountId}'),
          style: theme.textTheme.labelSmall?.copyWith(color: palette.ink3),
        ),
      );
    }

    // A tinta do cartão enquanto ele está dentro do limite; a de PERIGO
    // quando ele passou. A cor da conta é identidade — serve para dizer qual
    // barra é de qual cartão —, e identidade não pode ganhar de um aviso.
    final color = over != null
        ? AppColors.danger
        : invoice.color?.asColor(orElse: palette.ink3) ?? palette.ink3;

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
            // O NOME do cartão na semântica, e não só "Limite do cartão":
            // são seis barras seguidas na mesma folha, e quem ouve a tela
            // recebia seis vezes o mesmo rótulo com seis porcentagens
            // diferentes, sem saber de qual conta era cada uma.
            semanticLabel: l10n.hudCardLimitLabel(invoice.name),
          ),
          AppSpacing.gapXxs,
          Row(
            children: [
              Expanded(
                child: Text(
                  // A porcentagem REAL, sem o teto da barra: um cartão a
                  // 109% não é um cartão a 100%.
                  l10n.hudCardLimitUsage(percent),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: over != null ? palette.dangerText : palette.ink2,
                    fontWeight: over != null ? FontWeight.w600 : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AppSpacing.gapXs,
              Flexible(
                child: Text(
                  // O que FALTA para o teto, e não o que já foi: o "usado"
                  // já está dito duas vezes — pela barra e pela porcentagem
                  // —, e o par completo não cabia em 400 px sem cortar o
                  // número ao meio ("R$ 6…"), que mente mais do que não
                  // mostrar.
                  //
                  // "até o limite", e não "livres": o limite não é dinheiro
                  // do usuário, é o quanto o banco ainda deixa ele dever.
                  // "R$ 6.156,93 livres" soava como permissão de gastar
                  // justamente embaixo da frase que diz que todo gasto no
                  // cartão engorda um monstro.
                  over != null
                      ? l10n.hudCardLimitOver(over.format(locale: locale))
                      : l10n.hudCardLimitFree(available.format(locale: locale)),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: over != null ? palette.dangerText : palette.ink3,
                    fontWeight: over != null ? FontWeight.w600 : null,
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
      howItWorks: l10n.hudDropHowItWorks,
      color: drop.isBlinking ? AppColors.violet : context.palette.ink3,
      progress: drop.ratio.fill,
      headline: Text(drop.total.format(locale: locale)),
      // Sem classe, pela mesma razão dos incubados: o que se DEVE não se
      // mede na escala do que se guarda.
      subtitles: [?hudRatioOfIncome(l10n, drop.ratio, locale)],
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
              accountId: debt.accountId,
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
