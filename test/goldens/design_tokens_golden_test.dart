import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/theme/app_theme.dart';
import 'package:funances/core/widgets/app_card.dart';
import 'package:funances/core/widgets/app_chip.dart';
import 'package:funances/core/widgets/app_progress_bar.dart';
import 'package:funances/core/widgets/compass_strip.dart';
import 'package:funances/core/widgets/empty_state.dart';
import 'package:funances/core/widgets/error_view.dart';
import 'package:funances/core/widgets/level_badge.dart';
import 'package:funances/core/widgets/money_text.dart';
import 'package:funances/core/widgets/reward_toast.dart';
import 'package:funances/core/widgets/section_header.dart';
import 'package:funances/l10n/app_localizations.dart';

import 'golden_support.dart';

/// A folha de estilo do Funances, desenhada.
///
/// Serve a duas coisas que texto não faz: mostrar a identidade aprovada
/// ("Cofre Dourado com superfícies de papel") em pixels, nos DOIS temas, e
/// travar a fundação contra regressão. Se alguém trocar um raio, uma tinta ou
/// um degrau da escala tipográfica sem querer, é aqui que aparece primeiro —
/// e num diff pequeno, em vez de num golden de tela inteira onde a mudança se
/// esconde.
void main() {
  Future<void> pumpTokens(WidgetTester tester, ThemeData theme) async {
    await setGoldenSurface(tester, const Size(900, 1240));
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt'),
        home: const _TokenSheet(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('folha de tokens — tema claro', (tester) async {
    await pumpTokens(tester, AppTheme.light);
    await expectLater(
      find.byType(_TokenSheet),
      matchesGoldenFile('images/design_tokens_claro.png'),
    );
  });

  testWidgets('folha de tokens — tema escuro', (tester) async {
    await pumpTokens(tester, AppTheme.dark);
    await expectLater(
      find.byType(_TokenSheet),
      matchesGoldenFile('images/design_tokens_escuro.png'),
    );
  });
}

class _TokenSheet extends StatelessWidget {
  const _TokenSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return Scaffold(
      body: SingleChildScrollView(
        padding: AppSpacing.allLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Funances', style: theme.textTheme.displayMedium),
            Text(
              'Cofre Dourado com superfícies de papel',
              style: theme.textTheme.bodyLarge?.copyWith(color: palette.ink2),
            ),
            AppSpacing.gapLg,

            const _Section('Superfícies'),
            const Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                _Swatch('deep', AppColors.surfaceDeep, onDark: true),
                _Swatch('default', AppColors.surfaceDefault, onDark: true),
                _Swatch('raised', AppColors.surfaceRaised, onDark: true),
                _Swatch('paper', AppColors.paperLight),
                _Swatch('paper-2', AppColors.paper2Light),
              ],
            ),
            AppSpacing.gapMd,

            const _Section('Acentos e semânticas'),
            const Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                _Swatch('gold', AppColors.gold),
                _Swatch('teal', AppColors.teal),
                _Swatch('violet', AppColors.violet, onDark: true),
                _Swatch('success', AppColors.success),
                _Swatch('warning', AppColors.warning),
                _Swatch('danger', AppColors.danger, onDark: true),
              ],
            ),
            AppSpacing.gapMd,

            const _Section('Pools 50 / 30 / 20'),
            const Wrap(
              spacing: AppSpacing.xs,
              children: [
                _Swatch('pool 50', AppColors.pool50, onDark: true),
                _Swatch('pool 30', AppColors.pool30),
                _Swatch('pool 20', AppColors.pool20),
              ],
            ),
            AppSpacing.gapXs,
            AppPoolBar.standard(needs: 0.5, wants: 0.3, future: 0.2),
            AppSpacing.gapMd,

            const _Section('Escala tipográfica'),
            Text('40 · display', style: theme.textTheme.displayLarge),
            Text('32 · display', style: theme.textTheme.displayMedium),
            Text('24 · headline', style: theme.textTheme.headlineSmall),
            Text('20 · title', style: theme.textTheme.titleLarge),
            Text('16 · title semibold', style: theme.textTheme.titleMedium),
            Text('16 · body', style: theme.textTheme.bodyLarge),
            Text('14 · body', style: theme.textTheme.bodyMedium),
            Text('12 · body', style: theme.textTheme.bodySmall),
            Text('11 · LABEL', style: theme.textTheme.labelSmall),
            AppSpacing.gapXs,
            const Row(
              children: [
                MoneyText.hero(6415.99),
                SizedBox(width: AppSpacing.md),
                MoneyText.delta(233.33),
                SizedBox(width: AppSpacing.md),
                MoneyText.delta(-62.90),
              ],
            ),
            AppSpacing.gapMd,

            const _Section('Raios, do menor papel ao maior'),
            const Row(
              children: [
                _RadiusChip('xs 4', AppRadius.brXs),
                SizedBox(width: AppSpacing.xs),
                _RadiusChip('sm 8', AppRadius.brSm),
                SizedBox(width: AppSpacing.xs),
                _RadiusChip('md 12', AppRadius.brMd),
                SizedBox(width: AppSpacing.xs),
                _RadiusChip('lg 20', AppRadius.brLg),
                SizedBox(width: AppSpacing.xs),
                _RadiusChip('pílula', AppRadius.brPill),
              ],
            ),
            AppSpacing.gapMd,

            const _Section('Pílulas de status'),
            const Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                StatusPill(label: 'conta corrente'),
                StatusPill(label: 'no plano', tone: StatusTone.ok),
                StatusPill(label: 'fecha amanhã', tone: StatusTone.warning),
                StatusPill(label: 'acima', tone: StatusTone.danger),
                StatusPill(label: '+40 XP', tone: StatusTone.reward),
                StatusPill(label: 'compartilhada', tone: StatusTone.info),
              ],
            ),
            AppSpacing.gapMd,

            const _Section('Cartões: papel, elevado e jogo'),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Papel', style: theme.textTheme.titleMedium),
                        Text(
                          'lista, tabela, formulário',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppCard(
                    variant: AppCardVariant.raised,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Elevado', style: theme.textTheme.titleMedium),
                        Text(
                          'meta, conta',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppCard.game(
                    rewarded: true,
                    child: Builder(
                      builder: (context) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jogo',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            'XP, missão, conquista',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.gapMd,

            const _Section('Progresso, nível e Bússola'),
            const AppProgressBar(value: 0.62),
            AppSpacing.gapXs,
            const AppProgressBar.reward(value: 0.4),
            AppSpacing.gapXs,
            const Row(
              children: [
                LevelBadge(level: 7, progress: 0.4, label: 'Nv 7'),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: CompassStrip(
                    title: 'Bússola',
                    score: 48,
                    tierLabel: 'Estrategista',
                    delta: 3,
                    deltaLabel: '+3 desde o mês passado',
                    components: [],
                  ),
                ),
              ],
            ),
            AppSpacing.gapMd,

            const _Section('Botões'),
            Row(
              children: [
                FilledButton(onPressed: () {}, child: const Text('Lançar')),
                const SizedBox(width: AppSpacing.xs),
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('Conciliar'),
                ),
                const SizedBox(width: AppSpacing.xs),
                TextButton(onPressed: () {}, child: const Text('Ver tudo')),
                const SizedBox(width: AppSpacing.xs),
                const FilledButton(onPressed: null, child: Text('Desligado')),
              ],
            ),
            AppSpacing.gapXs,
            const TextField(
              decoration: InputDecoration(
                labelText: 'Valor',
                hintText: r'R$ 0,00',
              ),
            ),
            AppSpacing.gapMd,

            const _Section('Conquista, vazio e erro'),
            const Align(
              alignment: Alignment.centerLeft,
              child: RewardToast(
                icon: Icons.emoji_events,
                title: 'Conquista desbloqueada',
                subtitle: 'Visão de Longo Prazo',
                xpLabel: '+50 XP',
                major: true,
              ),
            ),
            AppSpacing.gapXs,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Expanded(
                  child: EmptyState.card(
                    icon: Icons.flag_outlined,
                    title: 'Nenhuma missão nesta semana',
                    message: 'Planeje uma categoria para começar.',
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ErrorView(
                    message: 'Não foi possível carregar seus dados.',
                  ),
                ),
              ],
            ),
            AppSpacing.gapMd,
            const SectionHeader.withIcon(
              title: 'Cabeçalho de seção',
              icon: Icons.category_outlined,
              trailing: SectionHeaderCounter(label: '3 / 12'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.xxs),
    child: Text(
      title.toUpperCase(),
      style: Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(color: context.palette.ink3),
    ),
  );
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.label, this.color, {this.onDark = false});

  final String label;
  final Color color;
  final bool onDark;

  @override
  Widget build(BuildContext context) => Container(
    width: 128,
    height: 56,
    alignment: Alignment.bottomLeft,
    padding: AppSpacing.allXxs,
    decoration: BoxDecoration(
      color: color,
      borderRadius: AppRadius.brSm,
      border: Border.all(color: context.palette.line),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: onDark ? AppColors.inkInverse : AppColors.inkLight,
      ),
    ),
  );
}

class _RadiusChip extends StatelessWidget {
  const _RadiusChip(this.label, this.radius);

  final String label;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) => Container(
    width: 110,
    height: 44,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: context.palette.paper2,
      borderRadius: radius,
      border: Border.all(color: context.palette.line),
    ),
    child: Text(label, style: Theme.of(context).textTheme.labelSmall),
  );
}
