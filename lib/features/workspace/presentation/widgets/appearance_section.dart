import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/celebration/celebration_service.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/theme/theme_mode_provider.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/widgets/section_header.dart';

/// Aparência: tema e retorno das conquistas.
///
/// O tema segue o sistema por padrão, e é isso que a maioria quer — o seletor
/// existe para quem quer o contrário. O som nasce desligado de propósito: o
/// app é usado em transporte público e em reunião.
///
/// **A seção vive no TOPO das configurações**, e não no fim. É o que o dono
/// pediu, e a razão é de uso: tema e som são as duas únicas configurações que
/// alguém troca por gosto e troca de novo depois — as outras (categorias,
/// contas, membros) são trabalho, e trabalho a gente procura. Um ajuste de
/// gosto enterrado embaixo de quatro seções é um ajuste que ninguém acha.
///
/// **E veste o mesmo tile do resto do menu.** Ela era um bloco solto: um
/// título em `titleMedium` sem ícone, uma descrição e um `SegmentedButton`
/// colados numa margem própria, ao lado de uma lista inteira de `ListTile`
/// com ícone à esquerda. O conteúdo é o mesmo; o que mudou é que agora ele se
/// lê como parte da mesma lista — ícone na mesma coluna, título na mesma
/// coluna, descrição na mesma tinta.
class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  /// Onde começa o TEXTO de um `ListTile` com ícone: 16 de margem, 40 de
  /// ícone e 16 de respiro.
  ///
  /// O seletor de tema é o único controle largo desta tela, e ele se alinha
  /// com o título do próprio item em vez de ocupar a largura inteira. É o que
  /// o amarra ao item: encostado na margem da tela, ele voltava a parecer um
  /// bloco à parte, que é exatamente o defeito que o dono apontou.
  static const double tileTextInset = 72;

  /// Largura máxima do seletor de tema.
  ///
  /// Sem teto, num desktop de 1300 px os três segmentos viravam três botões
  /// de quatrocentos pixels cada, atravessando a tela inteira para escolher
  /// entre "Sistema", "Claro" e "Escuro". Um controle com três opções curtas
  /// não fica mais legível por ser largo — fica mais difícil de mirar.
  static const double selectorMaxWidth = 420;

  /// Largura máxima de um item com CONTROLE à direita — hoje, o do som.
  ///
  /// Pelo mesmo motivo do teto do seletor, e com o mesmo número: num desktop
  /// de 1300 px o `SwitchListTile` atravessava a tela inteira e jogava a
  /// chavinha a mais de mil pixels do texto que ela liga, obrigando o olho a
  /// cruzar a tela vazia para ligar o som. O teto é o do seletor MAIS o
  /// recuo do texto, para os dois controles da seção terminarem na mesma
  /// coluna — dois tetos de 420 em recuos diferentes dariam duas bordas
  /// direitas desalinhadas em 72 px, que é justamente o "bloco solto" que
  /// este pacote veio desfazer.
  static const double controlMaxWidth = tileTextInset + selectorMaxWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final mode = ref.watch(ThemeProviders.mode);
    final celebration = ref.watch(CelebrationProviders.settings);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SectionHeader.label(l10n.settingsAppearanceSection),
        ListTile(
          leading: const Icon(Icons.brightness_6_outlined),
          title: Text(l10n.settingsThemeMode),
          subtitle: Text(l10n.settingsThemeModeDesc),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            tileTextInset,
            0,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: selectorMaxWidth),
              child: SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: const Icon(Icons.brightness_auto_outlined, size: 18),
                    label: Text(l10n.themeModeSystem),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: const Icon(Icons.light_mode_outlined, size: 18),
                    label: Text(l10n.themeModeLight),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: const Icon(Icons.dark_mode_outlined, size: 18),
                    label: Text(l10n.themeModeDark),
                  ),
                ],
                selected: {mode},
                showSelectedIcon: false,
                onSelectionChanged: (selection) {
                  final next = selection.firstOrNull;
                  if (next == null) return;
                  ref.read(ThemeProviders.mode.notifier).select(next);
                },
              ),
            ),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: controlMaxWidth),
            child: SwitchListTile(
              secondary: const Icon(Icons.volume_up_outlined),
              title: Text(l10n.settingsCelebrationSound),
              subtitle: Text(l10n.settingsCelebrationSoundDesc),
              value: celebration.sound,
              onChanged: (value) => ref
                  .read(CelebrationProviders.settings.notifier)
                  .setSound(value),
            ),
          ),
        ),
      ],
    );
  }
}
