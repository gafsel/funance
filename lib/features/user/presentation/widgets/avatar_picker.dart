import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_durations.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/widgets/error_view.dart';
import 'package:funances/features/arena/domain/models/arena_state.dart';
import 'package:funances/features/arena/presentation/game/arena_sprites.dart';
import 'package:funances/features/arena/presentation/providers/arena_sprites_provider.dart';
import 'package:funances/l10n/app_localizations.dart';

/// O nome de um avatar na língua do app.
///
/// Fica aqui, e não no enum, porque `HeroSkin` é domínio e não conhece
/// `AppLocalizations` — e porque é o mesmo texto que o leitor de tela anuncia.
String avatarName(AppLocalizations l10n, HeroSkin skin) => switch (skin) {
  HeroSkin.knight => l10n.avatarKnight,
  HeroSkin.mage => l10n.avatarMage,
  HeroSkin.ranger => l10n.avatarRanger,
  HeroSkin.warrior => l10n.avatarWarrior,
  HeroSkin.healer => l10n.avatarHealer,
  HeroSkin.barbarian => l10n.avatarBarbarian,
  HeroSkin.monk => l10n.avatarMonk,
  HeroSkin.smith => l10n.avatarSmith,
};

/// O seletor do herói que representa o usuário na Arena.
///
/// **Um widget só**, usado no onboarding e na edição de perfil. Os dois
/// lugares mostram a mesma grade porque é a mesma decisão: quem escolheu no
/// onboarding tem de reconhecer a tela quando voltar para trocar.
///
/// O boneco é desenhado com a FOLHA da Arena, no tamanho grande e com
/// [ArenaSprites.pixelPaint] — a mesma tinta sem interpolação da cena. Sem
/// ela um sprite de 16 px esticado a 64 vira um borrão cinza, e o usuário
/// escolheria no escuro um personagem que na Arena tem contorno preto e cara
/// de boneco.
///
/// O cartão de cada tile é `surfaceDeep`, a superfície de jogo, nos dois
/// temas: a arte do Kenney traz um fundo escuro embutido no próprio sprite e
/// sobre papel claro cada boneco viraria um adesivo com moldura.
class AvatarPicker extends ConsumerWidget {
  const AvatarPicker({
    super.key,
    required this.selected,
    required this.onSelected,
    this.skins = HeroSkin.values,
  });

  /// O avatar marcado agora, ou NULO quando não há escolha para mostrar.
  ///
  /// Nulo é o estado de quem nunca escolheu e o de quem tem no documento um
  /// avatar que este app não conhece. Nos dois casos a grade fica sem anel
  /// nenhum, de propósito: marcar o cavaleiro seria afirmar uma escolha que
  /// não existe, e foi assim que uma edição de nome passou a regravar
  /// `knight` por cima de quem nunca tinha aberto o seletor.
  final HeroSkin? selected;

  final ValueChanged<HeroSkin> onSelected;

  /// O catálogo. Parâmetro para o teste poder encurtar a grade; a tela usa
  /// todos.
  final List<HeroSkin> skins;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folha = ref.watch(arenaSpritesProvider);
    final l10n = AppLocalizations.of(context)!;

    // Erro NÃO é carregando. Sem este ramo, uma folha que não abriu deixava
    // oito quadros escuros e vazios na tela para sempre, sem dizer o que
    // houve nem dar o que fazer — e a escolha do avatar ficava impossível sem
    // que nada parecesse quebrado.
    if (folha.hasError) {
      return ErrorView.forError(
        context,
        folha.error,
        onRetry: () => ref.invalidate(arenaSpritesProvider),
      );
    }

    final sprites = folha.valueOrNull;

    // `Wrap`, e não `GridView`: o seletor vive dentro de formulários que já
    // rolam, e uma grade com rolagem própria aninhada em outra briga pelo
    // gesto. O `Wrap` também é o que dá o comportamento certo nas duas
    // larguras sem um `breakpoint` escrito à mão — em 400 px saem três
    // colunas, em 1300 px sai a fila inteira.
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final skin in skins)
          _AvatarTile(
            key: ValueKey('avatar_${skin.name}'),
            label: avatarName(l10n, skin),
            sprite: sprites?.hero(skin),
            selected: skin == selected,
            onTap: () => onSelected(skin),
          ),
      ],
    );
  }
}

class _AvatarTile extends StatefulWidget {
  const _AvatarTile({
    super.key,
    required this.label,
    required this.sprite,
    required this.selected,
    required this.onTap,
  });

  final String label;

  /// Nulo enquanto a folha carrega. O tile mantém o TAMANHO nesse intervalo:
  /// sem isso a grade inteira saltaria quando os oito bonecos aparecessem.
  final Sprite? sprite;

  final bool selected;
  final VoidCallback onTap;

  @override
  State<_AvatarTile> createState() => _AvatarTileState();
}

class _AvatarTileState extends State<_AvatarTile> {
  bool _focused = false;

  /// Lado do quadro do boneco. 64 é o menor tamanho em que um sprite de 16 px
  /// cresce por um inteiro (4×) — meio pixel de escala é o que serrilha a
  /// pixel art.
  static const double _art = 64;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      // A ação de toque vem JUNTO com o rótulo. Com `excludeSemantics` e sem
      // ela, o nó anunciava "botão, Mago" e não tinha o que ativar: o leitor
      // de tela via a grade e não conseguia escolher nada nela.
      onTap: widget.onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: widget.onTap,
        onFocusChange: (value) => setState(() => _focused = value),
        borderRadius: AppRadius.brLg,
        child: Container(
          // O respiro do anel de FOCO é constante: reservado sempre, pintado
          // só quando focado. Um anel que aparece empurrando o vizinho faz a
          // grade inteira dançar ao navegar pelo teclado.
          padding: AppSpacing.allXxs,
          decoration: _focused
              ? BoxDecoration(
                  borderRadius: AppRadius.brLg,
                  // A tinta principal do tema contra o fundo da tela: 14,9:1
                  // no claro e 13,4:1 no escuro. O ouro do ESCOLHIDO não
                  // serve de realce de foco — ele já significa outra coisa,
                  // e sobre o cartão escuro dá 1,3:1 contra o próprio anel
                  // de seleção.
                  border: Border.all(color: palette.ink, width: 2),
                )
              : null,
          child: SizedBox(
            width: 92,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: AppDurations.respectingMotion(
                    context,
                    AppDurations.micro,
                  ),
                  padding: AppSpacing.allXxs,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDeep,
                    borderRadius: AppRadius.brMd,
                    // O anel do escolhido é o ouro do jogo, grosso o bastante
                    // para ler de relance; o não escolhido mantém um contorno
                    // fino da MESMA espessura, senão o tile mudaria de
                    // tamanho ao ser marcado e a grade dançaria a cada toque.
                    border: Border.all(
                      color: widget.selected ? AppColors.gold : palette.line,
                      width: 3,
                    ),
                  ),
                  child: SizedBox(
                    height: _art,
                    width: _art,
                    child: widget.sprite == null
                        ? const SizedBox.shrink()
                        : CustomPaint(painter: SpritePainter(widget.sprite!)),
                  ),
                ),
                AppSpacing.gapXxs,
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: widget.selected
                        ? palette.rewardText
                        : palette.ink2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// O bloco COMPLETO da escolha do herói: título, aviso, grade e a
/// pré-visualização na cena.
///
/// Existe para que o perfil e o onboarding mostrem a mesma coisa sem
/// copiar-colar a montagem. A grade sozinha ([AvatarPicker]) continua
/// disponível para quem quiser só ela.
class AvatarField extends StatelessWidget {
  const AvatarField({
    super.key,
    required this.selected,
    required this.onSelected,
    this.unknown = false,
  });

  final HeroSkin? selected;
  final ValueChanged<HeroSkin> onSelected;

  /// O documento tem um avatar que este app não conhece. Vira uma linha de
  /// aviso; sem ela a grade sem marca nenhuma parece defeito.
  final bool unknown;

  /// A partir desta largura a pré-visualização cabe AO LADO da grade.
  ///
  /// 560 e não um breakpoint do app: a conta é dos dois filhos — 196 px de
  /// cena, o respiro, e o que sobra tem de caber três colunas de 92 px, que é
  /// o mínimo para a grade não virar uma fila.
  static const double _sideBySide = 560;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final texto = Theme.of(context).textTheme;

    final grade = AvatarPicker(selected: selected, onSelected: onSelected);
    final cena = AvatarArenaPreview(skin: selected);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.profileAvatarLabel, style: texto.titleMedium),
        Text(
          l10n.profileAvatarHint,
          style: texto.bodySmall?.copyWith(color: palette.ink2),
        ),
        if (unknown) ...[
          AppSpacing.gapXxs,
          Text(
            l10n.profileAvatarUnknown,
            style: texto.bodySmall?.copyWith(color: palette.warningText),
          ),
        ],
        AppSpacing.gapSm,
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < _sideBySide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [grade, AppSpacing.gapSm, cena],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                cena,
                AppSpacing.gapMd,
                Expanded(child: grade),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// "Na Arena, você fica assim": o boneco escolhido sobre o chão da cena.
///
/// A grade mostra o sprite num cartão; a cena mostra o mesmo sprite sobre
/// tijolo e terra, com sombra no chão e no tamanho em que ele de fato
/// aparece. São leituras diferentes da mesma arte, e a segunda é a que
/// responde a pergunta que o usuário está fazendo — o QA de game design pediu
/// exatamente isto, e sai de graça: o painter é o mesmo da grade.
class AvatarArenaPreview extends ConsumerWidget {
  const AvatarArenaPreview({super.key, required this.skin});

  /// Nulo enquanto não há escolha: o painel mostra o cenário vazio, que é o
  /// convite para escolher.
  final HeroSkin? skin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sprites = ref.watch(arenaSpritesProvider).valueOrNull;
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;

    return Semantics(
      label: l10n.profileAvatarPreview,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: AppRadius.brMd,
            child: SizedBox(
              width: 196,
              height: 128,
              child: sprites == null
                  ? const ColoredBox(color: AppColors.surfaceDeep)
                  : CustomPaint(
                      painter: _ScenePainter(
                        sprites: sprites,
                        hero: skin == null ? null : sprites.hero(skin!),
                        shadow: AppColors.surfaceDeep.withValues(alpha: 0.35),
                      ),
                    ),
            ),
          ),
          AppSpacing.gapXxs,
          Text(
            l10n.profileAvatarPreview,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: palette.ink2),
          ),
        ],
      ),
    );
  }
}

/// Põe um sprite da folha da Arena num widget comum.
///
/// O Flame desenha em `Canvas`, que é exatamente o que um `CustomPainter`
/// entrega — não é preciso montar um `GameWidget` (com laço de jogo, relógio
/// e ciclo de vida próprios) para mostrar um boneco parado.
class SpritePainter extends CustomPainter {
  const SpritePainter(this.sprite);

  final Sprite sprite;

  @override
  void paint(Canvas canvas, Size size) {
    sprite.render(
      canvas,
      size: Vector2(size.width, size.height),
      overridePaint: ArenaSprites.pixelPaint,
    );
  }

  @override
  bool shouldRepaint(SpritePainter oldDelegate) =>
      oldDelegate.sprite != sprite;
}

/// Um pedaço da cena: parede, chão e um boneco de pé.
class _ScenePainter extends CustomPainter {
  const _ScenePainter({
    required this.sprites,
    required this.hero,
    required this.shadow,
  });

  final ArenaSprites sprites;
  final Sprite? hero;
  final Color shadow;

  /// Lado do tile do cenário, em pixels. Quatro vezes os 16 px da folha — a
  /// mesma escala inteira da grade, pelo mesmo motivo.
  static const double _tile = 32;

  /// Lado do boneco. É o tamanho que ele tem na cena de celular (o golden da
  /// Arena mede 56 px), e o ponto da pré-visualização é justamente mostrá-lo
  /// nesse tamanho, e não ampliado como na grade.
  static const double _hero = 56;

  @override
  void paint(Canvas canvas, Size size) {
    final horizonte = size.height * 0.42;
    final tinta = ArenaSprites.pixelPaint;

    for (var y = 0.0; y < horizonte; y += _tile) {
      for (var x = 0.0; x < size.width; x += _tile) {
        sprites.wall.render(
          canvas,
          position: Vector2(x, y),
          size: Vector2.all(_tile),
          overridePaint: tinta,
        );
      }
    }

    var linha = 0;
    for (var y = horizonte; y < size.height; y += _tile) {
      var coluna = 0;
      for (var x = 0.0; x < size.width; x += _tile) {
        // Um salpicado a cada três tiles, em diagonal. Alternando um a um o
        // piso vira um xadrez, que é o oposto do chão de terra que a cena
        // mostra.
        final chao = (linha + coluna) % 3 == 1
            ? sprites.floorSpeckled
            : sprites.floor;
        chao.render(
          canvas,
          position: Vector2(x, y),
          size: Vector2.all(_tile),
          overridePaint: tinta,
        );
        coluna++;
      }
      linha++;
    }

    final boneco = hero;
    if (boneco == null) return;

    final pes = size.height * 0.88;
    final esquerda = (size.width - _hero) / 2;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, pes - _hero * 0.06),
        width: _hero * 0.62,
        height: _hero * 0.12,
      ),
      Paint()..color = shadow,
    );

    boneco.render(
      canvas,
      position: Vector2(esquerda, pes - _hero),
      size: Vector2.all(_hero),
      overridePaint: tinta,
    );
  }

  @override
  bool shouldRepaint(_ScenePainter oldDelegate) =>
      oldDelegate.hero != hero || oldDelegate.sprites != sprites;
}
