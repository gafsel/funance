import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/firestore/write_failures.dart';
import 'package:funances/core/observability/crash_reporter.dart';
import 'package:funances/features/finance/domain/models/automatic_transaction_model.dart';
import 'package:funances/features/finance/domain/services/automatic_transaction_service.dart';
import 'package:funances/features/finance/domain/services/finance_service.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/services/notification_listener_service.dart';

class AutomaticTransactionState {
  final List<AutomaticTransactionModel> pendingTransactions;
  final bool isLoading;

  AutomaticTransactionState({
    this.pendingTransactions = const [],
    this.isLoading = false,
  });

  AutomaticTransactionState copyWith({
    List<AutomaticTransactionModel>? pendingTransactions,
    bool? isLoading,
  }) {
    return AutomaticTransactionState(
      pendingTransactions: pendingTransactions ?? this.pendingTransactions,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AutomaticTransactionNotifier
    extends StateNotifier<AutomaticTransactionState> {
  final AutomaticTransactionService _service;
  final FinanceService _financeService;
  final INotificationListenerService _notificationService;
  // Só usamos a assinatura para cancelar, então o tipo do elemento é irrelevante.
  StreamSubscription<void>? _notificationSubscription;

  AutomaticTransactionNotifier({
    required AutomaticTransactionService service,
    required FinanceService financeService,
    required INotificationListenerService notificationService,
  }) : _service = service,
       _financeService = financeService,
       _notificationService = notificationService,
       super(AutomaticTransactionState()) {
    loadTransactions();
    _notificationService.startListening();
    _listenToNotifications();
  }

  void _listenToNotifications() {
    _notificationSubscription?.cancel();
    _notificationSubscription = NotificationListenerService.notificationStream
        .listen((event) {
          if (_notificationService is NotificationListenerService) {
            (_notificationService)
                .onNotificationReceived(
                  notificationId:
                      event.id?.toString() ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  title: event.title ?? "",
                  body: event.text ?? "",
                  timestamp: DateTime.now(),
                  packageName: event.packageName,
                )
                .then((_) => loadTransactions());
          }
        });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadTransactions() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true);
    final transactions = await _service.getPendingTransactions();

    // Tenta enriquecer as transações com sugestões se houver conexão
    final enrichedTransactions = await _enrichWithSuggestions(transactions);

    if (!mounted) return;
    state = state.copyWith(
      pendingTransactions: enrichedTransactions,
      isLoading: false,
    );
  }

  Future<List<AutomaticTransactionModel>> _enrichWithSuggestions(
    List<AutomaticTransactionModel> transactions,
  ) async {
    return transactions;
  }

  /// Executa uma escrita de triagem e RECARREGA a lista, dê no que der.
  ///
  /// Cada uma destas ações era um `await` cru dentro de um `VoidCallback`: a
  /// exceção virava erro assíncrono não tratado, o `loadTransactions()` seguinte
  /// nunca rodava e a pendência ficava na tela sem explicação nenhuma. Era
  /// exatamente assim que "apagar" não apagava — a escrita morria antes de sair
  /// do aparelho e ninguém ficava sabendo.
  ///
  /// A falha vai para a tarja de sincronização, que vive acima de todas as
  /// rotas, com o mesmo `WriteEntity` do repositório. E a lista é recarregada
  /// do servidor mesmo no erro: o item VOLTA, que é a verdade — nada mudou — e
  /// dá para tentar de novo.
  Future<bool> _triage(Future<void> Function() write) async {
    try {
      await write();
      return true;
    } catch (error, stack) {
      WriteFailures.report(
        WriteEntity.automaticTransaction,
        writeFailureReasonOf(error),
      );
      CrashReporter.recordError(error, stack);
      return false;
    } finally {
      await loadTransactions();
    }
  }

  Future<void> consolidate(
    AutomaticTransactionModel transaction,
    OrderModel order,
  ) async {
    await _triage(() async {
      await _financeService.addOrder(order);
      await _service.updateTransaction(
        transaction.copyWith(isConsolidated: true),
      );
    });
  }

  Future<void> ignore(AutomaticTransactionModel transaction) async {
    await _triage(
      () => _service.updateTransaction(transaction.copyWith(isIgnored: true)),
    );
  }

  Future<void> moveToWorkspace(
    AutomaticTransactionModel transaction,
    String toWorkspaceId,
  ) async {
    await _triage(() => _service.moveTransaction(toWorkspaceId, transaction));
  }

  Future<void> simulateNotification() async {
    final now = DateTime.now();
    final isIncome = now.second % 2 == 0;
    final newTransaction = AutomaticTransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      description: isIncome
          ? "Pix recebido de João Silva R\$ 50,00"
          : "Pagamento de R\$ 120,50 no Posto Shell",
      amount: isIncome ? 50.0 : 120.50,
      date: now,
      type: isIncome ? OrderType.income : OrderType.expense,
      packageName: "com.android.vending",
      originNotificationId: "sim-${now.millisecondsSinceEpoch}",
    );

    await _service.saveTransaction(newTransaction);
    await loadTransactions();
  }
}
