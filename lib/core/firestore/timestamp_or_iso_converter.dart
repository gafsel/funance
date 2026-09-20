import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

/// Um instante que pode chegar como `Timestamp` OU como texto ISO.
///
/// O app grava data como STRING ISO — é o que as rules exigem e é o que o
/// `toJson` continua produzindo. Mas o mesmo campo tem dois produtores: o
/// servidor escreve `accounts/{id}.nextInvoice` com `Timestamp` nativo, e o
/// leitor de notificação copia o documento da conta INTEIRO para dentro de
/// `automatic_transactions/{id}.suggestedAccount` — com os `Timestamp` junto.
///
/// A leitura de `accounts` passa por `accountJsonFromFirestore`, que converte
/// os `Timestamp` antes do `fromJson`. A cópia embutida na pendência não passa
/// por lugar nenhum: ela vai direto para `AccountModel.fromJson`, e um
/// converter que só aceitava `String` derrubava o parse com
/// `type 'Timestamp' is not a subtype of type 'String' in type cast` — o
/// documento sumia da lista sem o dono jamais saber que ele existia.
///
/// Tolerar os dois tipos na LEITURA e gravar sempre ISO é o que faz a
/// serialização não mudar.
DateTime? dateTimeFromTimestampOrIso(Object? value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate().toLocal();
  if (value is DateTime) return value.toLocal();
  if (value is String) return DateTime.parse(value).toLocal();
  return null;
}

/// Instante obrigatório: `Timestamp` ou ISO na entrada, ISO na saída.
///
/// O instante é preservado, sem normalizar a hora: as bordas do ciclo de
/// fatura são 00:00 e 23:59:59.999 exatos e servem de limite de consulta.
class TimestampOrIsoConverter implements JsonConverter<DateTime, Object?> {
  const TimestampOrIsoConverter();

  @override
  DateTime fromJson(Object? json) {
    final DateTime? parsed = dateTimeFromTimestampOrIso(json);
    if (parsed == null) {
      // A mensagem diz o TIPO, não o valor: é o que falta para achar quem
      // gravou errado, e uma data de fatura não vai para log de erro.
      throw FormatException(
        'data esperada como Timestamp ou texto ISO, veio ${json.runtimeType}',
      );
    }
    return parsed;
  }

  @override
  Object toJson(DateTime date) => date.toIso8601String();
}

/// A versão opcional de [TimestampOrIsoConverter]: ausente vira `null`.
class TimestampOrIsoNullableConverter
    implements JsonConverter<DateTime?, Object?> {
  const TimestampOrIsoNullableConverter();

  @override
  DateTime? fromJson(Object? json) => dateTimeFromTimestampOrIso(json);

  @override
  Object? toJson(DateTime? date) => date?.toIso8601String();
}
