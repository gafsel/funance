import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'celebration_event.dart';

/// A fila de conquistas a mostrar.
///
/// Existe porque o canal de celebração do app era o mesmo do erro — `SnackBar`
/// para badge, nada para missão concluída, nada para subida de patente — e
/// porque **todo** o feedback nascia de um único `ref.listen` dentro da
/// `HomeScreen`: ganhar XP dentro da Conciliação, do 50-30-20 ou do formulário
/// de transação não rendia toast nenhum, porque a Home não estava montada.
///
/// Agora o serviço vive acima do `Navigator` e a fila é do app inteiro.
///
/// Duas garantias:
///
/// * **Idempotência.** Cada evento tem uma chave e uma chave só é celebrada
///   uma vez por sessão. O Firestore reemite documentos a cada escrita; sem
///   isso, mexer numa missão faria a badge de ontem piscar de novo.
/// * **Teto.** No máximo [maxVisible] na tela. Subir de nível costuma vir
///   acompanhado de XP e de uma badge; três toasts é uma pilha, seis é um
///   bloqueio.
class CelebrationService extends StateNotifier<List<CelebrationEvent>> {
  CelebrationService() : super(const []);

  static const int maxVisible = 3;

  final Set<String> _seen = <String>{};

  /// Enfileira uma conquista. Devolve `false` quando ela já foi celebrada.
  bool celebrate(CelebrationEvent event) {
    if (!_seen.add(event.key)) return false;

    final next = [...state, event];
    state = next.length > maxVisible
        ? next.sublist(next.length - maxVisible)
        : next;
    return true;
  }

  /// Enfileira uma RAJADA, da menor para a maior importância, e devolve o
  /// que de fato entrou.
  ///
  /// Este é o único lugar que ordena uma rajada. O host tinha uma segunda
  /// cópia da regra, e duas cópias de uma regra de ordenação é uma que está
  /// errada: era a do host, que enfileirava na ordem em que os eventos foram
  /// descobertos e fazia o teto descartar justamente a maior conquista.
  ///
  /// A ordem importa duas vezes. A fila tem teto e descarta PELA FRENTE, então
  /// quem entra primeiro é quem cai fora primeiro — e o que deve cair fora é o
  /// XP, nunca a subida de nível. E a pilha na tela é desenhada a partir desta
  /// ordem.
  ///
  /// O desempate é o índice de CHEGADA. `List.sort` não é estável em Dart:
  /// duas badges desbloqueadas na mesma rajada podiam trocar de lugar entre
  /// duas execuções, e a fila (que é idempotente por chave) guardaria uma
  /// ordem diferente a cada vez.
  List<CelebrationEvent> celebrateAll(Iterable<CelebrationEvent> events) {
    final indexed = events.toList().indexed.toList()
      ..sort((a, b) {
        final byStrength = a.$2.kind.index.compareTo(b.$2.kind.index);
        return byStrength != 0 ? byStrength : a.$1.compareTo(b.$1);
      });

    return [
      for (final (_, event) in indexed)
        if (celebrate(event)) event,
    ];
  }

  void dismiss(String key) {
    state = state.where((e) => e.key != key).toList(growable: false);
  }

  void dismissAll() => state = const [];

  /// Esquece o que já foi celebrado.
  ///
  /// Chamado na troca de workspace: as chaves são por cofre, e o nível 7 da
  /// casa não é o nível 7 da empresa.
  void reset() {
    _seen.clear();
    state = const [];
  }

  @visibleForTesting
  bool hasSeen(String key) => _seen.contains(key);
}

/// Preferências de feedback.
///
/// O som nasce **desligado**: o app é usado em transporte público e em
/// reunião, e um som de moeda a cada toque é exatamente o que a direção de
/// produto listou como "infantiliza". Quem quiser, liga nas configurações.
class CelebrationSettings {
  const CelebrationSettings({this.sound = false, this.haptics = true});

  final bool sound;
  final bool haptics;

  CelebrationSettings copyWith({bool? sound, bool? haptics}) =>
      CelebrationSettings(
        sound: sound ?? this.sound,
        haptics: haptics ?? this.haptics,
      );
}

class CelebrationSettingsNotifier extends StateNotifier<CelebrationSettings> {
  CelebrationSettingsNotifier({Future<SharedPreferences>? prefs})
    : _prefs = prefs ?? SharedPreferences.getInstance(),
      super(const CelebrationSettings()) {
    _restore();
  }

  static const String soundKey = 'celebration_sound';
  static const String hapticsKey = 'celebration_haptics';

  final Future<SharedPreferences> _prefs;

  Future<void> _restore() async {
    try {
      final prefs = await _prefs;
      if (!mounted) return;
      state = CelebrationSettings(
        sound: prefs.getBool(soundKey) ?? false,
        haptics: prefs.getBool(hapticsKey) ?? true,
      );
    } on Exception {
      // Preferência ilegível fica no padrão.
    }
  }

  Future<void> setSound(bool value) async {
    state = state.copyWith(sound: value);
    await _write(soundKey, value);
  }

  Future<void> setHaptics(bool value) async {
    state = state.copyWith(haptics: value);
    await _write(hapticsKey, value);
  }

  Future<void> _write(String key, bool value) async {
    try {
      final prefs = await _prefs;
      await prefs.setBool(key, value);
    } on Exception {
      // Vale na sessão, só não sobrevive ao fechamento.
    }
  }
}

/// Toca o retorno físico de uma conquista, dentro das preferências.
///
/// A háptica não é enfeite: é o único canal que funciona com o telefone no
/// bolso e com a tela lida por um leitor. O som só sai se alguém o ligou.
Future<void> playCelebrationFeedback(
  CelebrationEvent event,
  CelebrationSettings settings,
) async {
  if (settings.haptics) {
    if (event.kind.isMajor) {
      await HapticFeedback.heavyImpact();
    } else {
      await HapticFeedback.mediumImpact();
    }
  }
  if (settings.sound) {
    // Som do sistema, de propósito: o app não embarca pacote de áudio nem
    // asset de som nesta etapa. Trocar isto por um toque próprio é decisão de
    // produto, não de tema.
    await SystemSound.play(SystemSoundType.alert);
  }
}

sealed class CelebrationProviders {
  /// A fila do app inteiro. Não é `autoDispose`: ela precisa sobreviver à
  /// troca de tela, que é justamente o que faltava antes.
  static final queue =
      StateNotifierProvider<CelebrationService, List<CelebrationEvent>>(
        (ref) => CelebrationService(),
      );

  static final settings =
      StateNotifierProvider<CelebrationSettingsNotifier, CelebrationSettings>(
        (ref) => CelebrationSettingsNotifier(),
      );
}
