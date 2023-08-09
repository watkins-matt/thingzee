import 'package:json_annotation/json_annotation.dart';

class DateTimeSerializer implements JsonConverter<DateTime, int> {
  const DateTimeSerializer();

  @override
  DateTime fromJson(int json) => DateTime.fromMillisecondsSinceEpoch(json);

  @override
  int toJson(DateTime dateTime) => dateTime.millisecondsSinceEpoch;
}

class NullableDateTimeSerializer implements JsonConverter<DateTime?, int> {
  const NullableDateTimeSerializer();

  @override
  DateTime? fromJson(int json) => json == 0 ? null : DateTime.fromMillisecondsSinceEpoch(json);

  @override
  int toJson(DateTime? dateTime) => dateTime != null ? dateTime.millisecondsSinceEpoch : 0;
}
