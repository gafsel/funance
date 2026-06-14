import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/user/presentation/widgets/user_avatar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/workspace/presentation/providers.dart';

class AccountLogo extends ConsumerWidget {
  final AccountModel account;
  final double size;
  final bool showMembers;
  final double memberAvatarSize;

  const AccountLogo({
    super.key,
    required this.account,
    this.size = 40,
    this.showMembers = false,
    this.memberAvatarSize = 18,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget logo;

    if (account.bankLogo != BankLogo.none) {
      logo = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(size * 0.2),
          border: Border.all(color: AppColors.softGrey, width: size * .05),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.2),
          child: Image.asset(
            'assets/logos/${account.bankLogo.name}.png',
            fit: BoxFit.fitWidth,
            errorBuilder: (context, error, stackTrace) => Icon(
              account.icon.asIcon(),
              color: account.color.asColor(),
              size: size * 0.6,
            ),
          ),
        ),
      );
    } else {
      logo = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(size * 0.2),
          border: Border.all(color: AppColors.softGrey, width: size * .05),
        ),
        child: Icon(
          account.icon.asIcon(),
          color: account.color.asColor(),
          size: size * 0.6,
        ),
      );
    }

    if (!showMembers || account.ownerIds.isEmpty) {
      return logo;
    }

    return SizedBox(
      width:
          size +
          (memberAvatarSize *
              0.6 *
              (account.ownerIds.length > 3 ? 3 : account.ownerIds.length)),
      height: size + (memberAvatarSize * 0.4),
      child: Stack(
        children: [
          logo,
          ...account.ownerIds.take(3).indexed.map((entry) {
            final index = entry.$1;
            final userId = entry.$2;
            final membersAsync = ref.watch(WorkspaceViewProviders.members);

            return Positioned(
              bottom: 0,
              right: index * (memberAvatarSize * 0.6),
              child: membersAsync.when(
                data: (members) {
                  final user = members.where((m) => m.id == userId).firstOrNull;
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: UserAvatar(
                      displayName: user?.displayName,
                      photoUrl: user?.photoUrl,
                      radius: memberAvatarSize / 2,
                    ),
                  );
                },
                loading: () =>
                    SizedBox(width: memberAvatarSize, height: memberAvatarSize),
                error: (_, __) =>
                    SizedBox(width: memberAvatarSize, height: memberAvatarSize),
              ),
            );
          }),
        ],
      ),
    );
  }
}
