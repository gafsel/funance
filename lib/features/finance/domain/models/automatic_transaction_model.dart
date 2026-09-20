import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';

part 'automatic_transaction_model.freezed.dart';
part 'automatic_transaction_model.g.dart';

@freezed
sealed class AutomaticTransactionModel with _$AutomaticTransactionModel {
  const factory AutomaticTransactionModel({
    required String id,
    required String description,
    required double amount,
    required DateTime date,
    required OrderType type,
    String? originNotificationId, // Para evitar duplicidade
    String? packageName, // App que originou a notificação
    String? accountId,
    String? categoryId,
    @JsonKey(toJson: suggestedCategoryToJson)
    CategoryModel? suggestedCategory,
    @JsonKey(toJson: suggestedAccountToJson) AccountModel? suggestedAccount,
    @Default(false) bool isConsolidated,
    @Default(false) bool isIgnored,
    Map<String, dynamic>? metadata,
  }) = _AutomaticTransactionModel;

  factory AutomaticTransactionModel.fromJson(Map<String, dynamic> json) =>
      _$AutomaticTransactionModelFromJson(json);
}

/// O MAPA da categoria sugerida, e não o objeto.
///
/// Sem isto o `toJson` gerado devolve `instance.suggestedCategory` cru — um
/// `CategoryModel` dentro do mapa que vai para o Firestore. O codec do
/// `cloud_firestore` não conhece esse tipo e recusa a escrita INTEIRA com um
/// `ArgumentError`; era por isso que "ignorar" não ignorava nada: toda
/// pendência com sugestão falhava, e só as sem sugestão sumiam da lista.
///
/// `json_serializable` só chamaria `.toJson()` sozinho com `explicit_to_json`,
/// que não está ligado no projeto — e ligá-lo mudaria a serialização de todos
/// os modelos de uma vez. Aqui o conserto é onde o defeito está.
Map<String, dynamic>? suggestedCategoryToJson(CategoryModel? category) =>
    category?.toJson();

/// O MAPA da conta sugerida. Mesma razão de [suggestedCategoryToJson].
///
/// `AccountModel` é uma união: o `toJson` do freezed já grava o `runtimeType`
/// que o `fromJson` usa para escolher o construtor, então a forma gravada não
/// muda. O que some é o `nextInvoice` — `includeToJson: false` na conta, por
/// ser dado do servidor — e as sobras legadas (`initial_balance_date`,
/// `*Cents`) que o documento tinha copiado da conta.
Map<String, dynamic>? suggestedAccountToJson(AccountModel? account) =>
    account?.toJson();
