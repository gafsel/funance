import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/widgets/app_scaffold.dart';
import 'package:funances/core/widgets/empty_state.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/features/user/domain/models/user_model.dart';
import 'package:funances/features/user/presentation/widgets/user_avatar.dart';
import 'package:funances/features/workspace/domain/models/invite_model.dart';
import 'package:funances/features/workspace/presentation/controller/workspace_members_notifier.dart';
import 'package:funances/features/workspace/presentation/model/workspace_members_view_models.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/core/widgets/section_header.dart';

/// Quem participa do workspace e quem ainda não respondeu ao convite.
///
/// Só o dono (o criador, `members[0]`) remove alguém, e nunca a si mesmo: ele
/// é a âncora de permissão do workspace no servidor e nas rules.
class WorkspaceMembersScreen extends ConsumerWidget {
  const WorkspaceMembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final workspaceId = ref.watch(WorkspaceViewProviders.currentWorkspaceId);

    if (workspaceId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.membersTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final provider = WorkspaceViewProviders.membersManagement;
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.membersTitle)),
      // A largura máxima vem do breakpoint, não de um 700 escrito à mão.
      body: AppContentWidth(
        gutter: 0,
        child: RefreshIndicator(
          onRefresh: notifier.loadMembers,
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            children: [
              SectionHeader.label(l10n.membersSectionActive),
              ..._buildMembers(context, state, notifier),
              const Divider(height: AppSpacing.xl),
              SectionHeader.label(l10n.membersSectionPending),
              ..._buildInvites(context, state, notifier),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMembers(
    BuildContext context,
    WorkspaceMembersState state,
    WorkspaceMembersNotifier notifier,
  ) {
    final l10n = context.l10n;

    if (state.isLoading) {
      return const [
        Padding(
          padding: AppSpacing.allXl,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (state.errorLoading) {
      return [
        _ErrorRow(
          message: l10n.membersLoadError,
          actionLabel: l10n.membersRetry,
          onRetry: notifier.loadMembers,
        ),
      ];
    }

    return state.members
        .map(
          (member) => _MemberTile(
            member: member,
            isOwner: member.id == notifier.ownerId,
            isCurrentUser: member.id == notifier.currentUserId,
            // Remover é do dono, e ninguém remove a si mesmo.
            canRemove:
                notifier.isOwner && member.id != notifier.currentUserId,
            isBusy: state.busyMemberId == member.id,
            onRemove: () => _confirmRemove(context, notifier, member),
          ),
        )
        .toList();
  }

  List<Widget> _buildInvites(
    BuildContext context,
    WorkspaceMembersState state,
    WorkspaceMembersNotifier notifier,
  ) {
    final l10n = context.l10n;

    if (state.errorInvites) {
      return [
        _ErrorRow(
          message: l10n.membersInvitesLoadError,
          actionLabel: l10n.membersRetry,
          onRetry: notifier.loadMembers,
        ),
      ];
    }

    if (!state.invitesLoaded) {
      return const [
        Padding(
          padding: AppSpacing.allXl,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (state.pendingInvites.isEmpty) {
      return [
        EmptyState.message(
          l10n.membersEmptyPending,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.lg,
          ),
        ),
      ];
    }

    return state.pendingInvites
        .map(
          (invite) => _InviteTile(
            invite: invite,
            isBusy: state.busyInviteId == invite.id,
            onResend: () async {
              final error = await notifier.resendInvite(invite);
              if (!context.mounted) return;
              _toast(context, error ?? l10n.membersResendSuccess);
            },
            onCancel: () => _confirmCancel(context, notifier, invite),
          ),
        )
        .toList();
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WorkspaceMembersNotifier notifier,
    UserModel member,
  ) async {
    final l10n = context.l10n;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n.membersRemoveTitle(member.displayName ?? member.email),
        ),
        content: Text(l10n.membersRemoveConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.membersRemoveAction,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final error = await notifier.removeMember(member);
    if (!context.mounted) return;

    _toast(context, error ?? l10n.membersRemoveSuccess);
  }

  Future<void> _confirmCancel(
    BuildContext context,
    WorkspaceMembersNotifier notifier,
    InviteModel invite,
  ) async {
    final l10n = context.l10n;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.membersCancelInviteTitle(invite.receiverEmail)),
        content: Text(l10n.membersCancelInviteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.membersCancelInviteAction,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final error = await notifier.cancelInvite(invite);
    if (!context.mounted) return;

    _toast(context, error ?? l10n.membersCancelInviteSuccess);
  }

  static void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({
    required this.message,
    required this.actionLabel,
    required this.onRetry,
  });

  final String message;
  final String actionLabel;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.lg,
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
          AppSpacing.gapXs,
          TextButton(onPressed: onRetry, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.isOwner,
    required this.isCurrentUser,
    required this.canRemove,
    required this.isBusy,
    required this.onRemove,
  });

  final UserModel member;
  final bool isOwner;
  final bool isCurrentUser;
  final bool canRemove;
  final bool isBusy;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final role = isOwner ? l10n.membersOwnerRole : l10n.membersMemberRole;
    final subtitle = isCurrentUser ? '$role · ${l10n.membersYou}' : role;

    return ListTile(
      leading: UserAvatar(
        displayName: member.displayName,
        photoUrl: member.photoUrl,
        radius: 20,
      ),
      title: Text(member.displayName ?? member.email),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(member.email, style: theme.textTheme.bodySmall),
          Text(
            subtitle,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
      isThreeLine: true,
      trailing: !canRemove
          ? null
          : isBusy
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : IconButton(
              tooltip: l10n.membersRemoveAction,
              icon: const Icon(
                Icons.person_remove_outlined,
                color: AppColors.danger,
              ),
              onPressed: onRemove,
            ),
    );
  }
}

class _InviteTile extends StatelessWidget {
  const _InviteTile({
    required this.invite,
    required this.isBusy,
    required this.onResend,
    required this.onCancel,
  });

  final InviteModel invite;
  final bool isBusy;
  final VoidCallback onResend;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.mail_outline)),
      title: Text(invite.receiverEmail),
      subtitle: Text(
        l10n.membersInviteSentAt(
          invite.createdAt.formated(l10n.formatSimpleDate),
        ),
        style: theme.textTheme.bodySmall,
      ),
      trailing: isBusy
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: l10n.membersResendAction,
                  icon: const Icon(Icons.refresh),
                  onPressed: onResend,
                ),
                IconButton(
                  tooltip: l10n.membersCancelInviteAction,
                  icon: const Icon(Icons.close, color: AppColors.danger),
                  onPressed: onCancel,
                ),
              ],
            ),
    );
  }
}
