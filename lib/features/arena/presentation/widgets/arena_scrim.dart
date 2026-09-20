import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';

/// O véu que garante contraste do HUD sobre a cena.
///
/// Pedido do dono: *"deixe a animação tomar a tela toda e faça os ícones
/// fazerem um overlay com um gradient que garante um contraste"*. A cena
/// passou a ser o FUNDO da aba inteira, e o placar, a faixa de ícones e o HUD
/// mensal passaram a flutuar sobre ela — sobre parede de tijolo cinza, sobre
/// areia clara, sobre um braseiro laranja ou sobre um monstro vermelho,
/// dependendo de onde a luta estiver.
///
/// A forma é deliberada, e não é um gradiente único do topo ao fim:
///
/// - a parte que carrega TEXTO é uma chapa de opacidade [coverAlpha], igual
///   em toda a sua altura. Um gradiente que começa opaco e vai clareando dá
///   ao texto do fim da faixa menos véu do que ao do começo — e o contraste
///   de uma tela não pode depender de qual linha do HUD se está lendo;
/// - só DEPOIS dela vem a banda de desvanecimento, de [fadeHeight], que
///   dissolve a chapa na cena. É ela que impede o corte reto, que leria como
///   uma barra colada por cima do jogo em vez de uma sombra da própria cena.
///
/// [coverAlpha] não é um número de gosto: sobre a arte mais CLARA possível
/// (branco puro), o `inkInverse` e o `inkInverse2` do HUD ficam acima de
/// 4,5:1 contra a chapa resultante. A conta está em
/// `test/arena/arena_contrast_test.dart`, e é ela que manda aqui — se o véu
/// afinar, o teste cai.
class ArenaScrim extends StatelessWidget {
  const ArenaScrim({super.key, required this.child, required this.fromTop});

  /// O véu do topo (placar e ícones).
  const ArenaScrim.top({Key? key, required Widget child})
    : this(key: key, child: child, fromTop: true);

  /// O véu do pé (HUD mensal).
  const ArenaScrim.bottom({Key? key, required Widget child})
    : this(key: key, child: child, fromTop: false);

  /// Opacidade da chapa sob o conteúdo.
  static const double coverAlpha = 0.93;

  /// Altura da banda que dissolve a chapa na cena, em pixels lógicos.
  static const double fadeHeight = 28;

  /// A cor da chapa, já composta com a sua opacidade.
  static Color get cover =>
      AppColors.surfaceDeep.withValues(alpha: coverAlpha);

  final Widget child;
  final bool fromTop;

  @override
  Widget build(BuildContext context) {
    final fade = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: fromTop ? Alignment.topCenter : Alignment.bottomCenter,
          end: fromTop ? Alignment.bottomCenter : Alignment.topCenter,
          colors: <Color>[cover, AppColors.surfaceDeep.withValues(alpha: 0)],
        ),
      ),
      child: const SizedBox(height: fadeHeight, width: double.infinity),
    );

    final chapa = ColoredBox(color: cover, child: child);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: fromTop ? [chapa, fade] : [fade, chapa],
    );
  }
}
