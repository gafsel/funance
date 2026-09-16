import '../models/badge_catalog_model.dart';

abstract class IBadgeCatalogRepository {
  /// Catálogo público de conquistas (`config/badges`).
  ///
  /// Emite `null` enquanto o documento não existir — é o estado normal antes do
  /// primeiro publish do servidor, e a tela mostra "catálogo indisponível" em
  /// vez de quebrar.
  Stream<BadgeCatalog?> watchCatalog();
}
