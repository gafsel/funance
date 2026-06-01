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
