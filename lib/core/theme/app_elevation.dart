import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Elevação: três degraus e um brilho.
///
/// O app usava três mecanismos concorrentes para a mesma ideia (`elevation:`,
/// `boxShadow` manual e nada). Aqui existe um só, e ele é explícito sobre o
/// que cada degrau significa.
abstract final class AppElevation {
  /// Plano: sem sombra. A separação vem de uma borda de 1px.
  static const List<BoxShadow> flat = <BoxShadow>[];

  /// Cartão pousado sobre o fundo.
  static List<BoxShadow> raised(Brightness brightness) =>
      brightness == Brightness.dark ? _raisedDark : _raisedLight;

  /// Camada sobreposta: folha, diálogo, menu, toast.
  static List<BoxShadow> overlay(Brightness brightness) =>
      brightness == Brightness.dark ? _overlayDark : _overlayLight;

  /// Brilho de recompensa: halo dourado.
  ///
  /// É a **única sombra colorida do app** e está reservada a conquista —
  /// missão concluída, badge desbloqueada, subida de nível ou de patente. Se
  /// aparecer em qualquer outro lugar, a recompensa deixa de significar algo.
  static const List<BoxShadow> reward = <BoxShadow>[
    BoxShadow(color: Color(0x59F5C518), blurRadius: 0, spreadRadius: 2),
    BoxShadow(
      color: Color(0x47F5C518),
      blurRadius: 24,
      spreadRadius: 0,
      offset: Offset(0, 8),
    ),
  ];

  /// Borda de 1px que faz o papel da elevação plana.
  static BorderSide hairline(Color line) => BorderSide(color: line, width: 1);

  /// Aro dourado de recompensa, para quando o halo seria demais.
  static const BorderSide goldRim = BorderSide(color: AppColors.gold, width: 2);

  static const List<BoxShadow> _raisedLight = <BoxShadow>[
    BoxShadow(color: Color(0x140A2329), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0F0A2329), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> _overlayLight = <BoxShadow>[
    BoxShadow(color: Color(0x1F0A2329), blurRadius: 4, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x1A0A2329), blurRadius: 28, offset: Offset(0, 12)),
  ];

  static const List<BoxShadow> _raisedDark = <BoxShadow>[
    BoxShadow(color: Color(0x59000000), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x4D000000), blurRadius: 16, offset: Offset(0, 6)),
  ];

  static const List<BoxShadow> _overlayDark = <BoxShadow>[
    BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3)),
    BoxShadow(color: Color(0x59000000), blurRadius: 32, offset: Offset(0, 14)),
  ];
}
