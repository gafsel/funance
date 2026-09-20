import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';

part 'automatic_transaction_model.freezed.dart';
part 'automatic_transaction_model.g.dart';

@freezed
sealed class AutomaticTransactionModel with _$AutomaticTransactionModel {
  /// `explicitToJson` porque o documento leva modelos ANINHADOS.
  ///
  /// Sem a anotação o `toJson` gerado devolve `instance.suggestedCategory`
  /// cru — um `CategoryModel` dentro do mapa que vai para o Firestore. O codec
  /// não conhece esse tipo e recusa a escrita INTEIRA com
  /// `Invalid argument: Instance of '_CategoryModel'`; era por isso que
  /// "ignorar" não ignorava nada. Só as pendências SEM sugestão sumiam da
  /// lista, e a exceção morria num `VoidCallback` sem chegar a lugar nenhum.
  ///
  /// É a mesma anotação que `OrderModel`, `InstallmentModel`, `InviteModel` e
  /// `CategoryPlanningModel` já usam pelo mesmo motivo: todo modelo deste
  /// projeto que aninha outro a carrega, e este tinha ficado de fora.
  ///
  /// `AccountModel` é uma união, e o `toJson` do freezed grava o `runtimeType`
  /// que o `fromJson` usa para escolher o construtor — a forma gravada não
  /// muda. O que NÃO é regravado é o `nextInvoice`: ver [suggestedAccount].
  @JsonSerializable(explicitToJson: true)
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
    CategoryModel? suggestedCategory,

    /// Cópia da conta que o leitor de notificação achou provável.
    ///
    /// É uma FOTOGRAFIA, e de propósito aparada: `nextInvoice` tem
    /// `includeToJson: false` na conta, então a primeira vez que o app
    /// regrava esta pendência a cópia da fatura some — e é assim que deve
    /// ser. A fonte da verdade da próxima fatura é `accounts/{id}`, que o
    /// servidor mantém; uma segunda cópia aqui só pode envelhecer e mentir.
    /// A tela lê a conta, nunca este resumo.
    AccountModel? suggestedAccount,
    @Default(false) bool isConsolidated,
    @Default(false) bool isIgnored,
    Map<String, dynamic>? metadata,
  }) = _AutomaticTransactionModel;

  factory AutomaticTransactionModel.fromJson(Map<String, dynamic> json) =>
      _$AutomaticTransactionModelFromJson(json);
}
