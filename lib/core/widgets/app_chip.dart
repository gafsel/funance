import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// O que a pílula está dizendo.
enum StatusTone {
  /// Fato sem julgamento: "conta corrente", "5 lançamentos".
  neutral,

  /// Está como deveria: "no plano", "conciliado", "pago".
  ok,

  /// Merece atenção, ainda dá tempo: "fecha amanhã", "perto do limite".
  warning,

  /// Está errado ou venceu: "acima", "atrasado", "falhou".
  danger,

  /// É jogo: XP, missão, badge, patente. A única pílula dourada.
  reward,

  /// Informação secundária com peso: "compartilhada", "automática".
  info,
}

/// A pílula de status.
///
/// Substitui as quatro pílulas feitas à mão (duas delas com o mesmo nome,
/// `_buildInfoChip`, uma com raio 20 e outra com raio 8, em paletas
/// incompatíveis) e padroniza o que os cinco `Chip` do Material faziam por
/// conta própria. Só existe em forma de estádio, como manda o `chipTheme`.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.tone = StatusTone.neutral,
    this.icon,
    this.dense = false,
    this.color,
    this.onGame = false,
    this.iconOnly = false,
  }) : assert(
         !iconOnly || icon != null,
         'uma pílula só de ícone precisa do ícone',
       );

  final String label;
  final StatusTone tone;
  final IconData? icon;

  /// Compacta: para dentro de um tile de lista.
  final bool dense;

  /// Cor explícita, para quando o assunto da pílula é a própria cor — a de
  /// uma categoria, a de um pool. Ignora [tone].
  final Color? color;

  /// A pílula está sobre uma superfície de JOGO (escura, nos dois temas).
  ///
  /// Ali o texto passa a ser [AppColors.inkInverse] e o tom fica só no fundo
  /// e na borda. A tinta semântica é feita para papel: sobre `surfaceRaised`
  /// — a mais clara das superfícies de jogo, e onde o `onGame` põe o
  /// `paper2` — ela dá 3,64:1 a 4,21:1, abaixo do piso de TEXTO.
  ///
  /// A saída óbvia seria clarear as três tintas até passarem ali. Medi: para
  /// isso o vermelho vira pêssego e o laranja vira amarelo, e os dois deixam
  /// de se distinguir — o app perderia a diferença entre "atenção" e "erro"
  /// para ganhar contraste num lugar. Com a tinta branca o tom continua
  /// inteiro onde ele identifica (fundo e borda) e sai de onde ele precisava
  /// ser legível, que é o texto: 6,4:1 a 6,6:1.
  final bool onGame;

  /// Só o ÍCONE, sem a palavra.
  ///
  /// O [label] continua obrigatório e não some: ele vira o tooltip e o rótulo
  /// de leitor de tela. Uma pílula muda quando o espaço ao lado é de outra
  /// coisa mais importante — foi o caso do tipo do cofre na AppBar, que
  /// espremia o NOME do cofre para dizer "Pessoal" — e o que não pode
  /// acontecer é a informação sumir junto com o texto.
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    // A pílula tem DUAS cores, e elas só coincidem por acaso.
    //
    // `ink` escreve; `fill` pinta o fundo a 12% e a borda a 28%. Para as
    // semânticas as duas são a mesma, porque a tinta de texto diluída dá um
    // fundo discreto do mesmo matiz. Para a recompensa não dá: a pílula
    // dourada precisa de um fundo DE OURO, e ouro sobre papel claro é
    // ilegível como texto — 2,23:1 com `goldDeep`, que era o que havia aqui.
    // Separar os dois papéis mantém a pílula dourada E legível: fundo de
    // `gold`, texto de `rewardText` (13,37:1 no claro, 6,80:1 no escuro).
    final Color ink =
        color ??
        switch (tone) {
          StatusTone.neutral => palette.ink2,
          StatusTone.ok => palette.successText,
          StatusTone.warning => palette.warningText,
          StatusTone.danger => palette.dangerText,
          StatusTone.reward => palette.rewardText,
          StatusTone.info => palette.tealText,
        };

    final Color fill = color ?? switch (tone) {
      StatusTone.reward => AppColors.gold,
      _ => ink,
    };

    final Color labelInk = onGame ? AppColors.inkInverse : ink;

    final style =
        (dense ? theme.textTheme.labelSmall : theme.textTheme.labelMedium)
            ?.copyWith(color: labelInk);

    final decoration = BoxDecoration(
      color: fill.withValues(alpha: 0.12),
      borderRadius: AppRadius.brPill,
      border: Border.all(color: fill.withValues(alpha: 0.28)),
    );

    if (iconOnly) {
      return Tooltip(
        message: label,
        child: Semantics(
          label: label,
          child: Container(
            padding: EdgeInsets.all(dense ? 4 : AppSpacing.xxs),
            decoration: decoration,
            child: Icon(icon, size: dense ? 14 : 16, color: labelInk),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpacing.xs : AppSpacing.sm,
        vertical: dense ? 2 : AppSpacing.xxs,
      ),
      decoration: decoration,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 12 : 14, color: labelInk),
            SizedBox(width: dense ? 4 : AppSpacing.xxs),
          ],
          Flexible(
            child: Text(label, style: style, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

/// Chip selecionável.
///
/// Fino sobre o `chipTheme`: existe para que filtro, escolha de tipo e
/// seleção de período não precisem repetir `selectedColor`, `labelStyle` e
/// `shape` em cada tela.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onSelected,
    this.icon,
    this.onDeleted,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final IconData? icon;

  /// O "x" que remove o chip.
  ///
  /// Vale nas DUAS formas. Antes ele só chegava ao `Chip` estático: um chip
  /// selecionável com `onDeleted` compilava, parecia certo na leitura do
  /// código, e simplesmente não desenhava o "x" — o filtro de transações
  /// escolhe e remove, e a segunda metade não existia.
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    final avatar = icon == null
        ? null
        : Icon(icon, size: 16, color: selected ? palette.ink : palette.ink2);

    if (onSelected == null) {
      return Chip(
        avatar: avatar,
        label: Text(label),
        onDeleted: onDeleted,
        deleteIcon: const Icon(Icons.close, size: 16),
        backgroundColor: selected
            ? AppColors.gold.withValues(alpha: 0.18)
            : theme.chipTheme.backgroundColor,
      );
    }

    return FilterChip(
      avatar: avatar,
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      onDeleted: onDeleted,
      deleteIcon: const Icon(Icons.close, size: 16),
      showCheckmark: false,
    );
  }
}
