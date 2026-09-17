import 'package:flutter/material.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/widgets/empty_state.dart';

/// Semana sem nada vencendo: um convite, não uma parabenização.
///
/// É o par do `SuccessEmptyState` e existe separado dele justamente porque a
/// diferença importa — celebrar uma semana em que o usuário não fez nada
/// premia o vazio.
class NoMissionsEmptyState extends StatelessWidget {
  const NoMissionsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return EmptyState.card(
      icon: Icons.flag_outlined,
      title: l10n.weeklyMissionsNone,
      message: l10n.weeklyMissionsNoneDesc,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
    );
  }
}
