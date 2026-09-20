import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/features/workspace/domain/models/workspace_model.dart';

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

/// Público de uma conquista. Espelha `BadgeAudience` do backend.
enum BadgeAudience {
  @JsonValue('personal')
  personal,
  @JsonValue('business')
  business,
  @JsonValue('both')
  both;

  /// `true` quando a conquista faz sentido num cofre de [type].
  bool appliesTo(WorkspaceType type) =>
      this == both ||
      (this == personal && type == WorkspaceType.personal) ||
      (this == business && type == WorkspaceType.business);
}

@freezed
sealed class BadgeCatalogItem with _$BadgeCatalogItem {
  const BadgeCatalogItem._();

  const factory BadgeCatalogItem({
    required String id,

    /// Nome por idioma (`{pt: ..., en: ...}`). Use [nameIn].
    @JsonKey(fromJson: localizedText)
    @Default(<String, String>{})
    Map<String, String> name,

    /// Nome do ícone Material (ver `badgeIconFor`).
    @Default('') String icon,
    @Default(0) int xpReward,
    @JsonKey(unknownEnumValue: BadgeCategory.unknown)
    @Default(BadgeCategory.unknown)
    BadgeCategory category,

    /// Descrição por idioma. Use [descriptionIn].
    @JsonKey(fromJson: localizedText)
    @Default(<String, String>{})
    Map<String, String> description,

    /// Para qual tipo de cofre a conquista existe: `personal`, `business` ou
    /// `both`. O servidor materializa o campo em toda badge publicada, mas um
    /// catálogo mais antigo pode não trazê-lo — e aí a badge vale para os
    /// dois, que é o padrão do servidor.
    @JsonKey(unknownEnumValue: BadgeAudience.both)
    @Default(BadgeAudience.both)
    BadgeAudience audience,
  }) = _BadgeCatalogItem;

  factory BadgeCatalogItem.fromJson(Map<String, dynamic> json) =>
      _$BadgeCatalogItemFromJson(json);

  /// Nome no idioma pedido, com fallback para português.
  String nameIn(String locale) => _pick(name, locale);

  /// Descrição no idioma pedido, com fallback para português.
  String descriptionIn(String locale) => _pick(description, locale);

  static String _pick(Map<String, String> text, String locale) {
    if (text.isEmpty) return '';
    return text[locale] ??
        text[locale.split(RegExp('[_-]')).first] ??
        text['pt'] ??
        text.values.first;
  }
}

/// Uma forma de ganhar XP, publicada pelo servidor em
/// `config/badges.xpSources`.
///
/// O app não mantém uma tabela própria: quanto cada ação vale é regra do
/// servidor, e uma cópia aqui sairia de sincronia no primeiro ajuste de
/// balanceamento — exatamente o que aconteceu com o catálogo de badges.
@freezed
sealed class XpSource with _$XpSource {
  const XpSource._();

  const factory XpSource({
    required String id,

    /// Nome por idioma (`{pt: ..., en: ...}`). Use [nameIn].
    @JsonKey(fromJson: localizedText)
    @Default(<String, String>{})
    Map<String, String> name,
    @Default(0) int xp,

    /// Descrição por idioma. Use [descriptionIn].
    @JsonKey(fromJson: localizedText)
    @Default(<String, String>{})
    Map<String, String> description,
  }) = _XpSource;

  factory XpSource.fromJson(Map<String, dynamic> json) =>
      _$XpSourceFromJson(json);

  String nameIn(String locale) => BadgeCatalogItem._pick(name, locale);

  String descriptionIn(String locale) =>
      BadgeCatalogItem._pick(description, locale);
}

/// Aceita o texto do catálogo em dois formatos.
///
/// Mapa por locale é o formato atual. String pura é o formato ANTIGO, que fica
/// publicado até o cron republicar o catálogo depois do deploy — tratada como
/// português, que é o idioma em que ela foi escrita.
Map<String, String> localizedText(Object? raw) {
  if (raw is String) return {'pt': raw};
  if (raw is Map) {
    return {
      for (final entry in raw.entries)
        if (entry.key is String && entry.value is String)
          entry.key as String: entry.value as String,
    };
  }
  return const {};
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

    /// Como ganhar XP. Vazio enquanto o servidor não publicar a lista — a
    /// seção simplesmente não aparece, em vez de mostrar um título vazio.
    @Default(<XpSource>[]) List<XpSource> xpSources,
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

  /// O catálogo como ele deve aparecer num cofre de [type].
  ///
  /// A regra é assimétrica de propósito: a vitrine esconde o que **não foi
  /// conquistado** e não pertence ao tipo — não faz sentido uma empresa ver
  /// "Regra de Ouro" como meta a perseguir. Mas uma conquista já obtida
  /// nunca some, mesmo que o cofre tenha mudado de tipo depois: ela foi
  /// ganha, e apagá-la da estante seria negar o que aconteceu.
  BadgeCatalog forWorkspace(
    WorkspaceType type,
    Map<String, String> unlockedBadges,
  ) => copyWith(
    badges: badges
        .where(
          (badge) =>
              badge.audience.appliesTo(type) ||
              unlockedBadges.containsKey(badge.id),
        )
        .toList(),
  );

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
