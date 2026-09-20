import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/analytics/analytics_providers.dart';
import 'package:funances/core/form/loading_button.dart';
import 'package:funances/core/form/manual_form.dart';
import 'package:funances/core/time/clock.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/features/arena/domain/models/arena_state.dart';
import 'package:funances/features/arena/presentation/providers/arena_providers.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/services/unplanned_nudge_service.dart';
import 'package:funances/features/finance/presentation/controllers/transaction_form_notifier.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/widgets/replication_cascade_dialog.dart';
import 'package:funances/features/finance/presentation/widgets/unplanned_nudge_sheet.dart';

typedef TransactionFormSnapshot =
    FormBuilderSnapshot<TransactionFormState, dynamic, TransactionFormNotifier>;

/// Traduz o estado do formulário na pergunta que o [UnplannedNudgeService]
/// responde (F3.2).
///
/// Fica fora da tela para ser testável sem widget: o que decide o convite é
/// esta combinação de sinais, não a renderização.
Future<UnplannedNudge?> evaluateUnplannedNudge(
  UnplannedNudgeService service,
  TransactionFormState before,
  DateTime today,
) {
  return service.evaluate(
    category: before.category,
    type: before.type,
    status: before.status,
    // Só lançamento novo: editar uma order antiga ou quitar uma parcela não
    // é "gastei fora do plano agora".
    isNewOrder: before.creation,
    // Se o usuário casou com um agendamento, o gasto estava previsto — e
    // nesse caminho quem salva nem é este formulário.
    matchedPending: before.matchedInstallmentId != null,
    amount: before.amount,
    dueDate: before.dueDate,
    today: today,
    accountId: before.accountIdSource,
  );
}

/// O evento da Arena que este save gera — ou `null` quando ele não move a
/// vida de ninguém.
///
/// Três filtros, cada um com um erro atrás:
///
/// 1. só lançamento **REALIZADO**: um agendamento não tira dinheiro do caixa
///    hoje, ele vira compromisso (e, portanto, vida do monstro);
/// 2. só **criação**: editar uma order antiga não é uma saída nova;
/// 3. só saída da conta **CORRENTE**. Uma compra no cartão não move o caixa, e
///    a barra dos heróis É o caixa: animar dano ali faria o número descer e a
///    barra não andar, que é a pior combinação possível. Ela chega depois,
///    somada, como a fatura. O investimento saiu desta lista com o HUD
///    mensal: ele deixou de ser vida dos heróis e virou a poção do rodapé.
///
/// O valor é o da **parcela**, não o da compra. O formulário guarda o total
/// quando `amountType` é `total`, e um sofá de R$ 3.600 em 12× tirou R$ 300
/// do caixa neste mês — anunciar R$ 3.600 de dano seria um número que a barra
/// nunca vai andar.
///
/// Fica fora da tela e público para ser testável sem widget, como
/// [evaluateUnplannedNudge].
ArenaPendingEvent? arenaEventFor(
  TransactionFormState before,
  AccountType? sourceType,
) {
  if (!before.creation) return null;
  if (before.status != InstallmentStatus.paid &&
      before.status != InstallmentStatus.settled) {
    return null;
  }
  if (sourceType != AccountType.checking) return null;

  final amount = arenaInstallmentAmount(before);
  if (amount <= 0) return null;

  return switch (before.type) {
    OrderType.expense => ArenaPendingEvent(damage: amount),
    OrderType.income => ArenaPendingEvent(healed: amount),
    // Transferência não é nem dano nem cura AQUI: quando ela paga uma fatura
    // ou uma parcela de empréstimo, ela já é compromisso — e o golpe é da
    // folha do monstro, não deste caminho.
    OrderType.transfer => null,
  };
}

/// O valor de UMA parcela, a partir do que o formulário guarda.
///
/// `amount` é o total quando `amountType` é `total`; dividir é o que
/// transforma "comprei um sofá de R$ 3.600" no golpe de R$ 300 que o mês
/// realmente leva.
@visibleForTesting
double arenaInstallmentAmount(TransactionFormState before) {
  final count = before.installmentCount;

  if (before.installmentType == InstallmentType.installment &&
      before.amountType == TransactionAmountType.total &&
      count != null &&
      count > 0) {
    return before.amount / count;
  }

  return before.amount;
}

/// O caminho inteiro do "salvar": cascata → submit → snackbar → convite de
/// gasto não planejado → pop.
///
/// A ordem não é arbitrária e cada passo existe por um motivo aprendido:
/// perguntar a cascata antes de gravar, ler o estado ANTES do save (depois
/// dele `creation` já é falso), e decidir o convite antes do pop porque o
/// `ref` da tela morre com ela.
Future<void> submitTransactionForm(
  BuildContext context, {
  required WidgetRef ref,
  required TransactionFormSnapshot snapshot,
  required LoadingWrapper loading,
  required ScaffoldMessengerState messenger,
  required NavigatorState navigator,
}) async {
  if (!snapshot.validate()) return;

  final l10n = context.l10n;
  final notifier = snapshot.notifier;

  // Lidos no início do submit, e não no build: o convite de gasto não
  // planejado acontece DEPOIS que esta tela sai da pilha, quando o `ref` dela
  // já não responde. Lê-los no build criaria o serviço em toda abertura do
  // formulário, inclusive nas que nunca salvam.
  final nudgeService = ref.read(UnplannedNudgeDomainProviders.service);
  final analytics = ref.read(analyticsServiceProvider);
  final today = ref.read(todayProvider);

  ReplicationCascade cascade = ReplicationCascade.none;

  // `shouldAskCascade` já compara o estado com a parcela persistida: só chega
  // aqui quem mexeu em algo que faz sentido replicar.
  if (notifier.shouldAskCascade) {
    final selectedCascade = await ReplicationCascadeDialog.showUpdate(context);

    if (selectedCascade == null) return;
    cascade = selectedCascade;
  }

  notifier.updateReplicationCascade(cascade);

  // O estado ANTES do save: `submit()` grava o `orderId`, e a partir daí
  // `creation` é falso — perguntar depois faria o convite nunca aparecer para
  // o caso que ele existe para atender.
  final before = snapshot.model;

  final result = await loading(notifier.submit());
  if (result == null) return;

  unawaited(HapticFeedback.mediumImpact());

  // A Arena não está na tela — quem lança um gasto está AQUI. O evento fica
  // guardado e vira golpe quando a cena existir de novo, na volta para a
  // Home. Sem o adiamento, o dano tocava numa tela que ninguém estava vendo.
  final arenaEvent = arenaEventFor(
    before,
    ref
        .read(ArenaViewProviders.accountTypes)
        .valueOrNull?[before.accountIdSource],
  );
  if (arenaEvent != null) {
    ref.read(ArenaViewProviders.pendingEvent.notifier).push(arenaEvent);
  }

  // O que prometer depende de o servidor ter confirmado. As parcelas do
  // lançamento nascem de um trigger no servidor: enquanto a escrita estiver
  // pendente elas não existem em lugar nenhum, e dizer "salvo!" faria o
  // usuário procurar na lista algo que ainda não está lá — foi assim que o
  // lançamento "sumia" offline.
  final pendingSync = notifier.lastWriteIsPending;

  messenger.showSnackBar(
    SnackBar(
      content: Text(switch ((pendingSync, before.creation)) {
        (false, _) => l10n.transactionSaveSuccess,
        // Só a CRIAÇÃO promete parcelas: numa edição elas já existem, e
        // repetir a frase delas confundiria.
        (true, true) => l10n.transactionSavePendingSync,
        (true, false) => l10n.savePendingSync,
      }),
      duration: pendingSync
          ? const Duration(seconds: 6)
          : const Duration(seconds: 4),
    ),
  );

  // F3.2 — o convite é decidido ANTES do pop (o `ref` desta tela morre com
  // ela) e mostrado DEPOIS (sobre ele, o usuário navega para a recorrência ou
  // para o limite sem o formulário atrás).
  final nudge = await evaluateUnplannedNudge(nudgeService, before, today);

  // O contexto do próprio Navigator sobrevive ao pop desta rota; o desta
  // tela, não.
  final sheetContext = navigator.context;

  navigator.pop(true);

  if (nudge == null || !sheetContext.mounted) return;

  final shown = await UnplannedNudgeSheet.show(
    sheetContext,
    nudge: nudge,
    analytics: analytics,
  );

  // Marca só o que de fato apareceu: gravar antes de abrir fazia o usuário
  // perder o convite do dia quando o sheet não chegava à tela (contexto já
  // desmontado), sem nunca ter visto nada.
  if (shown) {
    await nudgeService.markShown(nudge.category.id, today);
  }
}
