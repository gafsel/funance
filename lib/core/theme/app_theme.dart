import 'package:flutter/material.dart';

import 'app_breakpoints.dart';
import 'app_colors.dart';
import 'app_durations.dart';
import 'app_elevation.dart';
import 'app_palette.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// O tema do Funances, claro e escuro.
///
/// Antes eram 129 linhas que definiam nove componentes e nenhum tamanho de
/// fonte, com o `ColorScheme.error` roxo e a paleta usada como constante
/// global (495 `AppColors.*` contra 143 `colorScheme`). Trocar o tema não
/// trocava o app.
///
/// Agora o tema decide: cor, tipografia, raio, elevação e densidade de todos
/// os componentes que o app usa. Quem precisar de algo além disso encontra os
/// papéis em [AppPalette] (`context.palette`) — nunca um hexadecimal solto.
abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  /// Tema para um bloco de jogo (escuro) dentro de uma tela de papel.
  ///
  /// É o que faz "onde está escuro, você joga" funcionar sem que cada widget
  /// dentro do bloco precise saber que está sobre fundo escuro: campos,
  /// divisores, ícones e texto passam a ler o brilho certo.
  static ThemeData onGame(BuildContext context) {
    final base = Theme.of(context);
    if (base.brightness == Brightness.dark) return base;
    return dark.copyWith(
      scaffoldBackgroundColor: AppColors.surfaceDeep,
      extensions: <ThemeExtension<dynamic>>[
        AppPalette.dark.copyWith(
          background: AppColors.surfaceDeep,
          paper: AppColors.surfaceDefault,
          paper2: AppColors.surfaceRaised,
        ),
      ],
    );
  }

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final scheme = isDark ? _darkScheme : _lightScheme;
    final text = AppTypography.textTheme(palette.ink);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.background,
      canvasColor: palette.background,
      splashFactory: InkSparkle.splashFactory,
      textTheme: text,
      // O `primaryTextTheme` PRECISA vir explícito. `ThemeData` aplica o
      // `fontFamily` abaixo sobre a tipografia padrão do Material e só depois
      // faz `merge` com o que recebe; sem este parâmetro os quinze slots do
      // primário saíam todos em Inter — `displayLarge` inclusive —, e
      // qualquer componente que leia o primário (`AppBar` sobre a cor
      // primária, indicadores, tooltips de tema invertido) desenhava com a
      // fonte errada. A tinta é a de superfície de jogo: o primário é escuro
      // nos dois temas.
      primaryTextTheme: AppTypography.textTheme(AppColors.inkInverse),
      // Estes dois só têm efeito sobre os slots que NÃO definimos — na
      // prática, o fundo de segurança para qualquer `TextTheme` que o
      // Material crie por conta própria.
      fontFamily: AppTypography.body,
      fontFamilyFallback: AppTypography.bodyFallback,
      extensions: <ThemeExtension<dynamic>>[palette],

      // --- Navegação ---
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.ink,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: text.titleLarge?.copyWith(color: palette.ink),
        iconTheme: IconThemeData(color: palette.ink),
        actionsIconTheme: IconThemeData(color: palette.ink2),
        shape: Border(bottom: AppElevation.hairline(palette.line)),
      ),
      bottomAppBarTheme: BottomAppBarThemeData(
        color: AppColors.surfaceDeep,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceDeep,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.gold.withValues(alpha: 0.18),
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: AppRadius.brPill,
        ),
        height: 64,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? text.labelSmall?.copyWith(color: AppColors.gold)
              : text.labelSmall?.copyWith(color: AppColors.inkInverse2),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? AppColors.gold
                : AppColors.inkInverse2,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.surfaceDeep,
        indicatorColor: AppColors.gold.withValues(alpha: 0.18),
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: AppRadius.brMd,
        ),
        elevation: 0,
        minExtendedWidth: 200,
        useIndicator: true,
        selectedIconTheme: const IconThemeData(color: AppColors.gold, size: 24),
        unselectedIconTheme: const IconThemeData(
          color: AppColors.inkInverse2,
          size: 24,
        ),
        selectedLabelTextStyle: text.labelLarge?.copyWith(
          color: AppColors.inkInverse,
        ),
        unselectedLabelTextStyle: text.labelLarge?.copyWith(
          color: AppColors.inkInverse2,
          fontWeight: FontWeight.w500,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: palette.ink,
        // `ink3` é tinta de coisa DESLIGADA — placeholder, ícone apagado,
        // texto desabilitado —, e uma aba fechada continua sendo um destino
        // clicável. Em `ink3` ela dava 2,66:1 sobre papel claro; em `ink2`,
        // 5,70:1. A hierarquia entre aberta e fechada continua existindo,
        // agora pelo peso da fonte.
        unselectedLabelColor: palette.ink2,
        labelStyle: text.labelLarge,
        unselectedLabelStyle: text.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        indicatorColor: AppColors.gold,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: palette.line,
        overlayColor: WidgetStatePropertyAll(
          AppColors.gold.withValues(alpha: 0.08),
        ),
      ),

      // --- Superfícies ---
      cardTheme: CardThemeData(
        color: palette.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brLg,
          side: AppElevation.hairline(palette.line),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
        titleTextStyle: text.titleLarge?.copyWith(color: palette.ink),
        contentTextStyle: text.bodyMedium?.copyWith(color: palette.ink2),
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.paper,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: palette.paper,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        // O puxador é o que avisa que a folha se arrasta; some em `ink3`
        // (2,66:1 sobre papel claro).
        dragHandleColor: palette.ink2,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brSheet),
        constraints: const BoxConstraints(maxWidth: AppBreakpoints.wide),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: palette.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brMd,
          side: AppElevation.hairline(palette.line),
        ),
        textStyle: text.bodyMedium?.copyWith(color: palette.ink),
      ),
      dividerTheme: DividerThemeData(
        color: palette.line,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.surfaceRaised : palette.ink,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: AppColors.inkInverse,
        ),
        actionTextColor: AppColors.gold,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: palette.ink,
          borderRadius: AppRadius.brSm,
        ),
        textStyle: text.bodySmall?.copyWith(color: AppColors.inkInverse),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        waitDuration: AppDurations.toastDwell,
      ),

      // --- Controles ---
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.goldInk,
          disabledBackgroundColor: palette.line,
          disabledForegroundColor: palette.ink3,
          textStyle: text.labelLarge,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
          elevation: 0,
        ),
      ),
      // `ElevatedButton` e `FilledButton` eram dois CTAs primários diferentes
      // — um dourado, outro turquesa — usados sem regra na mesma sessão. Agora
      // são o mesmo botão; qual dos dois o código chama deixou de importar.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.goldInk,
          disabledBackgroundColor: palette.line,
          disabledForegroundColor: palette.ink3,
          textStyle: text.labelLarge,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.tealText,
          textStyle: text.labelLarge,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          side: BorderSide(color: palette.line),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.tealText,
          textStyle: text.labelLarge,
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brSm),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: palette.ink2,
          minimumSize: const Size(40, 40),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brSm),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.goldInk,
        elevation: 4,
        focusElevation: 4,
        hoverElevation: 6,
        highlightElevation: 2,
        shape: const CircleBorder(),
        extendedTextStyle: text.labelLarge,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: palette.paper,
          foregroundColor: palette.ink2,
          selectedBackgroundColor: AppColors.gold.withValues(alpha: 0.18),
          selectedForegroundColor: palette.ink,
          side: BorderSide(color: palette.line),
          textStyle: text.labelMedium,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.paper2,
        selectedColor: AppColors.gold.withValues(alpha: 0.18),
        secondarySelectedColor: AppColors.gold.withValues(alpha: 0.18),
        disabledColor: palette.line,
        checkmarkColor: palette.ink,
        surfaceTintColor: Colors.transparent,
        labelStyle: text.labelMedium?.copyWith(color: palette.ink),
        secondaryLabelStyle: text.labelMedium?.copyWith(color: palette.ink),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
        side: BorderSide(color: palette.line),
        shape: const StadiumBorder(),
        elevation: 0,
        pressElevation: 0,
        showCheckmark: false,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xxs,
        ),
        minVerticalPadding: AppSpacing.xs,
        horizontalTitleGap: AppSpacing.sm,
        iconColor: palette.ink2,
        textColor: palette.ink,
        titleTextStyle: text.titleMedium?.copyWith(color: palette.ink),
        subtitleTextStyle: text.bodySmall?.copyWith(color: palette.ink2),
        leadingAndTrailingTextStyle: text.labelMedium?.copyWith(
          color: palette.ink2,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        selectedColor: palette.ink,
        selectedTileColor: AppColors.gold.withValues(alpha: 0.10),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: palette.ink2,
        collapsedIconColor: palette.ink2,
        textColor: palette.ink,
        collapsedTextColor: palette.ink,
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        childrenPadding: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        collapsedShape: const RoundedRectangleBorder(
          borderRadius: AppRadius.brMd,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.goldInk
              : palette.paper,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.gold
              : palette.line,
        ),
        trackOutlineColor: WidgetStatePropertyAll(palette.line),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.gold
              : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(AppColors.goldInk),
        // A borda de uma caixa VAZIA é a única coisa que revela que existe um
        // controle ali: é elemento gráfico essencial, piso de 3:1. `ink3`
        // dava 2,66:1 sobre papel claro.
        side: BorderSide(color: palette.ink2, width: 1.5),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brXs),
      ),
      radioTheme: RadioThemeData(
        // Mesma regra do checkbox: o aro do rádio não marcado é o que mostra
        // que há uma escolha a fazer.
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.gold
              : palette.ink2,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.gold,
        inactiveTrackColor: palette.line,
        thumbColor: AppColors.gold,
        overlayColor: AppColors.gold.withValues(alpha: 0.16),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.teal,
        linearTrackColor: palette.line,
        linearMinHeight: AppSpacing.xs,
        circularTrackColor: palette.line,
        borderRadius: AppRadius.brXs,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.paper2,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        border: _inputBorder(palette.line),
        enabledBorder: _inputBorder(palette.line),
        focusedBorder: _inputBorder(AppColors.gold, width: 2),
        // A borda de erro é tinta de erro DO TEMA, não o vermelho cheio: no
        // escuro o cheio dava 2,91:1 contra o papel do campo, abaixo do piso
        // de 3:1 de elemento de interface — a borda que avisa do erro era a
        // que menos se via.
        errorBorder: _inputBorder(palette.dangerText),
        focusedErrorBorder: _inputBorder(palette.dangerText, width: 2),
        disabledBorder: _inputBorder(palette.line),
        labelStyle: text.bodyMedium?.copyWith(color: palette.ink2),
        floatingLabelStyle: text.labelMedium?.copyWith(color: palette.ink2),
        // O placeholder é conteúdo — diz o formato esperado do campo — e não
        // um estado desabilitado. Em `ink3` ele dava 2,49:1 sobre o papel do
        // campo; em `ink2`, 5,34:1.
        hintStyle: text.bodyMedium?.copyWith(color: palette.ink2),
        helperStyle: text.bodySmall?.copyWith(color: palette.ink2),
        errorStyle: text.bodySmall?.copyWith(color: palette.dangerText),
        prefixIconColor: palette.ink2,
        suffixIconColor: palette.ink2,
      ),
      iconTheme: IconThemeData(color: palette.ink2, size: 24),
      primaryIconTheme: const IconThemeData(color: AppColors.inkInverse),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: text.labelMedium?.copyWith(color: palette.ink2),
        dataTextStyle: text.bodyMedium?.copyWith(color: palette.ink),
        dividerThickness: 1,
        headingRowColor: WidgetStatePropertyAll(palette.paper2),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: AppRadius.brSm,
        borderSide: BorderSide(color: color, width: width),
      );

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.surfaceDeep,
    onPrimary: AppColors.inkInverse,
    primaryContainer: Color(0xFFD9E8EB),
    onPrimaryContainer: AppColors.inkLight,
    secondary: AppColors.tealInk,
    onSecondary: AppColors.paperLight,
    secondaryContainer: Color(0xFFD3F1EF),
    onSecondaryContainer: Color(0xFF073A43),
    tertiary: AppColors.gold,
    onTertiary: AppColors.goldInk,
    tertiaryContainer: Color(0xFFFFF0BF),
    onTertiaryContainer: AppColors.goldInk,
    // O erro do app era roxo (um roxo) enquanto o código
    // chamava três vermelhos diferentes. Agora erro e destrutivo são o mesmo
    // token, e ele é o do `ColorScheme`.
    //
    // `error` é a TINTA de erro do tema, não o vermelho de preenchimento. O
    // Flutter usa este papel dos dois jeitos — texto de erro, ícone de erro,
    // e fundo de botão destrutivo com `onError` por cima — e o vermelho cheio
    // não serve para nenhum dos dois no claro: dá 3,91:1 sobre papel como
    // tinta, e 3,91:1 contra o branco como fundo. O vermelho cheio continua
    // sendo o da borda de campo e o dos ícones grandes, onde 3:1 basta.
    error: AppColors.dangerInk,
    onError: AppColors.paperLight,
    errorContainer: Color(0xFFFBDCDD),
    onErrorContainer: AppColors.dangerInk,
    surface: AppColors.paperLight,
    onSurface: AppColors.inkLight,
    onSurfaceVariant: AppColors.ink2Light,
    surfaceContainerLowest: AppColors.paperLight,
    surfaceContainerLow: AppColors.paper2Light,
    surfaceContainer: AppColors.backgroundLight,
    surfaceContainerHigh: Color(0xFFE8F0F2),
    surfaceContainerHighest: Color(0xFFDFEAEC),
    surfaceDim: Color(0xFFE3EBED),
    surfaceBright: AppColors.paperLight,
    outline: AppColors.ink3Light,
    outlineVariant: AppColors.lineLight,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: AppColors.surfaceDeep,
    onInverseSurface: AppColors.inkInverse,
    inversePrimary: AppColors.teal,
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.teal,
    onPrimary: AppColors.surfaceDeep,
    primaryContainer: AppColors.surfaceRaised,
    onPrimaryContainer: AppColors.inkInverse,
    secondary: AppColors.teal,
    onSecondary: AppColors.surfaceDeep,
    secondaryContainer: Color(0xFF164B5A),
    onSecondaryContainer: AppColors.inkInverse2,
    tertiary: AppColors.gold,
    onTertiary: AppColors.goldInk,
    tertiaryContainer: Color(0xFF5A4600),
    onTertiaryContainer: Color(0xFFFFF0BF),
    // No escuro a tinta de erro é clara e quem escreve por cima dela é a
    // tinta escura — a convenção do Material 3, e a única forma de o par
    // fechar 4,5:1 nos dois sentidos.
    error: AppColors.dangerInkDark,
    onError: AppColors.dangerInk,
    errorContainer: Color(0xFF5E1417),
    onErrorContainer: Color(0xFFFFDAD9),
    surface: AppColors.paperDark,
    onSurface: AppColors.inkDark,
    onSurfaceVariant: AppColors.ink2Dark,
    surfaceContainerLowest: Color(0xFF0A2831),
    surfaceContainerLow: AppColors.backgroundDark,
    surfaceContainer: AppColors.paper2Dark,
    surfaceContainerHigh: Color(0xFF1B4B58),
    surfaceContainerHighest: AppColors.surfaceRaised,
    surfaceDim: AppColors.backgroundDark,
    surfaceBright: Color(0xFF24525F),
    outline: AppColors.ink3Dark,
    outlineVariant: AppColors.lineDark,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE3EBED),
    onInverseSurface: AppColors.inkLight,
    inversePrimary: AppColors.tealInk,
  );
}
