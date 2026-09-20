import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_spacing.dart';

/// A montagem de UM ícone do HUD: a figura, o número ao lado e o nome
/// embaixo quando há largura para ele.
///
/// Existe porque a cena tem DOIS grupos de ícones — os quatro do placar (as
/// missões, a bússola, o coach e as pendências) e os quatro do rodapé mensal
/// (poção, vila, incubados, veneno) — e o dono olhou para os dois juntos:
/// *"os ícones da parte superior, troca pra um formato parecido com o dos
/// ícones da parte de baixo (com o número do lado e o texto em baixo em telas
/// grandes o suficiente)"*.
///
/// Eles moram sobre a MESMA cena. Com duas montagens diferentes — número
/// embaixo em cima, número ao lado embaixo — a tela lia como dois HUDs
/// sobrepostos, e o usuário reaprendia a ler no meio do caminho. Uma
/// montagem só, num lugar só: duas cópias divergem na primeira mudança.
///
/// O que NÃO vem para cá: a figura (cada grupo desenha a sua), a semântica
/// (a do rodapé carrega o julgamento do valor; a do placar, o progresso da
/// semana) e o movimento. Aqui é layout, e só.
class HudSlotTile extends StatelessWidget {
  const HudSlotTile({
    super.key,
    required this.figure,
    required this.figureSize,
    required this.name,
    required this.showName,
    this.value,
    this.compact = false,
  });

  /// O anel com a figura dentro, já montado por quem chama.
  final Widget figure;

  /// O diâmetro do anel. É a largura da caixa que ancora a grade — e ela é
  /// reservada mesmo quando o slot não tem número.
  final double figureSize;

  /// O número curto ao lado da figura: "1/3", "72", "9/16", "1,1×".
  ///
  /// `null` quando não há o que contar — é o caso do coach, cujo estado quem
  /// diz é o anel. Sem número, o que fica ao lado da figura é nada: um traço
  /// ali seria uma legenda de ausência colada a um anel cheio.
  final String? value;

  /// O nome sob a figura. Só aparece com [showName].
  final String name;

  /// Desenhar o nome. Do tablet para cima: num celular quatro rótulos a mais
  /// disputam os mesmos 400 px com quatro números, e é o número que perde.
  final bool showName;

  /// Celular: tipografia menor.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // O ANEL é ancorado, e o número flutua à direita dele.
    //
    // Antes a linha inteira era centrada, e o resultado era um ritmo torto:
    // o anel de quem tem número curto ("72") ficava num x e o de quem tem
    // número longo ("< 0,1×") em outro, nos dois grupos e em desencontro
    // entre eles. Agora cada slot reserva a MESMA caixa para a figura, e é
    // o texto que se acomoda no que sobra — os quatro anéis do topo caem na
    // mesma grade dos quatro do rodapé.
    final figuraEValor = Row(
      children: [
        // A caixa da figura tem largura FIXA: é ela que fixa a grade.
        SizedBox(
          width: figureSize,
          child: Center(child: figure),
        ),
        AppSpacing.gapXxs,
        // O espaço do número existe mesmo sem número — é o que impede o anel
        // do coach (que não conta nada) de cair num x diferente do dos
        // outros três.
        Expanded(
          child: value == null
              ? const SizedBox.shrink()
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value!,
                    maxLines: 1,
                    style:
                        (compact
                                ? theme.textTheme.labelSmall
                                : theme.textTheme.labelMedium)
                            ?.copyWith(
                              color: AppColors.inkInverse,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                  ),
                ),
        ),
      ],
    );

    if (!showName) return Center(child: figuraEValor);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        figuraEValor,
        // O nome é EXCLUÍDO da semântica: ele já está no rótulo do botão, e
        // lido duas vezes viraria "Incubados: … Incubados".
        //
        // `Flexible` + `FittedBox`: a faixa do rodapé tem altura FIXA (é o
        // que impede a cena de reorganizar quando os números chegam), e a
        // 1,6 de escala de texto o nome estourava por 0,78px — a listra
        // amarela e preta atravessando o rodapé por causa de menos de um
        // pixel. Quem encolhe é o nome: a figura é o que identifica o slot.
        Flexible(
          child: ExcludeSemantics(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.inkInverse2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
