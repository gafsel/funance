import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/widgets/app_scaffold.dart';
import 'package:funances/features/goal/presentation/widgets/goals_section.dart';

/// A tela das metas.
///
/// A lista inteira morava na Home, listando todas as ativas E todas as
/// encerradas, cada uma num cartão com barra, valores e prazo. Meta é um
/// compromisso de meses — a lista não muda de um dia para o outro — e mesmo
/// assim era o bloco mais alto da tela que se abre todo dia. Na Home ficou a
/// meta mais próxima do prazo; as outras estão aqui.
class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: Text(context.l10n.onboardingGoalsTitle)),
      body: const SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: SafeArea(child: GoalsSection()),
      ),
    );
  }
}
