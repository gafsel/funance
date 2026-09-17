import 'package:funances/core/firestore/offline_write.dart';
import 'dart:async';

import 'package:funances/core/analytics/analytics_service.dart';
import 'package:funances/core/form/form_notifier.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/services/finance_service.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/home/domain/services/mission_service.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

class TransactionFormNotifier
    extends FormNotifier<TransactionFormState, dynamic> {
  final FinanceService financeService;
  final AnalyticsService analytics;

  /// Dia corrente, do relógio injetado. Define a janela de busca dos
  /// agendamentos e a data de quitação quando um deles é escolhido.
  final DateTime today;

  /// Quantos agendamentos a oferta mostra. Mais que isso vira uma lista para
  /// ler em vez de uma pergunta para responder.
  static const int maxPendingMatches = 5;

  TransactionFormNotifier(
    super.initialState, {
    required this.financeService,
    required this.analytics,
    DateTime? today,
  }) : today = today ?? DateTime.now(),
       super() {
    if (state.creation) {
      // A conta é obrigatória também em agendamentos, então o formulário
      // tenta resolver um default antes de pedir ao usuário.
      state = state.copyWith(resolvingAccount: true);
      unawaited(_resolveDefaultAccount());
      _lookForPendingMatches();
    }

    // A transferência pode chegar com as contas já preenchidas (extrato da
    // conta, fatura); o aviso de pool precisa aparecer sem esperar um toque.
    if (state.type == OrderType.transfer) {
      unawaited(_resolveTransferAccounting());
    }
  }

  void updateDescription(String value) =>
      state = state.copyWith(description: value);

  void updateAmount(double value) => state = state.copyWith(amount: value);

  void updateAmountType(TransactionAmountType value) =>
      state = state.copyWith(amountType: value);

  void updateInstallmentCount(int value) =>
      state = state.copyWith(installmentCount: value);

  void updateDueDate(DateTime value) => state = state.copyWith(dueDate: value);

  void updateCategory(CategoryModel? value) {
    final changed = state.category?.id != value?.id;
    state = state.copyWith(category: value);

    if (!state.creation || value == null) return;

    // Trocar a categoria muda qual é a "última conta usada": só vale a pena
    // reagir enquanto o usuário ainda não escolheu conta nenhuma.
    if (state.accountIdSource == null) {
      state = state.copyWith(resolvingAccount: true);
      unawaited(_resolveDefaultAccount());
    }

    // E muda quais agendamentos podem ser este lançamento. Recusar a oferta
    // de uma categoria não vale para a próxima.
    if (changed) {
      state = state.copyWith(
        pendingMatches: const [],
        dismissedMatch: false,
      );
      _lookForPendingMatches();
    }
  }

  void updateAccountIdTarget(String? value) {
    state = state.copyWith(
      accountIdTarget: value,
      accountIdSource: value == state.accountIdSource
          ? null
          : state.accountIdSource,
    );
    unawaited(_resolveTransferAccounting());
  }

  void updateAccountIdSource(String? value) {
    state = state.copyWith(
      accountIdSource: value,
      accountIdTarget: value == state.accountIdTarget
          ? null
          : state.accountIdTarget,
    );
    unawaited(_resolveTransferAccounting());
  }

  /// Procura agendamentos que este lançamento pode estar quitando.
  ///
  /// Só no caminho "Registrei": agendar em cima de um agendamento não é
  /// casamento, é outra intenção. Transferência não tem categoria escolhível
  /// e fica de fora.
  void _lookForPendingMatches() {
    if (state.type == OrderType.transfer ||
        state.category == null ||
        !_isPaid(state.status)) {
      return;
    }

    state = state.copyWith(loadingMatches: true);
    unawaited(_loadPendingMatches());
  }

  /// Parcelas pendentes da categoria no mês corrente e no anterior.
  ///
  /// A janela cobre o mês passado porque a conta que vence dia 5 costuma ser
  /// paga com atraso, e é exatamente essa que o usuário está registrando.
  Future<void> _loadPendingMatches() async {
    final category = state.category;

    try {
      final chunk = await financeService.queryInstallments(
        limit: maxPendingMatches,
        categoryId: category!.id,
        type: state.type,
        status: InstallmentStatus.pending,
        startDate: DateTime(today.year, today.month - 1, 1),
        // Fim do dia para incluir o que vence no último dia do mês
        // (referenceDate é normalizado às 12:00).
        endDate: DateTime(today.year, today.month + 1, 0, 23, 59, 59),
      );

      if (!mounted) return;
      // Resposta atrasada de uma categoria que não é mais a escolhida não
      // pode oferecer os agendamentos da categoria errada.
      if (state.category?.id != category.id) return;

      // Mais antigo primeiro: o agendamento atrasado é o candidato mais
      // provável e é o que vira missão vencida se ficar para trás. A ordem
      // do servidor não garante isso, e o corte em [maxPendingMatches] já
      // aconteceu — esta ordenação arruma o que veio, não escolhe o que vem.
      final matches = [...chunk.items]
        ..sort((a, b) => a.referenceDate.compareTo(b.referenceDate));

      state = state.copyWith(
        pendingMatches: matches,
        loadingMatches: false,
      );
    } catch (_) {
      if (!mounted) return;
      // Silencioso de propósito: sem a oferta, o lançamento segue como novo.
      state = state.copyWith(loadingMatches: false);
    }
  }

  /// O usuário escolheu quitar um agendamento em vez de criar um lançamento.
  ///
  /// O valor e a descrição que ele já tinha digitado continuam no estado: a
  /// tela troca o formulário à frente, mas este notifier segue vivo, e é por
  /// isso que [clearMatch] consegue devolver o que estava preenchido.
  void selectMatch(InstallmentModel installment) {
    state = state.copyWith(matchedInstallment: installment);
  }

  /// "Não era esse": desfaz o casamento e volta ao formulário de criação.
  ///
  /// A oferta continua de pé — tocar no agendamento errado não é dizer que o
  /// lançamento é novo, e cobrar essa segunda resposta do usuário só para
  /// corrigir um toque seria trocar um engano por um beco sem saída.
  void clearMatch() {
    state = state.copyWith(matchedInstallment: null);
  }

  /// "É um gasto novo": a oferta some e não volta nesta categoria.
  void dismissMatches() {
    state = state.copyWith(dismissedMatch: true, loadingMatches: false);
  }

  // Onde vive o sinal do casamento, para quem for construir o nudge de F3.2:
  //
  // `matchedInstallmentId` e `dismissedMatch` são estado DESTE notifier, o de
  // criação, e morrem com ele — são a memória de uma sessão do formulário
  // ("já perguntei, e ele respondeu isto"), não um dado do lançamento.
  //
  // Depois que o usuário casa, este notifier nem chega a salvar: a tela passa
  // a editar a parcela, e quem persiste é o formulário de quitação. O sinal
  // duradouro de que o agendamento foi quitado é, portanto, a própria parcela
  // com status `paid` — é ela que F3.2 deve ler, não um campo daqui.

  /// Conta padrão do lançamento: a última que o usuário usou na categoria
  /// escolhida e, na falta dela, a única conta do workspace.
  ///
  /// Silencioso de propósito: não achar um default não é erro, só significa
  /// que o campo continua vazio e o usuário escolhe.
  Future<void> _resolveDefaultAccount() async {
    String? resolved;

    try {
      final categoryId = state.category?.id;

      if (categoryId != null) {
        // Sem filtro de status na consulta porque o repositório aceita um só
        // e "conta já usada" é paga OU liquidada; agendamento ainda não saiu
        // de conta nenhuma e `removed` é lixo. O filtro vem depois, num lote
        // maior para sobrar histórico real.
        final chunk = await financeService.queryInstallments(
          limit: 20,
          categoryId: categoryId,
          type: state.type,
        );

        resolved = chunk.items
            .where((installment) => _isPaid(installment.status))
            .map((installment) => installment.accountIdSource)
            .nonNulls
            .firstOrNull;
      }

      if (resolved == null) {
        final accounts = await financeService.getAccounts();
        if (accounts.length == 1) {
          resolved = accounts.first.id;
        }
      }
    } catch (_) {
      // Silencioso de propósito.
    }

    if (!mounted) return;

    state = state.copyWith(
      resolvingAccount: false,
      // Se o usuário escolheu uma conta enquanto a busca corria, ela ganha.
      accountIdSource: state.accountIdSource ?? resolved,
    );
  }

  /// Descobre em qual pool a transferência vai cair para o formulário avisar.
  ///
  /// Quem grava a categoria virtual é `FinanceService._processVirtualCategory`
  /// (e o `SummaryService` recalcula no servidor); aqui é só informação.
  Future<void> _resolveTransferAccounting() async {
    if (state.type != OrderType.transfer) return;

    final sourceId = state.accountIdSource;
    final targetId = state.accountIdTarget;

    TransferAccounting? accounting;

    try {
      if (targetId != null) {
        accounting = _accountingOf(await financeService.getAccount(targetId));
      }

      if (accounting == null && sourceId != null) {
        accounting = _accountingOf(await financeService.getAccount(sourceId));
      }
    } catch (_) {
      accounting = null;
    }

    if (!mounted) return;

    state = state.copyWith(transferAccounting: accounting);
  }

  static TransferAccounting? _accountingOf(AccountModel account) =>
      switch (account.type) {
        AccountType.debt => TransferAccounting.debt,
        AccountType.investment => TransferAccounting.investment,
        _ => null,
      };

  void updateInstallmentType(InstallmentType value) {
    if (state.creation) {
      state = state.copyWith(installmentType: value);
    }
  }

  void updateOrderType(OrderType type) {
    if (state.creation) {
      state = state.copyWith(
        type: type,
        category: type == OrderType.transfer ? null : state.category,
      );
    }
  }

  void updatePaidDate(DateTime? value) {
    state = state.copyWith(
      dueDate: state.creation || state.amount > 0
          ? state.dueDate
          : value ?? state.dueDate,
      paidDate: value,
    );
  }

  void updatePaidAmount(double? value) =>
      state = state.copyWith(paidAmount: value);

  void updateReplicationCascade(ReplicationCascade? value) =>
      state = state.copyWith(replicateCascade: value);

  void updateStatus(InstallmentStatus value) {
    if (value == InstallmentStatus.paid || value == InstallmentStatus.settled) {
      state = state.copyWith(
        status: value,
        paidAmount: state.amount,
        paidDate: state.dueDate.isAfter(DateTime.now())
            ? DateTime.now()
            : state.dueDate,
      );
    } else {
      state = state.copyWith(status: value, paidDate: null, paidAmount: null);
    }
  }

  void unsettle() {
    state = state.copyWith(status: InstallmentStatus.paid);
  }

  Future<void> delete() async {
    if (state.installmentId == null) return;

    await financeService.cancelInstallment(
      state.installmentId!,
      replicationCascade: state.replicateCascade ?? ReplicationCascade.none,
    );
  }

  /// Se o SERVIDOR confirmou o último save.
  ///
  /// A tela precisa disso para escolher o que prometer: "pendente" significa
  /// que as parcelas, que nascem de um trigger no servidor, ainda não existem.
  /// Fica aqui, e não em `state`, porque `state` é do notifier.
  WriteOutcome get lastWriteOutcome => state.lastWriteOutcome;

  @override
  Future<dynamic> submit() async {
    // `state.status` já é o status NOVO quando chegamos aqui — a UI chama
    // updateStatus (ou monta o form já com status: paid) antes do submit.
    // Quem responde "como estava antes" é o status persistido da parcela.
    final wasAlreadyPaid = _isPaid(state.originalStatus);

    final dynamic result;
    if (state.formType == TransactionFormType.order) {
      final order = state.asOrderModel();

      if (state.creation) {
        final saved = await financeService.addOrder(order);

        state = state.copyWith(
          orderId: saved.value.id,
          lastWriteOutcome: saved.outcome,
        );

        result = saved.value;
      } else {
        await financeService.updateOrder(order);

        result = order;
      }
    } else {
      final installment = state.asInstallmentModel();

      await financeService.updateInstallment(installment);

      result = installment;
    }

    await _logSaved(wasAlreadyPaid: wasAlreadyPaid);

    return result;
  }

  static bool _isPaid(InstallmentStatus? status) =>
      status == InstallmentStatus.paid || status == InstallmentStatus.settled;

  /// Emite os eventos do funil. Nunca propaga erro: analytics não pode
  /// derrubar o salvamento de um lançamento.
  Future<void> _logSaved({required bool wasAlreadyPaid}) async {
    try {
      await analytics.logTransactionSaved(
        status: state.status.name,
        hadPlanning: await _hadPlanning(),
        type: state.type.name,
      );

      // Só conta como pagamento a submissão que de fato quitou a parcela:
      // reeditar uma parcela já paga não emite installment_paid de novo.
      final isInstallment = state.formType == TransactionFormType.installment;
      final justPaid = isInstallment && !wasAlreadyPaid && _isPaid(state.status);

      if (justPaid) {
        await analytics.logInstallmentPaid();

        // Uma missão semanal é exatamente uma parcela da semana corrente que
        // passou a paga/quitada.
        if (_isInCurrentWeek(state.dueDate)) {
          await analytics.logMissionCompleted();
        }
      }
    } catch (_) {
      // Silencioso de propósito.
    }
  }

  /// Regra do `had_planning`:
  ///
  /// - Caminho de parcela: a parcela já existia como item agendado antes deste
  ///   save, então conta como planejada. Vale tanto para a que estava pendente
  ///   (era algo agendado que o usuário está quitando agora) quanto para a
  ///   reedição de uma já paga, que mantém o valor que teria quando foi
  ///   quitada — senão o mesmo lançamento mudaria de classificação só por ter
  ///   sido reaberto.
  /// - Caminho de order (lançamento avulso): só é true quando a categoria tem
  ///   planejamento vigente no mês do vencimento.
  Future<bool> _hadPlanning() async {
    if (state.formType == TransactionFormType.installment) return true;

    final category = state.category;
    if (category == null) return false;

    try {
      final month = state.dueDate.formated("yyyy-MM");
      final plannings = await financeService.getCategoryPlannings(
        startMonth: month,
        endMonth: month,
      );

      return plannings.any((p) => p.category.id == category.id);
    } catch (_) {
      return false;
    }
  }

  /// Usa a mesma janela do `MissionService`: aqui a semana começava na
  /// segunda e lá no domingo, então uma parcela paga no domingo contava como
  /// missão numa ponta e não na outra.
  static bool _isInCurrentWeek(DateTime date) {
    final week = MissionService.weekWindow(DateTime.now());

    return !date.isBefore(week.start) && !date.isAfter(week.end);
  }

  /// Perguntar sobre replicação só faz sentido quando há para onde replicar e
  /// algo replicável de fato mudou.
  ///
  /// Antes esta propriedade devolvia `true` para toda edição de parcela de uma
  /// série, e a comparação com o original ficava espalhada na tela — o
  /// diálogo aparecia até para quem só marcou a parcela como paga.
  bool get shouldAskCascade {
    if (state.creation || state.formType != TransactionFormType.installment) {
      return false;
    }

    if (!state.hasSiblings) {
      return false;
    }

    return state.replicableFieldsChanged;
  }
}
