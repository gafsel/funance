import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/domain/models/virtual_category.dart';
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

    // As categorias de SISTEMA são semeadas pelo backend com o nome em
    // português (`category.model.ts:49,59,69,79` e `:39`), no Firestore de
    // todo mundo. O fallback de `displayOr` nunca pegava, porque `name` não
    // é vazio: quem usa o app em inglês lia "Empréstimo/Dívidas" no meio de
    // uma tela em inglês. Resolver por id é o mesmo caminho de `others`.
    final virtual = VirtualCategory.byId(id);
    if (virtual != null) {
      return switch (virtual.accountType) {
        AccountType.debt => l10n.categoryVirtualDebt,
        _ => l10n.categoryVirtualInvestment,
      };
    }

    if (id == VirtualCategory.initialBalanceId) {
      return l10n.categoryInitialBalance;
    }

    return displayOr(name, l10n.noCategory);
  }
}

extension AccountDisplayName on AccountModel {
  String displayName(AppLocalizations l10n) =>
      displayOr(name, l10n.unnamedAccount);
}
