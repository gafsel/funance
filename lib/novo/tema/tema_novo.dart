import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tokens da identidade do Funances 2. Este é o único arquivo do app novo
/// que pode escrever uma cor, um raio ou um estilo de texto cru.
///
/// Regras da identidade: petróleo é a tinta, amarelo é calor (só para o
/// passo do caminho e o que merece atenção boa), despesa NÃO é vermelha.
/// Vermelho fica reservado para problema de verdade.
class Cores {
  const Cores({
    required this.fundo,
    required this.superficie,
    required this.suave,
    required this.tinta,
    required this.tinta2,
    required this.tinta3,
    required this.linha,
    required this.primaria,
    required this.sobrePrimaria,
    required this.primariaSuave,
    required this.calor,
    required this.sobreCalor,
    required this.calorSuave,
    required this.positivo,
    required this.positivoSuave,
    required this.atencao,
    required this.atencaoSuave,
    required this.problema,
    required this.problemaSuave,
  });

  final Color fundo;

  /// Papel: cartões, barras, campos.
  final Color superficie;

  /// Fundo de segmentos, trilhos de barra, etiquetas neutras.
  final Color suave;
  final Color tinta;
  final Color tinta2;
  final Color tinta3;
  final Color linha;
  final Color primaria;
  final Color sobrePrimaria;
  final Color primariaSuave;
  final Color calor;
  final Color sobreCalor;
  final Color calorSuave;
  final Color positivo;
  final Color positivoSuave;
  final Color atencao;
  final Color atencaoSuave;
  final Color problema;
  final Color problemaSuave;

  // Nomes antigos, mantidos para as telas que ainda os usam.
  Color get superficieAlta => suave;
  Color get tintaSuave => tinta3;

  static const claro = Cores(
    fundo: Color(0xFFF6F8F7),
    superficie: Color(0xFFFFFFFF),
    suave: Color(0xFFEEF3F2),
    tinta: Color(0xFF0E3440),
    tinta2: Color(0xFF47636B),
    tinta3: Color(0xFF6E878D),
    linha: Color(0xFFDCE5E6),
    primaria: Color(0xFF0F7C82),
    sobrePrimaria: Color(0xFFFFFFFF),
    primariaSuave: Color(0xFFE1F1F1),
    calor: Color(0xFFFFC233),
    sobreCalor: Color(0xFF3A2E00),
    calorSuave: Color(0xFFFFF4D6),
    positivo: Color(0xFF23804A),
    positivoSuave: Color(0xFFE2F3E8),
    atencao: Color(0xFF9A5A08),
    atencaoSuave: Color(0xFFFCEFD9),
    problema: Color(0xFFC23A3A),
    problemaSuave: Color(0xFFFBE5E5),
  );

  static const escuro = Cores(
    fundo: Color(0xFF0B2A34),
    superficie: Color(0xFF12414F),
    suave: Color(0xFF0F3642),
    tinta: Color(0xFFF3F8F8),
    tinta2: Color(0xFFB7CDD3),
    tinta3: Color(0xFF93AEB5),
    linha: Color(0xFF24525F),
    primaria: Color(0xFF3CC7C4),
    sobrePrimaria: Color(0xFF06262B),
    primariaSuave: Color(0xFF17505C),
    calor: Color(0xFFFFC233),
    sobreCalor: Color(0xFF3A2E00),
    calorSuave: Color(0xFF4A3F17),
    positivo: Color(0xFF5FD58A),
    positivoSuave: Color(0xFF17402B),
    atencao: Color(0xFFF2B25C),
    atencaoSuave: Color(0xFF4A3413),
    problema: Color(0xFFFF9C9C),
    problemaSuave: Color(0xFF4D2023),
  );

  static Cores de(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? escuro : claro;
}

abstract final class Raios {
  static final p = BorderRadius.circular(8);
  static final m = BorderRadius.circular(10);
  static final g = BorderRadius.circular(12);
  static final folha = BorderRadius.circular(18);
  static final pilula = BorderRadius.circular(999);
}

abstract final class Espacos {
  static const double xp = 4;
  static const double p = 8;
  static const double m = 12;
  static const double g = 14;
  static const double xg = 20;
  static const double xxg = 28;
}

/// Largura a partir da qual o app usa o desenho de mesa (menu ao lado,
/// duas colunas, grade).
const double larguraDeMesa = 860;

bool ehMesa(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= larguraDeMesa;

/// Tela larga o bastante para uma terceira coluna de conteúdo.
bool ehTelaLarga(BuildContext context) => MediaQuery.sizeOf(context).width >= 1360;

/// Margem lateral do conteúdo: 14 no celular, 24 na mesa.
double margemDaTela(BuildContext context) => ehMesa(context) ? 24 : Espacos.g;

/// Estilos de texto que não cabem no `TextTheme`.
abstract final class Textos {
  /// Rótulo pequeno em maiúsculas ("SEU PRÓXIMO PASSO").
  static TextStyle sobrancelha(BuildContext context) => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.9,
        color: Cores.de(context).tinta3,
      );

  /// O número grande do Início.
  static TextStyle numerao(BuildContext context, {double tamanho = 42}) => GoogleFonts.figtree(
        fontSize: tamanho,
        fontWeight: FontWeight.w800,
        height: 1.05,
        letterSpacing: -0.8,
        color: Cores.de(context).tinta,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Valor em dinheiro numa linha: algarismos alinhados.
  static TextStyle valor(BuildContext context, {double tamanho = 14, Color? cor}) => GoogleFonts.inter(
        fontSize: tamanho,
        fontWeight: FontWeight.w600,
        color: cor ?? Cores.de(context).tinta,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle marca(BuildContext context, {double tamanho = 17}) => GoogleFonts.figtree(
        fontSize: tamanho,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        color: Cores.de(context).tinta,
      );
}

ThemeData temaNovo(Brightness brilho) {
  final c = brilho == Brightness.dark ? Cores.escuro : Cores.claro;
  final base = ThemeData(brightness: brilho, useMaterial3: true);
  final corpo = GoogleFonts.interTextTheme(base.textTheme).apply(bodyColor: c.tinta, displayColor: c.tinta);
  TextStyle titulo(double tamanho, {FontWeight peso = FontWeight.w700}) => GoogleFonts.figtree(
        fontSize: tamanho,
        fontWeight: peso,
        height: 1.2,
        letterSpacing: -0.2,
        color: c.tinta,
      );
  final botao = GoogleFonts.figtree(fontSize: 15, fontWeight: FontWeight.w700);
  const preenchimentoDoBotao = EdgeInsets.symmetric(horizontal: 16, vertical: 10);
  final formaDoBotao = RoundedRectangleBorder(borderRadius: Raios.m);

  OutlineInputBorder borda(Color cor, [double largura = 1]) =>
      OutlineInputBorder(borderRadius: Raios.m, borderSide: BorderSide(color: cor, width: largura));

  return base.copyWith(
    scaffoldBackgroundColor: c.fundo,
    visualDensity: VisualDensity.standard,
    colorScheme: ColorScheme.fromSeed(seedColor: c.primaria, brightness: brilho).copyWith(
      primary: c.primaria,
      onPrimary: c.sobrePrimaria,
      secondary: c.primaria,
      onSecondary: c.sobrePrimaria,
      secondaryContainer: c.primariaSuave,
      onSecondaryContainer: c.tinta,
      surface: c.superficie,
      onSurface: c.tinta,
      onSurfaceVariant: c.tinta2,
      surfaceContainerHighest: c.suave,
      surfaceContainerHigh: c.superficie,
      surfaceContainer: c.superficie,
      surfaceContainerLow: c.superficie,
      error: c.problema,
      outline: c.linha,
      outlineVariant: c.linha,
    ),
    textTheme: corpo.copyWith(
      displaySmall: titulo(40, peso: FontWeight.w800),
      headlineMedium: titulo(26, peso: FontWeight.w800),
      titleLarge: titulo(20),
      titleMedium: titulo(15),
      titleSmall: titulo(14),
      bodyLarge: corpo.bodyLarge?.copyWith(fontSize: 15, height: 1.45),
      bodyMedium: corpo.bodyMedium?.copyWith(fontSize: 14, height: 1.45),
      bodySmall: corpo.bodySmall?.copyWith(fontSize: 12, height: 1.4, color: c.tinta3),
      labelLarge: corpo.labelLarge?.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
      labelMedium: corpo.labelMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
    ),
    dividerTheme: DividerThemeData(color: c.linha, thickness: 1, space: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: c.superficie,
      surfaceTintColor: c.superficie,
      foregroundColor: c.tinta,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 52,
      titleTextStyle: titulo(17),
      shape: Border(bottom: BorderSide(color: c.linha)),
    ),
    cardTheme: CardThemeData(
      color: c.superficie,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: Raios.g, side: BorderSide(color: c.linha)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.primaria,
        foregroundColor: c.sobrePrimaria,
        disabledBackgroundColor: c.primaria.withValues(alpha: 0.4),
        disabledForegroundColor: c.sobrePrimaria.withValues(alpha: 0.8),
        minimumSize: const Size(0, 42),
        padding: preenchimentoDoBotao,
        textStyle: botao,
        shape: formaDoBotao,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.tinta,
        minimumSize: const Size(0, 42),
        padding: preenchimentoDoBotao,
        textStyle: botao,
        side: BorderSide(color: c.linha),
        shape: formaDoBotao,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.primaria,
        minimumSize: const Size(0, 34),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        shape: formaDoBotao,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: c.tinta2)),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.superficie,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      hintStyle: corpo.bodyMedium?.copyWith(color: c.tinta3, fontSize: 14),
      labelStyle: corpo.bodyMedium?.copyWith(color: c.tinta2, fontSize: 14),
      helperStyle: corpo.bodySmall?.copyWith(color: c.tinta3, fontSize: 12),
      border: borda(c.linha),
      enabledBorder: borda(c.linha),
      disabledBorder: borda(c.linha),
      focusedBorder: borda(c.primaria, 1.5),
    ),
    listTileTheme: ListTileThemeData(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      minVerticalPadding: 8,
      titleTextStyle: corpo.bodyMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: c.tinta),
      subtitleTextStyle: corpo.bodySmall?.copyWith(fontSize: 12, color: c.tinta3),
      iconColor: c.tinta2,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.sobrePrimaria : c.tinta3),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.primaria : c.suave),
      trackOutlineColor: WidgetStateProperty.all(c.linha),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primaria, linearTrackColor: c.suave),
    dialogTheme: DialogThemeData(
      backgroundColor: c.fundo,
      surfaceTintColor: c.fundo,
      shape: RoundedRectangleBorder(borderRadius: Raios.folha),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.fundo,
      surfaceTintColor: c.fundo,
      dragHandleColor: c.linha,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Raios.folha.topLeft)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.tinta,
      contentTextStyle: corpo.bodyMedium?.copyWith(color: c.fundo, fontSize: 13.5),
      actionTextColor: c.calor,
      shape: RoundedRectangleBorder(borderRadius: Raios.g),
      insetPadding: const EdgeInsets.all(12),
    ),
    datePickerTheme: DatePickerThemeData(backgroundColor: c.fundo, surfaceTintColor: c.fundo),
  );
}

/// Cor a partir de `#RRGGBB` (como as categorias e contas guardam). `null`
/// para texto que não é uma cor.
Color? corDeHex(String? hex) {
  if (hex == null) return null;
  final limpo = hex.replaceFirst('#', '');
  if (limpo.length != 6) return null;
  final valor = int.tryParse(limpo, radix: 16);
  return valor == null ? null : Color(0xFF000000 | valor);
}

/// Cores oferecidas na escolha de cor de uma categoria. São as mesmas que
/// os gráficos usam, então a categoria tem sempre a mesma cor em todo lugar.
const paletaDeCategorias = [
  '#EF5350', '#EC407A', '#AB47BC', '#7E57C2', '#5C6BC0', '#42A5F5',
  '#29B6F6', '#00BCD4', '#26A69A', '#23804A', '#9CCC65', '#FFB300',
  '#FF9800', '#FF7043', '#8D6E63', '#78909C',
];

/// Cor de uma categoria sem cor definida: estável para o mesmo id.
Color corPadraoDaCategoria(String id) {
  var soma = 0;
  for (final u in id.codeUnits) {
    soma = (soma * 31 + u) & 0xFFFF;
  }
  return corDeHex(paletaDeCategorias[soma % paletaDeCategorias.length])!;
}

/// Texto legível sobre uma cor de fundo qualquer.
Color sobreCor(Color fundo) => fundo.computeLuminance() > 0.55 ? const Color(0xFF0E3440) : const Color(0xFFFFFFFF);

/// As quatro cores da marca do Google, para o botão de entrar.
abstract final class CoresDoGoogle {
  static const azul = Color(0xFF4285F4);
  static const vermelho = Color(0xFFEA4335);
  static const amarelo = Color(0xFFFBBC05);
  static const verde = Color(0xFF34A853);
}
