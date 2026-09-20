import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/core/widgets/app_progress_bar.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

/// A barra de uma pool: o que foi GASTO, com o planejado e a meta marcados.
///
/// São três leituras, e a pergunta é comparativa — "o que eu gastei é muito?"
/// só tem resposta ao lado do planejado e da meta. A versão anterior empilhava
/// as três como ÁREAS sobrepostas na mesma barra, cada uma com o rótulo
/// pendurado embaixo da própria ponta. Duas coisas quebravam:
///
/// * **os rótulos se montavam um sobre o outro.** Com o planejado em 12% e o
///   real em 17%, "12,0%" e "17,0%" caíam quase no mesmo x e se sobrepunham
///   letra sobre letra; o rótulo da meta ficava num `Positioned` por cima do
///   trilho e colidia com os dois. Os goldens congelaram isso como se fosse o
///   desenho certo;
/// * **três tons da mesma tinta não se separam.** Medido: trilho, planejado e
///   real como lavagens do mesmo tom ficam entre 1,5:1 e 3,1:1 uns dos outros
///   — abaixo do piso de 3:1 de elemento gráfico, em qualquer combinação de
///   alfa. Área sobreposta não tem como ser acessível só por luminância.
///
/// A leitura nova: UMA área — o gasto real, na barra do design system, com o
/// trilho derivado da própria tinta — e DOIS marcadores fora dela, o planejado
/// acima e a meta abaixo. Marcador sobre o papel tem contraste de tinta sobre
/// papel, não de lavagem sobre lavagem, e dois marcadores em linhas
/// diferentes não têm como colidir. Os três números ficam numa linha própria,
/// com `spaceBetween`.
class AllocationProgressBar extends ConsumerWidget {
  const AllocationProgressBar({super.key, required this.allocation});

  final CategoryAllocation allocation;

  /// Altura das faixas de marcador, acima e abaixo da barra.
  static const double markerHeight = 10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final l10n = context.l10n;
    final locale = context.locale;

    final progressOf = FinanceViewProviders.planning503020AllocationProgress(
      allocation,
    );
    final isOver = ref.watch(progressOf.select((state) => state.isOver));
    final planned = ref.watch(
      progressOf.select((state) => state.currentPercentage),
    );
    final actual = ref.watch(
      progressOf.select((state) => state.actualPercentage),
    );

    // A TINTA do tema, não a cor cheia: é ela que o `AppProgressBar` dilui
    // para montar o trilho, e é o que garante os 3:1 entre o que foi gasto e
    // o que falta. A cor da pool continua nomeando a coluna — na aba, no
    // cabeçalho e na legenda —, que é onde ela identifica sem precisar ser
    // legível contra si mesma.
    final statusInk = isOver ? palette.dangerText : palette.successText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _Label(
                text: l10n.planning503020PlannedPercent(
                  planned.asPercent(locale: locale),
                ),
                color: palette.ink2,
                align: TextAlign.start,
              ),
            ),
            Expanded(
              child: _Label(
                text: l10n.planning503020TargetPercent(
                  allocation.idealPercentage.asPercent(locale: locale),
                ),
                color: palette.ink,
                align: TextAlign.center,
              ),
            ),
            Expanded(
              child: _Label(
                text: l10n.planning503020ActualPercent(
                  actual.asPercent(locale: locale),
                ),
                color: statusInk,
                align: TextAlign.end,
              ),
            ),
          ],
        ),
        AppSpacing.gapXxs,
        _Marker(fraction: planned, color: palette.ink2, pointsDown: true),
        AppProgressBar(
          value: actual,
          size: AppProgressSize.thick,
          color: statusInk,
          semanticLabel: l10n.planning503020ActualPercent(
            actual.asPercent(locale: locale),
          ),
        ),
        _Marker(
          fraction: allocation.idealPercentage,
          color: palette.ink,
          pointsDown: false,
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({
    required this.text,
    required this.color,
    required this.align,
  });

  final String text;
  final Color color;
  final TextAlign align;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: align,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
  );
}

/// Um marcador de posição, fora da barra.
///
/// `Align` com um x fracionário põe o CENTRO do filho na posição pedida sem
/// `LayoutBuilder` nenhum: a barra não precisa medir a si mesma para saber
/// onde desenhar. Fração fora de 0..1 é presa nas pontas — um planejado de
/// 130% marca o fim da barra, não um ponto fora dela.
class _Marker extends StatelessWidget {
  const _Marker({
    required this.fraction,
    required this.color,
    required this.pointsDown,
  });

  final double fraction;
  final Color color;

  /// `true` desenha acima da barra apontando para ela; `false`, abaixo.
  final bool pointsDown;

  @override
  Widget build(BuildContext context) {
    final f = fraction.isFinite ? fraction.clamp(0.0, 1.0) : 0.0;

    return SizedBox(
      height: AllocationProgressBar.markerHeight,
      child: Align(
        alignment: Alignment(f * 2 - 1, pointsDown ? 1 : -1),
        child: Icon(
          pointsDown ? Icons.arrow_drop_down : Icons.arrow_drop_up,
          size: AllocationProgressBar.markerHeight + 6,
          color: color,
        ),
      ),
    );
  }
}
