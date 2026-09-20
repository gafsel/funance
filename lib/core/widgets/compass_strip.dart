import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_durations.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_progress_bar.dart';

/// Um dos quatro componentes da Bússola, já traduzido.
@immutable
class CompassComponentData {
  const CompassComponentData({
    required this.label,
    required this.icon,
    required this.fraction,
    this.detail,
  });

  final String label;
  final IconData icon;

  /// Fração de 0 a 1.
  final double fraction;

  /// Uma linha de explicação: "3,2 meses de despesas guardados".
  final String? detail;
}

/// A Bússola da Liberdade em uma linha, que expande.
///
/// A Home antiga dava um bloco grande e estático à Bússola, que muda uma vez
/// por mês. A regra nova: o que muda por dia ocupa o corpo, o que muda por mês
/// vira linha. Aqui ficam o número, a patente e a VARIAÇÃO desde o ponto
/// anterior do histórico; os quatro componentes só aparecem quando alguém
/// toca.
///
/// A variação é mensal porque o dado é mensal. O índice de liberdade é
/// publicado pelo servidor uma vez por mês (`healthHistory` vem em
/// `monthKey`), e não existe ponto semanal para comparar: a documentação
/// dizia "variação da semana" e o texto na tela dizia "desde o mês passado",
/// duas promessas diferentes para o mesmo número. Se um dia houver série
/// semanal, é [deltaLabel] que muda — o widget não calcula período nenhum.
///
/// Widget puro: quem liga aos providers é a camada de feature.
class CompassStrip extends StatefulWidget {
  const CompassStrip({
    super.key,
    required this.title,
    required this.score,
    required this.tierLabel,
    required this.components,
    this.deltaLabel,
    this.delta,
    this.onOpenDetails,
    this.openDetailsLabel,
    this.initiallyExpanded = false,
    this.onGame = false,
  });

  /// "Bússola".
  final String title;

  /// Índice de 0 a 100. `null` enquanto a bússola está sendo calibrada.
  final double? score;

  /// A patente: "Estrategista".
  final String tierLabel;

  final List<CompassComponentData> components;

  /// "3 desde o mês passado" — já traduzido, com o período que a fonte de
  /// dados de fato oferece, e sem o sinal, que a seta desenha.
  final String? deltaLabel;

  /// A variação em pontos. O sinal decide a seta e a cor.
  final double? delta;

  final VoidCallback? onOpenDetails;
  final String? openDetailsLabel;

  final bool initiallyExpanded;

  /// `true` quando a linha está sobre uma superfície de jogo.
  final bool onGame;

  @override
  State<CompassStrip> createState() => _CompassStripState();
}

class _CompassStripState extends State<CompassStrip> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final ink = widget.onGame ? palette.onGame : palette.ink;
    final ink2 = widget.onGame ? palette.onGame2 : palette.ink2;

    final delta = widget.delta;
    final hasDelta = delta != null && delta != 0 && widget.deltaLabel != null;

    return Container(
      decoration: BoxDecoration(
        color: widget.onGame ? null : palette.paper,
        borderRadius: AppRadius.brMd,
        border: Border.all(
          color: widget.onGame ? AppColors.surfaceRaised : palette.line,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // A linha é um BOTÃO que abre e fecha, e o leitor de tela não tinha
          // como saber nem uma coisa nem outra: ela se anunciava como um
          // punhado de textos soltos — "Bússola", "48", "Estrategista" — sem
          // dizer que respondia ao toque, e sem dizer se os quatro
          // componentes estavam à mostra ou escondidos.
          Semantics(
            container: true,
            excludeSemantics: true,
            button: true,
            expanded: _expanded,
            onTap: () => setState(() => _expanded = !_expanded),
            label: widget.title,
            value: [
              widget.score == null ? '—' : widget.score!.round().toString(),
              widget.tierLabel,
              ?(hasDelta ? widget.deltaLabel : null),
            ].join(', '),
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
                      Icon(Icons.explore_outlined, size: 18, color: ink2),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        widget.title,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: ink2,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        widget.score == null
                            ? '—'
                            : widget.score!.round().toString(),
                        style: AppTypography.counter(
                          ink,
                        ).copyWith(fontSize: 18),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          widget.tierLabel,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: ink2,
                          ),
                        ),
                      ),
                      if (hasDelta) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Icon(
                          delta > 0
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down,
                          size: 18,
                          color: delta > 0
                              ? palette.successText
                              : palette.dangerText,
                        ),
                        Flexible(
                          child: Text(
                            widget.deltaLabel!,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: delta > 0
                                  ? palette.successText
                                  : palette.dangerText,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      AnimatedRotation(
                        turns: _expanded ? 0.25 : 0,
                        duration: AppDurations.respectingMotion(
                          context,
                          AppDurations.normal,
                        ),
                        curve: AppDurations.curve,
                        child: Icon(Icons.chevron_right, size: 20, color: ink2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: _CompassDetails(
              components: widget.components,
              onOpenDetails: widget.onOpenDetails,
              openDetailsLabel: widget.openDetailsLabel,
              ink: ink,
              ink2: ink2,
            ),
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
    );
  }
}

class _CompassDetails extends StatelessWidget {
  const _CompassDetails({
    required this.components,
    required this.onOpenDetails,
    required this.openDetailsLabel,
    required this.ink,
    required this.ink2,
  });

  final List<CompassComponentData> components;
  final VoidCallback? onOpenDetails;
  final String? openDetailsLabel;
  final Color ink;
  final Color ink2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          for (final c in components) ...[
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Row(
                children: [
                  Icon(c.icon, size: 16, color: ink2),
                  const SizedBox(width: AppSpacing.xs),
                  SizedBox(
                    width: 84,
                    child: Text(
                      c.label,
                      style: theme.textTheme.bodySmall?.copyWith(color: ink),
                    ),
                  ),
                  Expanded(
                    child: AppProgressBar(
                      value: c.fraction,
                      size: AppProgressSize.thin,
                      semanticLabel: c.label,
                    ),
                  ),
                  if (c.detail != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        c.detail!,
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: ink2),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (onOpenDetails != null && openDetailsLabel != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onOpenDetails,
                child: Text(openDetailsLabel!),
              ),
            ),
        ],
      ),
    );
  }
}
