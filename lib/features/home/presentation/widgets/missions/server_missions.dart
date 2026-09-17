import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/widgets/empty_state.dart';
import 'package:funances/features/home/domain/models/weekly_mission_model.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:funances/features/home/presentation/widgets/missions/mission_card.dart';
import 'package:funances/l10n/app_localizations.dart';

/// As três missões que o servidor gerou para a semana corrente.
class ServerMissions extends ConsumerWidget {
  const ServerMissions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(JourneyViewProviders.weeklyMissions);

    // Erro de leitura degrada para o mesmo aviso de "ainda não chegou": para
    // quem usa o app, uma regra do Firestore que ainda não foi publicada e um
    // cron que ainda não rodou são a mesma coisa — não há nada para fazer.
    final missions = async.valueOrNull ?? const <WeeklyMissionModel>[];

    if (missions.isEmpty) {
      if (async.isLoading) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return _MissionsSoon(l10n: l10n);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final mission in missions) ...[
          MissionCard(mission: mission),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _MissionsSoon extends StatelessWidget {
  const _MissionsSoon({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return EmptyState.card(
      icon: Icons.hourglass_top_rounded,
      title: l10n.journeyMissionsSoonTitle,
      message: l10n.journeyMissionsSoonMessage,
    );
  }
}
