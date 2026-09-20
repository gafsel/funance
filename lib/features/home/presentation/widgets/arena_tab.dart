import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_breakpoints.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/features/arena/presentation/widgets/arena_view.dart';

/// A primeira aba: O JOGO, tela inteira.
///
/// Decisão 1 do dono, literal: *"a primeira aba deve ser só a arena. ao invés
/// de um container expansível, a aba inteira será a arena, eliminando a
/// necessidade de expandir."*
///
/// O que havia aqui antes eram sete blocos empilhados numa rolagem — a Arena
/// num cartão de 30% da altura, as pendências do leitor de notificação, o
/// resumo das missões, a linha do coaching, a linha da Bússola e uma meta em
/// destaque. Cada um foi para onde ele é mais útil do que era aqui:
///
/// | bloco                      | para onde foi                        |
/// |----------------------------|--------------------------------------|
/// | Arena (cartão)             | **é** a aba, sem moldura e sem título |
/// | Lançamentos identificados  | opção do FAB, com contador (decisão 8) |
/// | Missões da semana          | ícone de pergaminho na cena (decisão 7) |
/// | Coaching                   | ícone do coach na cena               |
/// | Bússola                    | ícone de bússola na cena             |
/// | Metas em destaque          | ferramenta "Metas" no FAB            |
///
/// **Sem rolagem.** A cena preenche o que sobra entre o placar e o rodapé
/// mensal, em qualquer altura de tela; não existe mais um "abaixo da dobra"
/// nesta aba. É o que a decisão pede ao dizer que não há mais o que expandir.
///
/// **A largura máxima é a da Arena inteira**, e não só a da cena: num monitor
/// de 1300px o placar de borda a borda deixa a vida dos heróis e a do monstro
/// a mil pixels uma da outra, e elas param de se enfrentar. Ver
/// [arenaMaxSceneWidth].
class ArenaTab extends ConsumerWidget {
  const ArenaTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // `LayoutBuilder` e não o `MediaQuery` da janela: no desktop a Home
        // divide a largura com o `NavigationRail`, e uma janela de 1040px
        // entrega à aba bem menos do que isso.
        final compact = constraints.layout.isCompact;

        return ColoredBox(
          // O fundo é o da cena, e não o do tema: nas bordas que sobram num
          // monitor, o cinza do app ao lado do azul profundo da arena leria
          // como uma imagem colada na página.
          color: AppColors.surfaceDeep,
          child: SafeArea(
            // Em baixo quem cuida do espaço é o `Scaffold` da Home: a barra
            // inferior já reserva a área segura do aparelho, e somar as duas
            // deixaria uma tarja vazia entre o rodapé mensal e a barra.
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: arenaMaxSceneWidth,
                ),
                child: ArenaView(compact: compact),
              ),
            ),
          ),
        );
      },
    );
  }
}
