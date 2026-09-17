import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:funances/features/home/presentation/widgets/compass/compass_content.dart';
import 'package:funances/features/home/presentation/widgets/compass/compass_shell.dart';
import 'package:funances/features/home/presentation/widgets/compass/freedom_compass_sheet.dart';

// As peças da Bússola moram em `compass/` desde que este arquivo foi quebrado
// por responsabilidade. Continuam saindo por aqui porque `freedom_compass.dart`
// é o endereço que a Jornada e os testes já conheciam — quebrar o arquivo não
// é motivo para quebrar quem o importa.
export 'package:funances/features/home/presentation/widgets/compass/compass_content.dart';
export 'package:funances/features/home/presentation/widgets/compass/compass_history.dart';
export 'package:funances/features/home/presentation/widgets/compass/compass_labels.dart';
export 'package:funances/features/home/presentation/widgets/compass/compass_shell.dart';
export 'package:funances/features/home/presentation/widgets/compass/compass_sparkline_painter.dart';
export 'package:funances/features/home/presentation/widgets/compass/freedom_compass_sheet.dart';

/// A Bússola da Liberdade na Jornada.
///
/// Lê `workspaces/{w}.financialHealth`, que é calculado no servidor. Enquanto
/// o índice não existir (workspace novo, ou backend ainda não publicado), o
/// card diz que a bússola está sendo calibrada — não some e não quebra.
class FreedomCompassCard extends ConsumerWidget {
  const FreedomCompassCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(JourneyViewProviders.financialHealth);

    // Erro (regra do Firestore ainda não publicada, por exemplo) cai no mesmo
    // estado de "calibrando": não há ação do usuário que resolva, e uma tela
    // de erro só assustaria.
    final health = async.valueOrNull;

    if (health == null) {
      return CompassShell(
        child: async.isLoading
            ? const CompassLoading()
            : const CompassCalibrating(),
      );
    }

    return CompassShell(
      onTap: () => FreedomCompassSheet.show(context, health),
      child: CompassContent(health: health),
    );
  }
}
