import 'package:flutter/material.dart';
import 'package:funances/features/user/domain/models/user_model.dart';
import 'package:funances/features/user/presentation/widgets/user_avatar.dart';

/// Cabeçalho de um titular de contas.
///
/// A seleção agrupa por TITULAR antes de agrupar por banco: num workspace de
/// casal, "as contas do João" é a primeira pergunta que o olho faz — e o
/// usuário logado vem primeiro na lista.
class AccountOwnerHeader extends StatelessWidget {
  const AccountOwnerHeader({super.key, required this.title, this.member});

  final String title;

  /// `null` nas contas COMPARTILHADAS: elas não são de ninguém em particular,
  /// e o ícone de grupo diz isso no lugar do avatar.
  final UserModel? member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final member = this.member;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (member != null) ...[
                UserAvatar(
                  displayName: member.displayName,
                  photoUrl: member.photoUrl,
                  radius: 12,
                ),
                const SizedBox(width: 8),
              ] else ...[
                const Icon(Icons.people_outline, size: 24),
                const SizedBox(width: 8),
              ],
              Text(
                title.toUpperCase(),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const Divider(height: 8, thickness: 1),
        ],
      ),
    );
  }
}
