import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';

extension ColorExtension on String {
  /// Converte "#RRGGBB", "#AARRGGBB" ou "0xAARRGGBB" em [Color].
  /// Valores inválidos (ex.: cor alucinada pela IA como "blue" ou "#FFF")
  /// retornam [orElse] em vez de lançar durante o build.
  Color asColor({Color orElse = AppColors.deepTurquoise}) {
    final raw = trim().replaceAll('#', '').replaceAll('0x', '');
    final hex = raw.length == 6 ? 'FF$raw' : raw;
    if (hex.length != 8) return orElse;
    final value = int.tryParse(hex, radix: 16);
    return value != null ? Color(value) : orElse;
  }
}
