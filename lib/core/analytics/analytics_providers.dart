import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/analytics/analytics_service.dart';

/// Ponto único de acesso ao analytics.
///
/// Em testes basta sobrescrever com um fake (ou com [NoopAnalyticsService])
/// via `overrideWithValue`, sem precisar do Firebase inicializado.
final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => FirebaseAnalyticsService(),
);
