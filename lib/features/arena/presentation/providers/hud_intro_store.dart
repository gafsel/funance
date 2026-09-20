import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/arena/domain/models/hud_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Quem já leu a explicação de cada folha do HUD mensal.
///
/// A explicação de uma folha é uma aula: ela precisa aparecer sozinha na
/// PRIMEIRA vez — senão ninguém descobre o que a poção é — e não pode
/// aparecer na segunda, porque aí ela deixa de ser aula e vira um obstáculo
/// entre o toque e o número.
///
/// **Uma chave por SLOT, e nenhuma por workspace.** As quatro folhas são
/// quatro assuntos diferentes: quem leu o que a poção é continua sem saber o
/// que um aldeão é, e uma marca só faria a segunda folha aberta engolir a
/// própria apresentação. Já o workspace não entra na chave de propósito: o
/// que a regra do jogo significa não muda entre a casa e a empresa — só o
/// vocabulário do texto financeiro muda —, e uma marca por workspace faria a
/// MESMA aula voltar a cada cofre novo. É memória sobre o que esta pessoa já
/// leu neste aparelho, como o tema e o placar da semana; por isso mora no
/// `SharedPreferences` e não no Firestore.
class HudIntroStore {
  HudIntroStore({Future<SharedPreferences>? prefs})
    : _prefs = prefs ?? SharedPreferences.getInstance();

  final Future<SharedPreferences> _prefs;

  static String keyFor(HudSlot slot) => 'hud_intro_seen:${slot.name}';

  /// `true` quando a apresentação desta folha já aconteceu.
  ///
  /// Preferência ilegível conta como JÁ VISTA, e esse é o lado seguro do
  /// erro: a apresentação é um extra, e um extra que volta a cada abertura
  /// porque o disco falhou é pior do que um extra perdido. É o contrário da
  /// escolha do nudge de gasto não planejado — lá o convite é a feature.
  Future<bool> wasSeen(HudSlot slot) async {
    try {
      return (await _prefs).getBool(keyFor(slot)) ?? false;
    } on Exception {
      return true;
    }
  }

  Future<void> markSeen(HudSlot slot) async {
    try {
      await (await _prefs).setBool(keyFor(slot), true);
    } on Exception {
      // Gravação falhou: a apresentação volta na próxima abertura da folha.
      // É melhor do que estourar por cima de uma folha já na tela.
    }
  }

  /// Esquece as quatro marcas de uma vez.
  ///
  /// Existe para uma opção de "rever as explicações" nas configurações. A
  /// opção ainda NÃO foi pedida e por isso não existe; o método existe para
  /// que ela não precise inventar uma segunda forma de apagar as chaves — foi
  /// assim que este projeto chegou a ter catorze barras de progresso.
  Future<void> showAgain() async {
    try {
      final prefs = await _prefs;
      for (final slot in HudSlot.values) {
        await prefs.remove(keyFor(slot));
      }
    } on Exception {
      // Idem: no pior caso a explicação continua guardada.
    }
  }
}

sealed class HudIntroProviders {
  /// Injetável para que o teste troque o disco por uma memória de mentira —
  /// e para que a folha não precise conhecer o `SharedPreferences`.
  static final store = Provider<HudIntroStore>((ref) => HudIntroStore());
}
