import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/workspace/presentation/controller/invite_providers.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/invite_model.dart';

class InviteListScreen extends ConsumerWidget {
  const InviteListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        // O herói é escuro nos dois temas: em vez de pintar cada texto de
        // branco, o bloco inteiro passa a ler o tema de jogo.
        child: Theme(
          data: AppTheme.onGame(context),
          child: const SafeArea(child: _InviteListBody()),
        ),
      ),
    );
  }
}

class _InviteListBody extends ConsumerWidget {
  const _InviteListBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.palette;
    final inviteState = ref.watch(inviteNotifierProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.invitesTitle, style: theme.textTheme.headlineMedium),
          AppSpacing.gapXs,
          Text(
            l10n.invitesSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(color: palette.ink2),
          ),
          AppSpacing.gapXl,
          Expanded(
            child: ListView.separated(
              itemCount: inviteState.pendingInvites.length,
              separatorBuilder: (context, index) => AppSpacing.gapMd,
              itemBuilder: (context, index) {
                final invite = inviteState.pendingInvites[index];
                return _InviteCard(invite: invite);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteCard extends ConsumerWidget {
  final InviteModel invite;
  const _InviteCard({required this.invite});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.palette;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.tealInk,
                child: Icon(Icons.business, color: AppColors.inkInverse),
              ),
              AppSpacing.gapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invite.workspace.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.gold,
                      ),
                    ),
                    Text(
                      l10n.inviteFrom(invite.senderName),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.ink2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.gapLg,
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => ref
                      .read(inviteNotifierProvider.notifier)
                      .respond(invite.id, InviteStatus.declined),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.warning,
                    side: const BorderSide(color: AppColors.warning),
                  ),
                  child: Text(l10n.declineButton.toUpperCase()),
                ),
              ),
              AppSpacing.gapSm,
              Expanded(
                child: ElevatedButton(
                  onPressed: () => ref
                      .read(inviteNotifierProvider.notifier)
                      .respond(invite.id, InviteStatus.accepted),
                  child: Text(l10n.acceptButton.toUpperCase()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
