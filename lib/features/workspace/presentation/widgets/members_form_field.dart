import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/user/presentation/widgets/user_avatar.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/core/widgets/error_view.dart';
import 'package:funances/core/presentation/retry.dart';

class MembersFormField extends ConsumerWidget {
  final List<String> initialValue;
  final ValueChanged<List<String>> onChanged;
  final String label;
  final String? errorText;

  const MembersFormField({
    super.key,
    required this.initialValue,
    required this.onChanged,
    required this.label,
    this.errorText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(WorkspaceViewProviders.members);
    final theme = Theme.of(context);
    final palette = context.palette;

    return membersAsync.when(
      data: (members) {
        return InputDecorator(
          decoration: InputDecoration(labelText: label, errorText: errorText),
          child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: members.map((member) {
              final isSelected = initialValue.contains(member.id);
              return FilterChip(
                avatar: UserAvatar(
                  displayName: member.displayName,
                  photoUrl: member.photoUrl,
                  radius: 12,
                ),
                label: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      member.displayName ?? member.email,
                      style: theme.textTheme.labelMedium,
                    ),
                    Text(
                      member.email,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: palette.ink2,
                      ),
                    ),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  final newList = List<String>.from(initialValue);
                  if (selected) {
                    newList.add(member.id);
                  } else {
                    newList.remove(member.id);
                  }
                  onChanged(newList);
                },
              );
            }).toList(),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) =>
          ErrorView.forError(context, err, onRetry: () => Retry.members(ref)),
    );
  }
}
