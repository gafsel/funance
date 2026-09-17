import 'package:freezed_annotation/freezed_annotation.dart';

part 'financial_health_model.freezed.dart';

/// Patente da Bússola da Liberdade.
///
/// Um valor que o app não conhece cai em [unknown] e a tela mostra o score sem
/// patente, em vez de quebrar por causa de um nome novo publicado pelo
/// servidor.
enum FreedomTier {
  aprendiz,
  guardiao,
  estrategista,
  mestre,
  livre,
  unknown;

  static FreedomTier parse(Object? raw) {
    return switch (raw) {
      'aprendiz' => aprendiz,
      'guardiao' => guardiao,
      'estrategista' => estrategista,
      'mestre' => mestre,
      'livre' => livre,
      _ => unknown,
    };
  }

  /// Patente pela faixa do score.
  ///
  /// Usada quando o servidor publica o `score` sem um `tier` que o app
  /// reconheça. A régua é do produto (0–19 Aprendiz, 20–39 Guardião, 40–59
  /// Estrategista, 60–79 Mestre, 80–100 Livre) e é a mesma que o servidor
  /// aplica — derivar aqui evita a tela mostrar um score alto ao lado de "Em
  /// avaliação", que lê como se o índice não valesse.
  ///
  /// O `tier` do servidor continua tendo prioridade: se ele mudar a régua, a
  /// tela acompanha sem depender de um deploy do app.
  static FreedomTier forScore(double score) {
    if (score >= 80) return livre;
    if (score >= 60) return mestre;
    if (score >= 40) return estrategista;
    if (score >= 20) return guardiao;
    return aprendiz;
  }
}

/// Os quatro componentes do índice, na ordem em que a bússola os mostra.
enum FreedomComponent { folego, poupanca, disciplina, alivio }

/// Um componente do índice, com o número que o explica.
///
/// Cada componente tem uma unidade própria — [months] para o Fôlego, [rate]
/// para a Poupança, [within]/[total] para a Disciplina e [delta] para o
/// Alívio. Todos são opcionais: o servidor pode publicar só o score, e a tela
/// mostra a barra sem a legenda em vez de inventar um número.
@freezed
sealed class FreedomComponentScore with _$FreedomComponentScore {
  const FreedomComponentScore._();

  const factory FreedomComponentScore({
    required FreedomComponent component,
    required double score,
    double? months,
    double? rate,
    int? within,
    int? total,
    double? delta,
  }) = _FreedomComponentScore;

  /// Score de 0 a 1, para a barra.
  double get fraction => (score / 100).clamp(0.0, 1.0);
}

/// `workspaces/{w}.financialHealth` — a Bússola da Liberdade.
///
/// O app só LÊ: o índice é calculado pelo servidor. Enquanto o documento não
/// tiver o campo, a Jornada mostra "sua bússola está sendo calibrada".
@freezed
sealed class FinancialHealth with _$FinancialHealth {
  const FinancialHealth._();

  const factory FinancialHealth({
    required double score,
    required FreedomTier tier,
    @Default(<FreedomComponentScore>[]) List<FreedomComponentScore> components,
    DateTime? computedAt,
    String? monthKey,
  }) = _FinancialHealth;

  /// Score de 0 a 1, para o anel.
  double get fraction => (score / 100).clamp(0.0, 1.0);

  FreedomComponentScore? componentOf(FreedomComponent component) =>
      components.where((c) => c.component == component).firstOrNull;
}

/// Um ponto do histórico (`workspaces/{w}/health_history/{YYYY-MM}`).
@freezed
sealed class FinancialHealthPoint with _$FinancialHealthPoint {
  const factory FinancialHealthPoint({
    required String monthKey,
    required double score,
    @Default(FreedomTier.unknown) FreedomTier tier,
  }) = _FinancialHealthPoint;
}
