import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/l10n/app_localizations.dart';

/// O texto que aparece quando o dado não trouxe nome.
///
/// A camada de dados não inventa mais texto: o mapper devolve string vazia
/// quando a IA (ou um documento antigo) não mandou nome, descrição ou
/// categoria. Escrever "Sem Categoria" lá dentro significava gravar português
/// num modelo — e, no caminho do onboarding, gravar português no Firestore de
/// quem usa o app em inglês. Quem escolhe a palavra é a tela.
String displayOr(String? value, String fallback) {
  final trimmed = value?.trim();
  return (trimmed == null || trimmed.isEmpty) ? fallback : trimmed;
}

extension CategoryDisplayName on CategoryModel {
  /// Nome da categoria na tela, incluindo a categoria sintética "Outros" que
  /// os agrupamentos criam (ela não existe no Firestore e por isso não tem
  /// nome traduzível guardado em lugar nenhum).
  String displayName(AppLocalizations l10n) {
    if (id == CategoryModel.othersId) return l10n.categoryOthers;
    return displayOr(name, l10n.noCategory);
  }
}

extension AccountDisplayName on AccountModel {
  String displayName(AppLocalizations l10n) =>
      displayOr(name, l10n.unnamedAccount);
}
