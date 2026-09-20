import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/core/firestore/timestamp_or_iso_converter.dart';
import 'package:funances/core/utils/date_time_converter.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';

part 'account_model.freezed.dart';

part 'account_model.g.dart';

enum AccountType {
  @JsonValue('checking')
  checking,
  @JsonValue('investment')
  investment,
  @JsonValue('creditCard')
  creditCard,
  @JsonValue('debt')
  debt,
}

enum BankLogo {
  @JsonValue('none')
  none,
  @JsonValue('nubank')
  nubank,
  @JsonValue('inter')
  inter,
  @JsonValue('itau')
  itau,
  @JsonValue('bradesco')
  bradesco,
  @JsonValue('santander')
  santander,
  @JsonValue('bb')
  bb,
  @JsonValue('caixa')
  caixa,
  @JsonValue('c6')
  c6,
  @JsonValue('xp')
  xp,
  @JsonValue('btg')
  btg,
  @JsonValue('visa')
  visa,
  @JsonValue('mastercard')
  mastercard,
  @JsonValue('elo')
  elo,
  @JsonValue('amex')
  amex,
}

extension BankLogoExtension on BankLogo {
  String? get defaultColor {
    return switch (this) {
      BankLogo.none => null,
      BankLogo.nubank => '#8A05BE',
      BankLogo.inter => '#FF7A00',
      BankLogo.itau => '#EC7000',
      BankLogo.bradesco => '#CC092F',
      BankLogo.santander => '#EC0000',
      BankLogo.bb => '#FCF800',
      BankLogo.caixa => '#005CA5',
      BankLogo.c6 => '#212121',
      BankLogo.xp => '#000000',
      BankLogo.btg => '#00253E',
      BankLogo.visa => '#1A1F71',
      BankLogo.mastercard => '#EB001B',
      BankLogo.elo => '#00A4E0',
      BankLogo.amex => '#0070CD',
    };
  }
}

/// Resumo da PRÓXIMA fatura do cartão, escrito pelo servidor em
/// `accounts/{id}.nextInvoice` (F1.8).
///
/// O app **lê** vencimento, fechamento e janela do ciclo em vez de calculá-los.
/// Havia duas implementações da mesma regra — uma em TypeScript e uma cópia
/// Dart — e elas divergiam no clamp do dia; como o id da order de fatura deriva
/// da data, cliente e servidor podiam apontar para faturas diferentes. A cópia
/// Dart deixou de existir.
///
/// `includeToJson: false` no campo da conta: as security rules negam o envio
/// deste objeto, e um formulário que serialize a conta inteira seria rejeitado.
///
/// As datas entram por [TimestampOrIsoConverter] porque o mesmo objeto chega
/// de dois lugares: normalizado por `accountJsonFromFirestore` (texto ISO) e
/// copiado CRU para dentro de `automatic_transactions.suggestedAccount`, com
/// os `Timestamp` do servidor. A saída continua sendo ISO.
@freezed
sealed class NextInvoice with _$NextInvoice {
  const NextInvoice._();

  const factory NextInvoice({
    /// Vencimento da fatura.
    @TimestampOrIsoConverter() required DateTime dueDate,

    /// Fechamento que gerou esta fatura.
    @TimestampOrIsoConverter() required DateTime closingDate,

    /// Primeira compra que pertence a esta fatura (inclusive).
    @TimestampOrIsoConverter() required DateTime cycleStart,

    /// Última compra que pertence a esta fatura (inclusive).
    @TimestampOrIsoConverter() required DateTime cycleEnd,

    /// Valor em aberto. Zero quando o ciclo ainda não tem compra nenhuma.
    @Default(0.0) double amount,

    /// Id da order de fatura (`invoice-{accountId}-{YYYY-MM-DD}`).
    @Default('') String orderId,

    /// Parcela da fatura, ou `null` enquanto a fatura não existe de fato.
    String? installmentId,

    @Default(InstallmentStatus.pending) InstallmentStatus status,

    @TimestampOrIsoNullableConverter() DateTime? updatedAt,
  }) = _NextInvoice;

  /// `true` enquanto o ciclo está aberto e ainda não acumulou nada — o app
  /// mostra o período em vez de um valor que pareceria definitivo.
  bool get isEmpty => installmentId == null && amount == 0;

  factory NextInvoice.fromJson(Map<String, dynamic> json) =>
      _$NextInvoiceFromJson(json);
}

@freezed
sealed class AccountModel with _$AccountModel {
  const AccountModel._();

  const factory AccountModel.checking({
    required String id,
    required String name,
    required String icon,
    required String color,
    @Default(false) bool isDeleted,
    @Default(0.0) double initialBalance,
    @DateTimeTwelvePmConverter() required DateTime initialBalanceDate,
    @Default(BankLogo.none) BankLogo bankLogo,
    @Default([]) List<String> ownerIds,
  }) = CheckingAccount;

  const factory AccountModel.investment({
    required String id,
    required String name,
    required String icon,
    required String color,
    @Default(false) bool isDeleted,
    @Default(0.0) double initialBalance,
    @DateTimeTwelvePmConverter() required DateTime initialBalanceDate,
    required double interestRate,
    @Default(BankLogo.none) BankLogo bankLogo,
    @Default([]) List<String> ownerIds,
  }) = InvestmentAccount;

  const factory AccountModel.creditCard({
    required String id,
    required String name,
    required String icon,
    required String color,
    @Default(false) bool isDeleted,
    @Default(0.0) double initialBalance,
    @DateTimeTwelvePmConverter() required DateTime initialBalanceDate,
    required double limit,
    required int dueDay,
    required int closingDay,
    @Default(BankLogo.none) BankLogo bankLogo,
    @Default([]) List<String> ownerIds,
    // Somente leitura: escrito pelo servidor e negado ao cliente pelas rules.
    @JsonKey(includeToJson: false, fromJson: nextInvoiceFromJson)
    NextInvoice? nextInvoice,
  }) = CreditCardAccount;

  const factory AccountModel.debt({
    required String id,
    required String name,
    required String icon,
    required String color,
    @Default(false) bool isDeleted,
    @Default(0.0) double initialBalance,
    @DateTimeTwelvePmConverter() required DateTime initialBalanceDate,
    required double interestRate,
    @Default(BankLogo.none) BankLogo bankLogo,
    @Default([]) List<String> ownerIds,
  }) = DebtAccount;

  AccountType get type => map(
    checking: (_) => AccountType.checking,
    investment: (_) => AccountType.investment,
    creditCard: (_) => AccountType.creditCard,
    debt: (_) => AccountType.debt,
  );

  factory AccountModel.fromJson(Map<String, dynamic> json) =>
      _$AccountModelFromJson(json);
}

/// O resumo da fatura, ou `null` quando ele não dá para ser lido inteiro.
///
/// A regra "fatura pela metade é DESCARTADA" vivia em
/// `accountJsonFromFirestore`, na camada de dados — e por isso valia só para
/// quem lia a coleção `accounts`. A cópia que o leitor de notificação embute
/// em `automatic_transactions.suggestedAccount` não passa por lá: um resumo
/// sem `dueDate` estourava no converter e derrubava a conta, a pendência e,
/// com ela, o documento inteiro — exatamente o defeito que esta rodada veio
/// consertar, de volta por outra porta.
///
/// Aqui a regra é uma só e vale para os dois caminhos. Descartar é o
/// comportamento honesto: a tela mostra "calculando" em vez de uma fatura com
/// borda pela metade, e a fonte da verdade (`accounts/{id}`) segue intacta.
NextInvoice? nextInvoiceFromJson(Object? raw) {
  if (raw is! Map) return null;

  try {
    return NextInvoice.fromJson({
      for (final entry in raw.entries) entry.key.toString(): entry.value,
    });
  } catch (_) {
    // Silencioso de propósito: não é erro do app nem do usuário, é um
    // documento gravado por uma versão anterior do servidor. Quem precisa
    // aparecer é a pendência, e ela aparece.
    return null;
  }
}

@freezed
sealed class AccountBalanceModel with _$AccountBalanceModel {
  const AccountBalanceModel._();

  const factory AccountBalanceModel({
    required String id, // Date string YYYY-MM-DD
    required double balance,
    required DateTime updatedAt,
  }) = _AccountBalanceModel;

  factory AccountBalanceModel.zero({DateTime? date}) => AccountBalanceModel(
    id: "",
    balance: 0,
    updatedAt: date ?? DateTime.now(),
  );

  factory AccountBalanceModel.fromJson(Map<String, dynamic> json) =>
      _$AccountBalanceModelFromJson(json);
}

@freezed
sealed class AccountDocumentAnalysisResult
    with _$AccountDocumentAnalysisResult {
  /// `explicitToJson`: `account` e `orders` são modelos aninhados, e sem a
  /// anotação eles vão como OBJETO no mapa. Ver
  /// `AutomaticTransactionModel` — é o mesmo defeito, aqui ainda adormecido
  /// porque este resultado só chega de uma callable e nunca é gravado.
  @JsonSerializable(explicitToJson: true)
  factory AccountDocumentAnalysisResult({
    required AccountModel account,
    @Default([]) List<OrderModel> orders,
  }) = _AccountDocumentAnalysisResult;

  const AccountDocumentAnalysisResult._();

  factory AccountDocumentAnalysisResult.fromJson(Map<String, dynamic> json) =>
      _$AccountDocumentAnalysisResultFromJson(json);
}
