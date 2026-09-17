import 'dart:developer' as developer;
import 'dart:async';
import 'package:funances/core/platform/app_platform.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:funances/features/finance/domain/models/automatic_transaction_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/services/automatic_transaction_service.dart';

abstract class INotificationListenerService {
  Future<void> startListening();
  Future<void> stopListening();
  Future<bool> isPermissionGranted();
  Future<void> openPermissionSettings();
}

@pragma('vm:entry-point')
class NotificationListenerService implements INotificationListenerService {
  final AutomaticTransactionService service;

  // Stream para comunicar eventos do isolate de background para o isolate principal
  static final StreamController<NotificationEvent> _notificationStreamController = 
      StreamController<NotificationEvent>.broadcast();

  static Stream<NotificationEvent> get notificationStream => _notificationStreamController.stream;

  @pragma('vm:entry-point')
  NotificationListenerService({required this.service});

  @override
  Future<void> startListening() async {
    if (!AppPlatform.isAndroid) {
      return;
    }

    final bool hasPermission = await isPermissionGranted();
    if (!hasPermission) {
      return;
    }

    await NotificationsListener.initialize(
      callbackHandle: _onNotificationEvent,
    );
    await NotificationsListener.startService(
      title: "Funances",
      description: "Monitorando notificações bancárias",
      showWhen: true,
      foreground: true,
    );
  }

  @override
  Future<void> stopListening() async {
    if (!AppPlatform.isAndroid) {
      return;
    }

    await NotificationsListener.stopService();
  }

  @override
  Future<bool> isPermissionGranted() async {
    if (!AppPlatform.isAndroid) {
      return false;
    }

    return await NotificationsListener.hasPermission ?? false;
  }

  @override
  Future<void> openPermissionSettings() async {
    if (!AppPlatform.isAndroid) {
      return;
    }

    await NotificationsListener.openPermissionSettings();
  }

  // Callback estático obrigatório para o plugin
  @pragma('vm:entry-point')
  static void _onNotificationEvent(NotificationEvent event) {
    _handleNotificationStatic(event);
  }

  @pragma('vm:entry-point')
  static Future<void> _handleNotificationStatic(NotificationEvent event) async {
    developer.log(
      'Notificação recebida em background',
      name: 'funances.NotificationListener',
    );
    
    // Filtra notificações de sistema irrelevantes antes de enviar para o stream
    if (event.packageName == 'com.android.systemui' || 
        event.packageName == 'android' ||
        (event.title == null && event.text == null)) {
      return;
    }

    // Encaminha o evento para o isolate principal via stream
    _notificationStreamController.add(event);
  }

  // Método chamado para processar a notificação (adaptado do código anterior)
  Future<void> onNotificationReceived({
    required String notificationId,
    required String title,
    required String body,
    required DateTime timestamp,
    String? packageName,
  }) async {
    // Evitar duplicidade
    if (await service.existsByNotificationId(notificationId)) {
      return;
    }

    // Lógica de Parsing simples (Simulada)
    // Exemplo: "Pagamento de R$ 50,00 realizado em Starbucks"
    final transaction = _parseNotification(notificationId, title, body, timestamp, packageName);
    
    if (transaction != null) {
      await service.saveTransaction(transaction);
    }
  }

  AutomaticTransactionModel? _parseNotification(
    String id,
    String title,
    String body,
    DateTime date,
    String? packageName,
  ) {
    // Regex simples para capturar valores em R$
    final regExp = RegExp(r'R\$\s?((\d+\.)*\d+,\d{2})');
    final match = regExp.firstMatch(body);
    
    if (match != null) {
      final amountStr = match.group(1)?.replaceAll('.', '').replaceAll(',', '.') ?? "0.0";
      final amount = double.tryParse(amountStr) ?? 0.0;
      
      // Identifica o tipo baseado em palavras chave
      OrderType type = OrderType.expense;
      final incomeKeywords = ['recebido', 'recebeu', 'transferência recebida', 'pix recebido', 'depósito'];
      final bodyLower = body.toLowerCase();
      if (incomeKeywords.any((keyword) => bodyLower.contains(keyword))) {
        type = OrderType.income;
      }

      return AutomaticTransactionModel(
        id: const Uuid().v4(),
        description: body,
        amount: amount,
        date: date,
        type: type,
        originNotificationId: id,
        packageName: packageName,
      );
    }
    
    return null;
  }
}

/// Implementação inerte para toda plataforma que não é Android.
///
/// O `flutter_notification_listener` só tem lado nativo no Android; na web
/// nem isso — tocar no canal de lá levanta `MissingPluginException`. Antes o
/// serviço real era registrado em todo lugar e cada chamada precisava se
/// defender sozinha. Agora quem não é Android recebe este objeto, e o
/// provider deixa de ser o lugar onde a plataforma é decidida por acidente.
class NoopNotificationListenerService implements INotificationListenerService {
  const NoopNotificationListenerService();

  @override
  Future<void> startListening() async {}

  @override
  Future<void> stopListening() async {}

  /// Sem permissão possível: a tela que pergunta isso não deve nem aparecer.
  @override
  Future<bool> isPermissionGranted() async => false;

  @override
  Future<void> openPermissionSettings() async {}
}
