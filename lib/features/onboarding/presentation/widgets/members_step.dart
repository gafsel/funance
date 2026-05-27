import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:funances/features/workspace/domain/models/invite_model.dart';
import 'package:funances/features/workspace/presentation/providers/invite_providers.dart';
import 'package:funances/features/workspace/presentation/providers/workspace_providers.dart';
import 'package:funances/features/auth/presentation/providers/auth_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/onboarding_providers.dart';

class MembersStep extends ConsumerStatefulWidget {
  final OnboardingState state;
  final OnboardingNotifier notifier;
  const MembersStep({super.key, required this.state, required this.notifier});

  @override
  ConsumerState<MembersStep> createState() => _MembersStepState();
}

class _MembersStepState extends ConsumerState<MembersStep> {
  final TextEditingController _emailController = TextEditingController();
  final List<String> _invitedEmails = [];

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _addInvite() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) return;

    final user = ref.read(authStateProvider).value;
    final workspace = ref.read(workspaceNotifierProvider).currentWorkspace;

    if (user != null && workspace != null) {
      final invite = InviteModel(
        id: '', // Firestore gera o ID
        workspace: workspace,
        senderId: user.id,
        senderName: user.displayName ?? user.email,
        receiverEmail: email,
        status: InviteStatus.pending,
        createdAt: DateTime.now(),
      );

      await ref.read(inviteNotifierProvider.notifier).sendInvite(invite);
      
      setState(() {
        _invitedEmails.add(email);
        _emailController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.group_add_outlined, size: 64, color: AppColors.brightCyan),
          const SizedBox(height: 24),
          Text(
            l10n.onboardingMembersTitle,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingMembersDesc,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: l10n.emailLabel,
                    hintText: 'exemplo@email.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _addInvite,
                icon: const Icon(Icons.send, color: AppColors.paleGold),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.deepTurquoise.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _invitedEmails.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.mail_outline, color: AppColors.vibrantTeal),
                  title: Text(_invitedEmails[index]),
                  trailing: const Icon(Icons.check, color: AppColors.limeGreen),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // No OnboardingNotifier, poderíamos ter um método de finish, 
              // mas como o AuthWrapper reage ao estado dos providers, 
              // apenas forçar o refresh/navegação se necessário.
              // Neste caso, se o workspace foi criado e carregado, 
              // o AuthWrapper mudará automaticamente assim que sairmos da tela de onboarding.
              // Mas precisamos de um gatilho.
              ref.read(workspaceNotifierProvider.notifier).reset(); 
              // Reset e recarga forçará o AuthWrapper a reavaliar.
              final user = ref.read(authStateProvider).value;
              if (user != null) {
                ref.read(workspaceNotifierProvider.notifier).loadWorkspaces(user.id);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.limeGreen,
              foregroundColor: AppColors.deepTurquoise,
            ),
            child: Text(l10n.onboardingFinish),
          ),
        ],
      ),
    );
  }
}
