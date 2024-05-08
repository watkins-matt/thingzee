// ignore_for_file: avoid_unused_constructor_parameters

import 'package:meta/meta.dart';
import 'package:repository/model/serializer_datetime.dart';

abstract class JsonConvertible<T> {
  factory JsonConvertible.fromJson(Map<String, dynamic> json) => throw UnimplementedError();
  Map<String, dynamic> toJson();
}

@immutable
abstract class Model<T> implements JsonConvertible<T> {
  @DateTimeSerializer()
  final DateTime created;

  @DateTimeSerializer()
  final DateTime updated;

  Model({DateTime? created, DateTime? updated})
      // Initialize 'created' and 'updated' date-times.
      // If 'created' is not provided, it defaults to the value of 'updated' if that was provided,
      // otherwise to the current time. If 'updated' is not provided, it defaults to the value of 'created',
      // ensuring both fields are synchronized and non-null. If both are provided, their values are retained.
      : created = _defaultDateTime(created, updated),
        updated = _defaultDateTime(updated, created);

  bool get isValid => uniqueKey.isNotEmpty;
  String get uniqueKey;

  T copyWith({DateTime? created, DateTime? updated});
  bool equalTo(T other);
  T merge(T other);

  /// This method is a helper method to ensure that
  /// created and updated can be initialized to equivalent values if
  /// one or both are null.
  static DateTime _defaultDateTime(DateTime? primary, DateTime? secondary) {
    return primary ?? secondary ?? DateTime.now();
  }
}

/// Annotation for fields that should not be persisted into
/// generated classes.
class Transient {
  const Transient();
}
