import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// As telas que se apresentam sozinhas na primeira visita.
///
/// São nomes, e não um enum, porque elas vêm de features diferentes — a
/// Arena e a vitrine de conquistas — e um enum num lugar só faria uma
/// depender da outra para dizer "eu também tenho uma aula".
abstract final class IntroKeys {
  static const String hudPotion = 'hud.potion';
  static const String hudVillage = 'hud.village';
  static const String hudEgg = 'hud.egg';
  static const String hudDrop = 'hud.drop';
  static const String badgesXpSources = 'badges.xpSources';

  /// Todas, para "rever as explicações".
  static const List<String> all = [
    hudPotion,
    hudVillage,
    hudEgg,
    hudDrop,
    badgesXpSources,
  ];
}

/// Quem já leu a explicação de cada tela.
///
/// A explicação de uma tela é uma aula: ela precisa aparecer sozinha na
/// PRIMEIRA vez — senão ninguém descobre o que a poção é, nem o que rende XP
/// — e não pode aparecer na segunda, porque aí ela deixa de ser aula e vira
/// um obstáculo entre o toque e o conteúdo.
///
/// **Uma chave por TELA, e nenhuma por workspace.** As folhas do HUD são
/// quatro assuntos diferentes: quem leu o que a poção é continua sem saber o
/// que um aldeão é, e uma marca só faria a segunda folha engolir a própria
/// apresentação. Já o workspace não entra na chave de propósito: o que a
/// regra do jogo significa não muda entre a casa e a empresa — só o
/// vocabulário do texto financeiro muda —, e uma marca por workspace faria a
/// MESMA aula voltar a cada cofre novo. É memória sobre o que esta pessoa já
/// leu neste aparelho, como o tema e o placar da semana; por isso mora no
/// `SharedPreferences` e não no Firestore.
class IntroStore {
  IntroStore({Future<SharedPreferences>? prefs})
    : _prefs = prefs ?? SharedPreferences.getInstance();

  final Future<SharedPreferences> _prefs;

  static String keyFor(String intro) => 'intro_seen:$intro';

  /// `true` quando a apresentação desta tela já aconteceu.
  ///
  /// Preferência ilegível conta como JÁ VISTA, e esse é o lado seguro do
  /// erro: a apresentação é um extra, e um extra que volta a cada abertura
  /// porque o disco falhou é pior do que um extra perdido. É o contrário da
  /// escolha do nudge de gasto não planejado — lá o convite é a feature.
  Future<bool> wasSeen(String intro) async {
    try {
      return (await _prefs).getBool(keyFor(intro)) ?? false;
    } on Exception {
      return true;
    }
  }

  Future<void> markSeen(String intro) async {
    try {
      await (await _prefs).setBool(keyFor(intro), true);
    } on Exception {
      // Gravação falhou: a apresentação volta na próxima abertura da tela.
      // É melhor do que estourar por cima de algo já na tela.
    }
  }

  /// Esquece todas as marcas de uma vez.
  ///
  /// Existe para uma opção de "rever as explicações" nas configurações. A
  /// opção ainda NÃO foi pedida e por isso não existe; o método existe para
  /// que ela não precise inventar uma segunda forma de apagar as chaves — foi
  /// assim que este projeto chegou a ter catorze barras de progresso.
  Future<void> showAgain() async {
    try {
      final prefs = await _prefs;
      for (final intro in IntroKeys.all) {
        await prefs.remove(keyFor(intro));
      }
    } on Exception {
      // Idem: no pior caso a explicação continua guardada.
    }
  }
}

sealed class IntroProviders {
  /// Injetável para que o teste troque o disco por uma memória de mentira —
  /// e para que a tela não precise conhecer o `SharedPreferences`.
  static final store = Provider<IntroStore>((ref) => IntroStore());
}
