import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static TextTheme get darkTextTheme {
    return const TextTheme(
      displayLarge: TextStyle(color: AppColors.pureWhite, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: AppColors.pureWhite, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: AppColors.pureWhite, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: AppColors.pureWhite, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(color: AppColors.pureWhite, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: AppColors.pureWhite),
      bodyMedium: TextStyle(color: AppColors.pureWhite),
      bodySmall: TextStyle(color: AppColors.pureWhite),
    );
  }

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.deepTurquoise,
        primary: AppColors.deepTurquoise,
        secondary: AppColors.vibrantTeal,
        tertiary: AppColors.successGold,
        surface: AppColors.pureWhite,
        error: AppColors.deepPurple,
        onPrimary: AppColors.pureWhite,
        onSecondary: AppColors.pureWhite,
        onTertiary: AppColors.deepTurquoise,
        onSurface: AppColors.deepTurquoise,
        onError: AppColors.pureWhite,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.pureWhite,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.deepTurquoise,
        foregroundColor: AppColors.pureWhite,
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.successGold,
          foregroundColor: AppColors.deepTurquoise,
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.pureWhite.withValues(alpha: 0.1),
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.brightCyan, width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.pureWhite.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.vibrantTeal),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.vibrantTeal),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.successGold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.coralOrange, width: 1),
        ),
        labelStyle: const TextStyle(color: AppColors.vibrantTeal),
        hintStyle: TextStyle(color: AppColors.deepTurquoise.withValues(alpha: 0.5)),
        prefixIconColor: AppColors.vibrantTeal,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppColors.deepTurquoise, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: AppColors.deepTurquoise, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: AppColors.deepTurquoise, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(color: AppColors.deepTurquoise, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: AppColors.deepTurquoise, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: AppColors.deepTurquoise),
        bodyMedium: TextStyle(color: AppColors.deepTurquoise),
        bodySmall: TextStyle(color: AppColors.deepTurquoise),
      ),
    );
  }
}
