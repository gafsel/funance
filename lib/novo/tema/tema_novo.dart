import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tokens da identidade do Funances 2. Este é o único arquivo do app novo
/// que pode escrever uma cor, um raio ou um estilo de texto cru.
///
/// Regras da identidade: petróleo é a tinta, amarelo é calor (usado com
/// parcimônia, para o que merece atenção boa), despesa NÃO é vermelha.
/// Vermelho fica reservado para problema de verdade.
class Cores {
  const Cores({
    required this.fundo,
    required this.superficie,
    required this.superficieAlta,
    required this.tinta,
    required this.tintaSuave,
    required this.linha,
    required this.primaria,
    required this.sobrePrimaria,
    required this.calor,
    required this.sobreCalor,
    required this.positivo,
    required this.atencao,
    required this.problema,
  });

  final Color fundo;
  final Color superficie;
  final Color superficieAlta;
  final Color tinta;
  final Color tintaSuave;
  final Color linha;
  final Color primaria;
  final Color sobrePrimaria;
  final Color calor;
  final Color sobreCalor;
  final Color positivo;
  final Color atencao;
  final Color problema;

  static const claro = Cores(
    fundo: Color(0xFFF6F8F7),
    superficie: Color(0xFFFFFFFF),
    superficieAlta: Color(0xFFEDF2F1),
    tinta: Color(0xFF0E3440),
    tintaSuave: Color(0xFF5B7480),
    linha: Color(0xFFDCE5E3),
    primaria: Color(0xFF0F7C82),
    sobrePrimaria: Color(0xFFFFFFFF),
    calor: Color(0xFFFFC233),
    sobreCalor: Color(0xFF0E3440),
    positivo: Color(0xFF23804A),
    atencao: Color(0xFFB86B0E),
    problema: Color(0xFFC23A3A),
  );

  static const escuro = Cores(
    fundo: Color(0xFF0A1F26),
    superficie: Color(0xFF11303A),
    superficieAlta: Color(0xFF173D49),
    tinta: Color(0xFFE8F1F0),
    tintaSuave: Color(0xFF9DB5BC),
    linha: Color(0xFF24505D),
    primaria: Color(0xFF3FB8BD),
    sobrePrimaria: Color(0xFF06262B),
    calor: Color(0xFFFFC233),
    sobreCalor: Color(0xFF0E3440),
    positivo: Color(0xFF2E9E5B),
    atencao: Color(0xFFE08A1E),
    problema: Color(0xFFD64545),
  );

  static Cores de(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? escuro : claro;
}

abstract final class Raios {
  static final p = BorderRadius.circular(8);
  static final m = BorderRadius.circular(14);
  static final g = BorderRadius.circular(22);
  static final pilula = BorderRadius.circular(999);
}

abstract final class Espacos {
  static const double xp = 4;
  static const double p = 8;
  static const double m = 12;
  static const double g = 16;
  static const double xg = 24;
  static const double xxg = 32;
}

/// Largura a partir da qual o app usa o desenho de mesa (mais denso).
const double larguraDeMesa = 900;

bool ehMesa(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= larguraDeMesa;

ThemeData temaNovo(Brightness brilho) {
  final c = brilho == Brightness.dark ? Cores.escuro : Cores.claro;
  final base = ThemeData(brightness: brilho, useMaterial3: true);
  final texto = GoogleFonts.interTextTheme(base.textTheme).apply(
    bodyColor: c.tinta,
    displayColor: c.tinta,
  );
  TextStyle? titulo(TextStyle? s, {double? tamanho}) => GoogleFonts.figtree(
        textStyle: s,
        fontWeight: FontWeight.w700,
        fontSize: tamanho,
        color: c.tinta,
        // Números alinhados em coluna: valor nunca "dança" ao mudar.
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  return base.copyWith(
    scaffoldBackgroundColor: c.fundo,
    colorScheme: ColorScheme.fromSeed(
      seedColor: c.primaria,
      brightness: brilho,
    ).copyWith(
      primary: c.primaria,
      onPrimary: c.sobrePrimaria,
      surface: c.superficie,
      onSurface: c.tinta,
      error: c.problema,
      outline: c.linha,
      outlineVariant: c.linha,
    ),
    textTheme: texto.copyWith(
      displaySmall: titulo(texto.displaySmall, tamanho: 40),
      headlineMedium: titulo(texto.headlineMedium, tamanho: 26),
      titleLarge: titulo(texto.titleLarge, tamanho: 20),
      titleMedium: titulo(texto.titleMedium, tamanho: 16),
      bodyLarge: texto.bodyLarge?.copyWith(fontSize: 16, height: 1.4),
      bodyMedium: texto.bodyMedium?.copyWith(fontSize: 14, height: 1.4),
      bodySmall: texto.bodySmall?.copyWith(
        fontSize: 12.5,
        color: c.tintaSuave,
        height: 1.35,
      ),
      labelLarge: texto.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
    dividerTheme: DividerThemeData(color: c.linha, thickness: 1, space: 1),
    cardTheme: CardThemeData(
      color: c.superficie,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: Raios.m,
        side: BorderSide(color: c.linha),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.primaria,
        foregroundColor: c.sobrePrimaria,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: Raios.m),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.tinta,
        minimumSize: const Size(0, 48),
        side: BorderSide(color: c.linha),
        shape: RoundedRectangleBorder(borderRadius: Raios.m),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.superficie,
      border: OutlineInputBorder(
        borderRadius: Raios.m,
        borderSide: BorderSide(color: c.linha),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: Raios.m,
        borderSide: BorderSide(color: c.linha),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: Raios.m,
        borderSide: BorderSide(color: c.primaria, width: 2),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.superficie,
      indicatorColor: c.superficieAlta,
      elevation: 0,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: c.superficie,
      indicatorColor: c.superficieAlta,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.fundo,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Raios.g.topLeft),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.tinta,
      contentTextStyle: texto.bodyMedium?.copyWith(color: c.fundo),
      actionTextColor: c.calor,
      shape: RoundedRectangleBorder(borderRadius: Raios.m),
    ),
  );
}
