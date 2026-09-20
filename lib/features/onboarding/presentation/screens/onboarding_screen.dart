import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/onboarding/presentation/provider.dart';
import 'package:funances/features/workspace/domain/models/workspace_model.dart';
import 'package:funances/features/workspace/presentation/providers.dart';

import '../../../../core/theme/app_durations.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../widgets/accounts_step.dart';
import '../widgets/goals_analysis_step.dart';
import '../widgets/members_step.dart';
import '../widgets/success_step.dart';
import '../widgets/welcome_step.dart';
import '../widgets/workspace_info_step.dart';

/// Ponto de entrada das rotas de onboarding. Prepara o estado do notifier
/// fora do `redirect` do GoRouter (que deve permanecer puro): carrega o
/// workspace corrente para retomar o onboarding, ou zera o fluxo quando o
/// usuário está criando um novo workspace.
class OnboardingEntry extends ConsumerStatefulWidget {
  final bool createNew;

  const OnboardingEntry({super.key, required this.createNew});

  @override
  ConsumerState<OnboardingEntry> createState() => _OnboardingEntryState();
}

class _OnboardingEntryState extends ConsumerState<OnboardingEntry> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final notifier = ref.read(OnboardingViewProviders.onboarding.notifier);
      if (widget.createNew) {
        notifier.startNew();
        return;
      }
      final workspace = ref
          .read(WorkspaceViewProviders.workspace)
          .currentWorkspace;
      if (workspace != null &&
          workspace.lastOnboardingStep != OnboardingSteps.done) {
        notifier.load(workspace);
      }
    });
  }

  @override
  Widget build(BuildContext context) => const OnboardingScreen();
}

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStep = ref.watch(
      OnboardingViewProviders.onboarding.select((s) => s.currentStep),
    );

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          // O onboarding inteiro é superfície de jogo: em vez de um tema
          // improvisado por tela, o bloco escuro declara isso uma vez e os
          // filhos leem a tinta certa sozinhos.
          child: Theme(
            data: AppTheme.onGame(context),
            child: AnimatedSwitcher(
              duration: AppDurations.normal,
              // Os seis passos têm a MESMA largura de leitura. Antes dois
              // deles se limitavam a 600 por conta própria e os outros
              // quatro não, então o wizard mudava de largura ao avançar.
              child: AppContentWidth.reading(
                gutter: 0,
                key: ValueKey(currentStep),
                child: _buildStep(context, currentStep),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, OnboardingSteps currentStep) {
    switch (currentStep) {
      case OnboardingSteps.type:
        return const WelcomeStep();
      case OnboardingSteps.name:
        return const WorkspaceInfoStep();
      case OnboardingSteps.accounts:
        return const AccountsStep();
      case OnboardingSteps.planning:
        return const GoalsAnalysisStep();
      case OnboardingSteps.invites:
        return const MembersStep();
      case OnboardingSteps.success:
        return const SuccessStep();
      default:
        return const WelcomeStep();
    }
  }
}
