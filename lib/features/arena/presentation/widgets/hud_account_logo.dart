import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/features/finance/presentation/providers/account_view_providers.dart';
import 'package:funances/features/finance/presentation/widgets/account_logo.dart';

/// A marca de uma conta nas listas da Arena: a logo do banco e os donos.
///
/// O dono: *"Na lista de contas, que define o hp dos heróis, mostre a logo do
/// banco e dos proprietários, como na aba de visão geral… isso ajuda o
/// usuário a entender como identificar esses dados facilmente (é o padrão
/// adotado em todo o app)"*.
///
/// É o MESMO [AccountLogo] da Visão Geral, e não um desenho parecido: duas
/// implementações da mesma marca divergem na primeira vez que alguém
/// acrescenta um banco — é a lição que já custou catorze barras de progresso
/// a este projeto.
///
/// O que esta casca acrescenta é o caminho do dado. As folhas do HUD recebem
/// LEITURAS (`HudBalanceReading`, `HudInvoiceReading`, `ArenaAccountLife`),
/// que carregam id, nome, cor e ícone — e não o `AccountModel` que a logo
/// precisa. Em vez de engrossar quatro modelos, a conta é buscada pelo id no
/// mapa que já existe ([AccountViewProviders.byIdMap], derivado do stream que
/// a Visão Geral já assina).
///
/// **Conta desconhecida não vira buraco.** Enquanto o mapa não chegou — ou
/// quando a conta foi apagada e a leitura do mês ainda a cita —, fica o
/// quadrado com o ícone e a cor que a própria leitura traz. Era o desenho de
/// antes, e ele continua sendo a rede de segurança.
class HudAccountLogo extends ConsumerWidget {
  const HudAccountLogo({
    super.key,
    required this.accountId,
    this.color,
    this.icon,
    this.size = 32,
  });

  final String accountId;

  /// Cor e ícone da LEITURA, usados só quando a conta não está no mapa.
  final String? color;
  final String? icon;

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(AccountViewProviders.byIdMap)[accountId];

    if (account == null) return _Fallback(color: color, icon: icon, size: size);

    return AccountLogo(account: account, size: size, showMembers: true);
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.color, required this.icon, required this.size});

  final String? color;
  final String? icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tinta = color?.asColor(orElse: palette.ink3) ?? palette.ink3;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tinta.withValues(alpha: 0.16),
        borderRadius: AppRadius.brSm,
      ),
      child: Icon(icon?.asIcon() ?? Icons.circle, size: size * 0.55, color: tinta),
    );
  }
}
