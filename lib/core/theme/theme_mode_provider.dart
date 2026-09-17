import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferência de tema do usuário.
///
/// O padrão é [ThemeMode.system] — o app segue o sistema até alguém dizer o
/// contrário, e só então guarda a escolha. A preferência é **do aparelho**, não
/// do workspace: quem usa o modo escuro à noite usa nos dois cofres.
///
/// A leitura do disco é assíncrona e o app não pode esperar por ela para
/// desenhar o primeiro quadro. Por isso o estado começa em `system` e é
/// corrigido assim que as preferências chegam: na prática, quem escolheu
/// "escuro" num sistema claro vê um quadro claro antes da troca. É barato e
/// não vale bloquear a inicialização.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier({Future<SharedPreferences>? prefs})
    : _prefs = prefs ?? SharedPreferences.getInstance(),
      super(ThemeMode.system) {
    _restore();
  }

  static const String storageKey = 'app_theme_mode';

  final Future<SharedPreferences> _prefs;

  Future<void> _restore() async {
    try {
      final prefs = await _prefs;
      final stored = prefs.getString(storageKey);
      final restored = decode(stored);
      if (!mounted || restored == state) return;
      state = restored;
    } on Exception {
      // Preferência ilegível não é motivo para o app não abrir: fica no
      // padrão do sistema.
    }
  }

  Future<void> select(ThemeMode mode) async {
    if (state == mode) return;
    state = mode;
    try {
      final prefs = await _prefs;
      await prefs.setString(storageKey, encode(mode));
    } on Exception {
      // Idem: a troca já valeu na sessão, só não sobreviveu ao fechamento.
    }
  }

  static String encode(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };

  static ThemeMode decode(String? raw) => switch (raw) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}

sealed class ThemeProviders {
  static final mode = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
    (ref) => ThemeModeNotifier(),
  );
}
