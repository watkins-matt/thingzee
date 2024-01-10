// ignore_for_file: avoid_unused_constructor_parameters

import 'package:meta/meta.dart';
import 'package:repository/model/serializer_datetime.dart';

abstract class JsonConvertible<T> {
  factory JsonConvertible.fromJson(Map<String, dynamic> json) => throw UnimplementedError();
  Map<String, dynamic> toJson();
}

@immutable
abstract class Model<T> implements JsonConvertible<T> {
  @NullableDateTimeSerializer()
  final DateTime? created;

  @NullableDateTimeSerializer()
  final DateTime? updated;

  Model({DateTime? created, DateTime? updated})
      : created = _defaultDateTime(created, updated),
        updated = _defaultDateTime(updated, created);

  String get id;

  bool equalTo(T other);
  T merge(T other);

  static DateTime _defaultDateTime(DateTime? primary, DateTime? secondary) {
    return primary ?? secondary ?? DateTime.now();
  }
}
