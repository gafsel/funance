import 'package:json_annotation/json_annotation.dart';

class DateTimeTwelvePmConverter implements JsonConverter<DateTime, String> {
  const DateTimeTwelvePmConverter();

  @override
  DateTime fromJson(String json) {
    final date = DateTime.parse(json).toLocal();
    return DateTime(date.year, date.month, date.day, 12);
  }

  @override
  String toJson(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day, 12);
    return normalizedDate.toIso8601String();
  }
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
  DateTime? fromJson(String? json) {
    if (json == null) return null;
    final date = DateTime.parse(json).toLocal();
    return DateTime(date.year, date.month, date.day, 12);
  }

  @override
  String? toJson(DateTime? date) {
    if (date == null) return null;
    final normalizedDate = DateTime(date.year, date.month, date.day, 12);
    return normalizedDate.toIso8601String();
  }
}
