import 'package:json_annotation/json_annotation.dart';

/// O dia, ao meio-dia — a ÚNICA definição de "data de calendário" do app.
///
/// Vencimento, pagamento e competência são datas, não instantes: guardá-las a
/// 00:00 faz qualquer conversão de fuso para oeste escorregar para o dia
/// anterior, e a parcela do dia 1º aparecer em julho. O meio-dia é a folga de
/// doze horas para cada lado que impede isso.
///
/// Esta função existe para que a regra não seja reescrita em nenhum outro
/// lugar: os converters abaixo e o `referenceDate` do lançamento chamam ela.
DateTime atNoon(DateTime date) =>
    DateTime(date.year, date.month, date.day, 12);

class DateTimeTwelvePmConverter implements JsonConverter<DateTime, String> {
  const DateTimeTwelvePmConverter();

  @override
  DateTime fromJson(String json) => atNoon(DateTime.parse(json).toLocal());

  @override
  String toJson(DateTime date) => atNoon(date).toIso8601String();
}

/// Converte um instante ISO preservando o INSTANTE, só trazendo-o para o fuso
/// local.
///
/// [DateTimeTwelvePmConverter] serve para data de calendário (vencimento,
/// competência): ele joga a hora para meio-dia justamente para o dia não
/// escorregar. As bordas do ciclo de fatura são o oposto — 00:00 e 23:59:59.999
/// exatos, calculados pelo servidor e usados como limite de consulta. Normalizar
/// a hora aqui mudaria o intervalo e faria compras entrarem ou saírem da fatura.
class DateTimeIsoConverter implements JsonConverter<DateTime, String> {
  const DateTimeIsoConverter();

  @override
  DateTime fromJson(String json) => DateTime.parse(json).toLocal();

  @override
  String toJson(DateTime date) => date.toIso8601String();
}

class DateTimeIsoNullableConverter implements JsonConverter<DateTime?, String?> {
  const DateTimeIsoNullableConverter();

  @override
  DateTime? fromJson(String? json) =>
      json == null ? null : DateTime.parse(json).toLocal();

  @override
  String? toJson(DateTime? date) => date?.toIso8601String();
}

class DateTimeTwelvePmNullableConverter implements JsonConverter<DateTime?, String?> {
  const DateTimeTwelvePmNullableConverter();

  @override
  DateTime? fromJson(String? json) =>
      json == null ? null : atNoon(DateTime.parse(json).toLocal());

  @override
  String? toJson(DateTime? date) =>
      date == null ? null : atNoon(date).toIso8601String();
}
