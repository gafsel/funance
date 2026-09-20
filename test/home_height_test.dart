import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/widgets/app_scaffold.dart';
import 'package:funances/features/home/presentation/screens/home_screen.dart';
import 'package:funances/features/home/presentation/widgets/journey_tab.dart';

import 'support/home_harness.dart';

/// D2 — a Home tem de caber.
///
/// "A Home está longa demais" foi a segunda coisa que o dono disse sobre o
/// APK, e a primeira rodada tratou isso como uma questão de ORDEM. Não é:
/// reordenar o que não cabe só muda o que se perde primeiro. Com dados
/// típicos — três missões, o checklist da semana, uma meta em andamento, o
/// coaching e um mês com renda cadastrada — a tela media 1477px (2,7 telas) a
/// 400px e 1283px (2,4) a 800px.
///
/// O teto é DOIS viewports. Não é um número bonito: é a distância a partir da
/// qual o que está no fim da tela deixa de existir para quem abre o app e
/// olha. Ele é medido aqui, e não conferido no olho, porque a altura cresce
/// por acúmulo — cada bloco parece razoável sozinho.

/// A altura real do conteúdo da Jornada, em pixels.
double _alturaDoConteudo(WidgetTester tester) {
  final coluna = find
      .descendant(of: find.byType(AppContentWidth), matching: find.byType(Column))
      .first;
  return tester.getSize(coluna).height;
}

void main() {
  for (final largura in <double>[400, 800]) {
    testWidgets('D2 — a Home cabe em duas rolagens a ${largura.toInt()}px', (
      tester,
    ) async {
      const altura = 544.0;

      await pumpHome(
        tester,
        const JourneyTab(),
        overrides: homeOverrides(
          missions: homeTypicalMissions(),
          installments: homeTypicalInstallments(),
          goals: homeTypicalGoals(),
          categories: homeTypicalCategories,
          summary: homeTypicalSummary(),
          // A CONTAGEM REAL do aparelho: 35 pendências do leitor de
          // notificação e uma análise de coaching recente. A fixture antiga
          // tinha uma pendência e nenhuma análise — media 1,5 telas aqui
          // enquanto o app media 7,1.
          pendingAutomatic: homeTypicalPending(),
          lastInsight: homeTypicalInsight(),
        ),
        size: Size(largura, altura),
      );

      final medida = _alturaDoConteudo(tester);

      debugPrint(
        'ALTURA ${largura.toInt()}px: ${medida.toStringAsFixed(0)}px — '
        '${(medida / altura).toStringAsFixed(1)} telas',
      );

      expect(
        medida,
        lessThanOrEqualTo(altura * 2),
        reason:
            'a Home mede ${medida.toStringAsFixed(0)}px em ${largura.toInt()}'
            '×${altura.toInt()} — '
            '${(medida / altura).toStringAsFixed(1)} telas; o teto é 2',
      );
    });
  }

  /// A mesma medida na tela REAL, e não só na aba.
  ///
  /// `JourneyTab` é o conteúdo; `HomeScreen` é o que o app monta — com
  /// `AppBar`, barra inferior, `TabBarView` e o botão de lançar disputando o
  /// mesmo espaço. Medir só a aba deixaria de fora justamente o que encolhe o
  /// viewport, e foi assim que a Home mediu 1,5 telas aqui enquanto o
  /// aparelho mostrava 7,1.
  for (final largura in <double>[400, 800]) {
    testWidgets('D2 — e a Home REAL cabe a ${largura.toInt()}px', (
      tester,
    ) async {
      const altura = 544.0;

      await pumpHome(
        tester,
        const HomeScreen(),
        overrides: homeOverrides(
          missions: homeTypicalMissions(),
          installments: homeTypicalInstallments(),
          goals: homeTypicalGoals(),
          categories: homeTypicalCategories,
          summary: homeTypicalSummary(),
          pendingAutomatic: homeTypicalPending(),
          lastInsight: homeTypicalInsight(),
        ),
        size: Size(largura, altura),
      );

      final medida = _alturaDoConteudo(tester);
      final visivel = tester.getSize(find.byType(TabBarView)).height;

      debugPrint(
        'ALTURA REAL ${largura.toInt()}px: ${medida.toStringAsFixed(0)}px em '
        'viewport de ${visivel.toStringAsFixed(0)}px — '
        '${(medida / visivel).toStringAsFixed(1)} telas',
      );

      expect(
        medida,
        lessThanOrEqualTo(visivel * 2),
        reason:
            '${medida.toStringAsFixed(0)}px em ${visivel.toStringAsFixed(0)}'
            'px de viewport — ${(medida / visivel).toStringAsFixed(1)} telas',
      );
    });
  }
}
