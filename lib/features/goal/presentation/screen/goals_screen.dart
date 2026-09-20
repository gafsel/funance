import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/widgets/app_scaffold.dart';
import 'package:funances/features/goal/presentation/widgets/goals_section.dart';
import 'package:go_router/go_router.dart';

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
      appBar: AppBar(
        title: Text(context.l10n.goalsTitle),
        // A tela abre empilhada pela Home, mas também por link direto. Sem a
        // saída explícita, chegar por fora deixava a pessoa numa tela sem
        // botão de voltar — o mesmo padrão de `EntityRoute`.
        leading: BackButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle),
            tooltip: context.l10n.journeyAddGoalTooltip,
            onPressed: () => context.push('/goals/form'),
          ),
        ],
      ),
      // `showTitle: false`: a `AppBar` já diz "Metas", e a seção desenhava
      // outro título igual logo abaixo, com um segundo botão de adicionar.
      body: const SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: SafeArea(child: GoalsSection(showTitle: false)),
      ),
    );
  }
}
