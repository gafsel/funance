import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_durations.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';
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

  /// O avatar marcado agora. Nunca é nulo: a tela resolve o padrão antes de
  /// chegar aqui, para que ninguém veja uma grade sem nada escolhido.
  final HeroSkin selected;

  final ValueChanged<HeroSkin> onSelected;

  /// O catálogo. Parâmetro para o teste poder encurtar a grade; a tela usa
  /// todos.
  final List<HeroSkin> skins;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sprites = ref.watch(arenaSpritesProvider).valueOrNull;
    final l10n = AppLocalizations.of(context)!;

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
            skin: skin,
            label: avatarName(l10n, skin),
            sprite: sprites?.hero(skin),
            selected: skin == selected,
            onTap: () => onSelected(skin),
          ),
      ],
    );
  }
}

class _AvatarTile extends StatelessWidget {
  const _AvatarTile({
    super.key,
    required this.skin,
    required this.label,
    required this.sprite,
    required this.selected,
    required this.onTap,
  });

  final HeroSkin skin;
  final String label;

  /// Nulo enquanto a folha carrega. O tile mantém o TAMANHO nesse intervalo:
  /// sem isso a grade inteira saltaria quando os oito bonecos aparecessem.
  final Sprite? sprite;

  final bool selected;
  final VoidCallback onTap;

  /// Lado do quadro do boneco. 64 é o menor tamanho em que um sprite de 16 px
  /// cresce por um inteiro (4×) — meio pixel de escala é o que serrilha a
  /// pixel art.
  static const double _art = 64;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brMd,
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
                  // fino da MESMA espessura, senão o tile mudaria de tamanho
                  // ao ser marcado e a grade dançaria a cada toque.
                  border: Border.all(
                    color: selected ? AppColors.gold : palette.line,
                    width: 3,
                  ),
                ),
                child: SizedBox(
                  height: _art,
                  width: _art,
                  child: sprite == null
                      ? const SizedBox.shrink()
                      : CustomPaint(painter: _SpritePainter(sprite!)),
                ),
              ),
              AppSpacing.gapXxs,
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? palette.rewardText : palette.ink2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Põe um sprite da folha da Arena num widget comum.
///
/// O Flame desenha em `Canvas`, que é exatamente o que um `CustomPainter`
/// entrega — não é preciso montar um `GameWidget` (com laço de jogo, relógio
/// e ciclo de vida próprios) para mostrar um boneco parado.
class _SpritePainter extends CustomPainter {
  const _SpritePainter(this.sprite);

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
  bool shouldRepaint(_SpritePainter oldDelegate) =>
      oldDelegate.sprite != sprite;
}
