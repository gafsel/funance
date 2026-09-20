import 'package:flutter/material.dart';
import 'package:funances/core/form/loading_button.dart';
import 'package:funances/features/onboarding/presentation/provider.dart';
import 'package:funances/features/user/presentation/widgets/avatar_picker.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:funances/features/workspace/domain/models/workspace_model.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkspaceInfoStep extends ConsumerWidget {
  const WorkspaceInfoStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(
      OnboardingViewProviders.onboarding.select((s) => s.workspace),
    );
    final avatar = ref.watch(
      OnboardingViewProviders.onboarding.select((s) => s.avatar),
    );
    final notifier = ref.read(OnboardingViewProviders.onboarding.notifier);
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: AppSpacing.allXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IconButton(
            alignment: Alignment.centerLeft,
            icon: Icon(Icons.arrow_back, color: context.palette.ink),
            onPressed: () {
              notifier.previousStep();
            },
          ),
          AppSpacing.gapXl,
          // O passo ganhou o seletor de avatar e deixou de caber numa coluna
          // rígida: com `Spacer` ele estourava a tela baixa (544 px de altura
          // é a régua dos goldens). O que rola é só o miolo — o botão de
          // continuar fica ancorado embaixo, onde o dedo já o procura.
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.onboardingWorkspaceNameTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  AppSpacing.gapXs,
                  Text(
                    workspace.type == WorkspaceType.personal
                        ? l10n.onboardingWorkspaceNamePersonalHint
                        : l10n.onboardingWorkspaceNameBusinessHint,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  AppSpacing.gapXl,
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: l10n.onboardingWorkspaceNameLabel,
                    ),
                    onChanged: (value) => notifier.setWorkspaceName(value),
                  ),
                  AppSpacing.gapXl,
                  Text(
                    l10n.profileAvatarLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  AppSpacing.gapXxs,
                  Text(
                    l10n.profileAvatarHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.palette.ink2,
                    ),
                  ),
                  AppSpacing.gapSm,
                  // Alinhado à ESQUERDA porque a coluna é `stretch`: sem isto
                  // o `Wrap` recebe largura infinita de restrição cruzada e
                  // centraliza os tiles de um jeito que muda com o número de
                  // bonecos por linha.
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AvatarPicker(
                      selected: avatar,
                      onSelected: notifier.setAvatar,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.gapMd,
          LoadingButton.elevated(
            onPressed: workspace.name.isEmpty
                ? null
                : (loading) async {
                    await loading(notifier.nextStep());
                  },
            child: Text(l10n.continueButton.toUpperCase()),
          ),
        ],
      ),
    );
  }
}
