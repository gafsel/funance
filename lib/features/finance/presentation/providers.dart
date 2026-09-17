// ─────────────────────────────────────────────────────────────────────────────
// Registro de providers de finanças — BARRIL.
//
// Este arquivo tinha 811 linhas e era o registro central de tudo: repositórios,
// serviços, providers de tela e os cálculos derivados do 50-30-20, sem nenhuma
// fronteira entre eles. Quem vinha mexer no 50-30-20 abria um arquivo que
// também registrava o repositório de conciliação.
//
// Ele agora é só um `export`: os providers moraram para `providers/`, um
// arquivo por subdomínio, e NENHUM import do app precisou mudar — os nomes
// das classes (`FinanceViewProviders`, `AccountViewProviders`, …) continuam
// exatamente os mesmos, e um provider é identidade: mover a declaração de
// arquivo não recria nada.
// ─────────────────────────────────────────────────────────────────────────────

export 'package:funances/features/finance/presentation/providers/account_view_providers.dart';
export 'package:funances/features/finance/presentation/providers/finance_domain_providers.dart';
export 'package:funances/features/finance/presentation/providers/finance_view_providers.dart';
export 'package:funances/features/finance/presentation/providers/period_summary_providers.dart';
