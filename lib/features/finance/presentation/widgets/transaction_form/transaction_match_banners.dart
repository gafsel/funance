import 'package:flutter/material.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/controllers/transaction_form_notifier.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';

/// Altura reservada para a oferta de agendamentos, em pixels lógicos.
///
/// É a altura do conteúdo da oferta com um agendamento: título em duas
/// linhas mais uma linha de agendamento. O banner ocupa esse espaço já
/// durante a busca para que os campos nasçam na posição final — a oferta
/// chegando depois empurraria o campo de valor para baixo bem quando o dedo
/// do usuário está descendo nele, e o toque que era do valor viraria toque
/// no agendamento.
///
/// O número é medido, não deduzido, e o teste "o espaço da oferta é
/// reservado enquanto a busca corre" o mantém honesto: se o banner mudar de
/// tamanho, é ele que quebra. A reserva é exata no caso comum — um
/// agendamento, tamanho de texto padrão; com dois ou mais o banner ainda
/// cresce, e aí o usuário já está lendo uma lista, não digitando.
const double reservedMatchesHeight = 100;

/// Espaço reservado enquanto a busca por agendamentos corre.
///
/// O indicador é discreto de propósito: explica o vão no topo sem competir
/// com o formulário, que já está utilizável. Quem já sabe que o lançamento
/// é novo pode recusar a oferta antes mesmo dela chegar.
MaterialBanner searchingMatchesBanner(
  BuildContext context,
  TransactionFormState state,
  TransactionFormNotifier notifier,
) {
  final l10n = context.l10n;
  final theme = Theme.of(context);

  return MaterialBanner(
    backgroundColor: theme.colorScheme.secondaryContainer,
    content: SizedBox(
      height: reservedMatchesHeight,
      child: Row(
        spacing: 12,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
          Expanded(
            child: Text(
              l10n.transactionMatchSearching,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    ),
    actions: [_DismissAction(state: state, notifier: notifier)],
  );
}

/// Oferta de casamento com um agendamento já existente.
///
/// Aparece antes dos campos porque a pergunta muda o que o save vai fazer:
/// quitar a parcela agendada ou criar um lançamento novo. Sem a pergunta, o
/// usuário criava o lançamento novo sem perceber e o agendamento ficava
/// pendente para sempre — planejado em dobro no 50-30-20, missão atrasada
/// que nunca fecha e saldo projetado errado.
MaterialBanner pendingMatchesBanner(
  BuildContext context,
  TransactionFormState state,
  TransactionFormNotifier notifier,
) {
  final l10n = context.l10n;
  final theme = Theme.of(context);
  final locale = context.locale;
  final likelyId = state.likelyMatchId;

  return MaterialBanner(
    backgroundColor: theme.colorScheme.secondaryContainer,
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.transactionMatchTitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...state.pendingMatches.map((match) {
          final likely = match.id == likelyId;

          return InkWell(
            key: ValueKey('pending-match-${match.id}'),
            onTap: () => notifier.selectMatch(match),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              // O destaque é do valor que bate com o digitado. A cor
              // sozinha não serve a quem não a distingue, então o rótulo
              // "mesmo valor" diz em texto por que esta linha é diferente.
              decoration: likely
                  ? BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    )
                  : null,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Row(
                spacing: 8,
                children: [
                  const Icon(Icons.event_available_outlined, size: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${match.amount.asCurrency(locale: locale)} · '
                          '${match.dueDate.formated(l10n.formatSimpleDate)}'
                          '${likely ? ' · ${l10n.transactionMatchSameAmount}' : ''}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: likely
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    l10n.transactionMatchSettle,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    ),
    actions: [_DismissAction(state: state, notifier: notifier)],
  );
}

/// "Não é nenhum desses" — o mesmo botão nos dois banners, com a frase no
/// gênero certo para receita.
class _DismissAction extends StatelessWidget {
  const _DismissAction({required this.state, required this.notifier});

  final TransactionFormState state;
  final TransactionFormNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return TextButton(
      onPressed: notifier.dismissMatches,
      child: Text(
        state.type == OrderType.income
            ? l10n.transactionMatchDismissIncome
            : l10n.transactionMatchDismiss,
      ),
    );
  }
}
