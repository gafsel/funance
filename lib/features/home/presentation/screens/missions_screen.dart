import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/widgets/app_scaffold.dart';
import 'package:funances/features/home/presentation/widgets/weekly_missions_view.dart';
import 'package:go_router/go_router.dart';

/// A semana inteira: as três missões em cartão, o XP da semana e o checklist
/// do que vence.
///
/// Tudo isto morava na Home e media 1158px — 65% de uma tela que já tinha
/// três rolagens e meia. Só o checklist são 516px, e ele é uma LISTA: quem
/// abre o app para saber o que fazer hoje não precisa dela aberta, precisa
/// saber que ela existe. Na Home ficou o resumo de três linhas; o detalhe
/// está aqui, a um toque do cabeçalho.
class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: Text(context.l10n.weeklyMissionsTitle),
        // A tela abre empilhada pela Home, mas também por link direto (uma
        // notificação, um deep link). Sem a saída explícita, chegar por fora
        // deixava a pessoa numa tela sem botão de voltar.
        leading: BackButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: SafeArea(child: WeeklyMissionsView()),
      ),
    );
  }
}
