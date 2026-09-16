import 'package:freezed_annotation/freezed_annotation.dart';

part 'badge_catalog_model.freezed.dart';

part 'badge_catalog_model.g.dart';

/// Seções da vitrine de conquistas, na ordem em que aparecem.
///
/// Espelha `BADGE_CATEGORIES` do backend. Uma categoria desconhecida (badge
/// novo publicado por um servidor mais novo que o app) cai em [unknown] e é
/// mostrada no fim, em vez de sumir da tela.
enum BadgeCategory {
  @JsonValue('advanced')
  advanced,
  @JsonValue('first_steps')
  firstSteps,
  @JsonValue('consistency')
  consistency,
  @JsonValue('savings')
  savings,
  @JsonValue('goals')
  goals,
  @JsonValue('team')
  team,
  unknown,
}

@freezed
sealed class BadgeCatalogItem with _$BadgeCatalogItem {
  const BadgeCatalogItem._();

  const factory BadgeCatalogItem({
    required String id,
    required String name,
    /// Nome do ícone Material (ver `badgeIconFor`).
    @Default('') String icon,
    @Default(0) int xpReward,
    @JsonKey(unknownEnumValue: BadgeCategory.unknown)
    @Default(BadgeCategory.unknown)
    BadgeCategory category,
    @Default('') String description,
  }) = _BadgeCatalogItem;

  factory BadgeCatalogItem.fromJson(Map<String, dynamic> json) =>
      _$BadgeCatalogItemFromJson(json);
}

/// Catálogo publicado pelo servidor em `config/badges`.
///
/// O app NÃO mantém mais uma cópia do catálogo nem a fórmula de nível: os dois
/// eram espelhos manuais que saíam de sincronia a cada badge novo.
@freezed
sealed class BadgeCatalog with _$BadgeCatalog {
  const BadgeCatalog._();

  const factory BadgeCatalog({
    @Default('') String version,
    @Default(<BadgeCatalogItem>[]) List<BadgeCatalogItem> badges,

    /// XP mínimo de cada nível: `levelThresholds[n - 1]` abre o nível `n`.
    @Default(<int>[]) List<int> levelThresholds,
  }) = _BadgeCatalog;

  factory BadgeCatalog.fromJson(Map<String, dynamic> json) =>
      _$BadgeCatalogFromJson(json);

  /// Badges da categoria, na ordem publicada.
  List<BadgeCatalogItem> ofCategory(BadgeCategory category) =>
      badges.where((badge) => badge.category == category).toList();

  /// Categorias que de fato têm badges, na ordem do enum.
  List<BadgeCategory> get categories => BadgeCategory.values
      .where((category) => badges.any((badge) => badge.category == category))
      .toList();

  /// XP acumulado que abre o nível informado (1 = 0 XP).
  int xpForLevel(int level) {
    if (levelThresholds.isEmpty || level <= 1) return 0;
    final index = level - 1;
    if (index >= levelThresholds.length) return levelThresholds.last;
    return levelThresholds[index];
  }

  /// Progresso dentro do nível atual, de 0 a 1.
  ///
  /// Sem tabela (catálogo ainda não publicado) devolve 0: é melhor uma barra
  /// vazia do que uma barra calculada com uma fórmula que o servidor pode ter
  /// mudado.
  double levelProgress(int level, int xp) {
    if (levelThresholds.isEmpty) return 0;
    final floor = xpForLevel(level);
    final ceiling = xpForLevel(level + 1);
    final span = ceiling - floor;
    if (span <= 0) return 1;
    return ((xp - floor) / span).clamp(0.0, 1.0);
  }

  /// XP já conquistado dentro do nível atual.
  int xpInLevel(int level, int xp) => (xp - xpForLevel(level)).clamp(0, xp);

  /// XP total que o nível atual exige para virar o próximo.
  int xpToNextLevel(int level) {
    final span = xpForLevel(level + 1) - xpForLevel(level);
    return span > 0 ? span : 0;
  }
}
