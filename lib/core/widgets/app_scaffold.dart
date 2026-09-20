import 'package:flutter/material.dart';

import '../theme/app_breakpoints.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';

/// O esqueleto de uma tela.
///
/// Resolve de uma vez os dois problemas que a auditoria mediu: **109 dos 130
/// arquivos de tela não tinham nenhuma decisão de largura**, e nenhuma tela de
/// conteúdo principal limitava a largura de leitura — a 1400px o app mostrava
/// linhas de duzentos caracteres. Aqui a regra é uma só: gutter de 16 em
/// qualquer largura, e uma largura máxima de conteúdo que vem do breakpoint.
///
/// O botão de lançar fica no centro da barra inferior nas telas principais, e
/// some nos formulários e nos slides de coaching, onde já existe outro botão
/// principal — quem passa [launchAction] decide isso explicitamente.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomBar,
    this.rail,
    this.launchAction,
    this.maxWidth,
    this.gutter = AppSpacing.gutter,
    this.constrained = true,
    this.backgroundColor,
    this.extendBody = true,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;

  /// Barra inferior das telas principais. Só é montada em compacto e médio.
  final Widget? bottomBar;

  /// Navegação lateral do desktop. Só é montada em [AppLayout.wide].
  final Widget? rail;

  /// O botão de lançar. Central e entalhado quando há [bottomBar]; flutuante
  /// à direita quando a navegação é o [rail].
  final Widget? launchAction;

  /// FAB comum, para telas que têm uma ação própria que não é "lançar".
  final Widget? floatingActionButton;

  /// Sobrepõe a largura máxima do breakpoint. Use [AppLayout.readingMaxWidth]
  /// para formulários e texto corrido.
  final double? maxWidth;

  final double gutter;

  /// `false` entrega o corpo sem gutter nem largura máxima — para telas que
  /// gerenciam o próprio scroll com slivers de borda a borda.
  final bool constrained;

  final Color? backgroundColor;
  final bool extendBody;
  final bool? resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Deliberadamente as constraints do painel, não o `MediaQuery`: com
        // um rail de 200px aberto, uma janela de 1000px dizia "desktop"
        // enquanto o painel real tinha 800 — e a tabela renderizava num
        // espaço que não a comportava.
        final layout = constraints.layout;
        final showRail = rail != null && layout.usesRail;
        final showBottomBar = bottomBar != null && !showRail;

        final Widget content = constrained
            ? AppContentWidth(maxWidth: maxWidth, gutter: gutter, child: body)
            : body;

        final fab = launchAction ?? floatingActionButton;

        return Scaffold(
          appBar: appBar,
          backgroundColor: backgroundColor ?? context.palette.background,
          extendBody: extendBody,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
          body: showRail
              ? Row(
                  children: [
                    rail!,
                    Expanded(child: content),
                  ],
                )
              : content,
          bottomNavigationBar: showBottomBar ? bottomBar : null,
          floatingActionButton: fab,
          floatingActionButtonLocation: fab == null
              ? null
              : (showBottomBar
                    ? FloatingActionButtonLocation.centerDocked
                    : FloatingActionButtonLocation.endFloat),
        );
      },
    );
  }
}

/// Gutter de 16 e largura máxima de leitura.
///
/// Serve sozinho, para dentro de um `Scaffold` que já existe (a Home, por
/// exemplo, monta as quatro abas dentro do próprio `TabBarView`).
class AppContentWidth extends StatelessWidget {
  const AppContentWidth({
    super.key,
    required this.child,
    this.maxWidth,
    this.gutter = AppSpacing.gutter,
    this.alignment = Alignment.topCenter,
  });

  /// Largura de leitura (560): formulário, texto corrido, slide.
  const AppContentWidth.reading({
    Key? key,
    required Widget child,
    double gutter = AppSpacing.gutter,
  }) : this(key: key, gutter: gutter, maxWidth: 560, child: child);

  final Widget child;
  final double? maxWidth;
  final double gutter;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final limit = maxWidth ?? constraints.layout.contentMaxWidth;
        return Align(
          alignment: alignment,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: limit),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
