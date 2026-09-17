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
class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

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
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.settingsThemeMode,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                l10n.settingsThemeModeDesc,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              AppSpacing.gapXs,
              SegmentedButton<ThemeMode>(
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
            ],
          ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.volume_up_outlined),
          title: Text(l10n.settingsCelebrationSound),
          subtitle: Text(l10n.settingsCelebrationSoundDesc),
          value: celebration.sound,
          onChanged: (value) =>
              ref.read(CelebrationProviders.settings.notifier).setSound(value),
        ),
      ],
    );
  }
}
