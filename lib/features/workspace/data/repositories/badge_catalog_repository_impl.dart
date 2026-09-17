import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/badge_catalog_model.dart';
import '../../domain/repositories/badge_catalog_repository.dart';

/// Catálogo de conquistas publicado pelo servidor.
///
/// O documento é do PROJETO (não do workspace): as rules o deixam legível por
/// qualquer usuário autenticado e negam a escrita. Ver `functions/README.md`,
/// seção "Catálogo de badges (`config/badges`)".
class BadgeCatalogRepositoryImpl implements IBadgeCatalogRepository {
  BadgeCatalogRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<BadgeCatalog?> watchCatalog() {
    return _firestore.doc('config/badges').snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;

      return BadgeCatalog(
        version: data['version'] as String? ?? '',
        // Uma entrada malformada é descartada, não derruba o catálogo inteiro:
        // a vitrine com 66 badges é melhor do que a tela de erro por causa de
        // um documento que alguém publicou torto.
        badges: [
          for (final raw in (data['badges'] as List<dynamic>? ?? const []))
            if (raw is Map) ?_tryParse(raw),
        ],
        levelThresholds: [
          for (final raw
              in (data['levelThresholds'] as List<dynamic>? ?? const []))
            if (raw is num) raw.toInt(),
        ],
        // Mesma tolerância dos badges: uma fonte de XP malformada é
        // descartada sozinha, sem derrubar a vitrine inteira.
        xpSources: [
          for (final raw in (data['xpSources'] as List<dynamic>? ?? const []))
            if (raw is Map) ?_tryParseXpSource(raw),
        ],
      );
    });
  }
}

BadgeCatalogItem? _tryParse(Map<dynamic, dynamic> raw) {
  try {
    return BadgeCatalogItem.fromJson(Map<String, dynamic>.from(raw));
  } catch (_) {
    return null;
  }
}

XpSource? _tryParseXpSource(Map<dynamic, dynamic> raw) {
  try {
    return XpSource.fromJson(Map<String, dynamic>.from(raw));
  } catch (_) {
    return null;
  }
}
