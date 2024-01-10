extension DateTimeExtensions on DateTime {
  /// Returns the newer (later) of two non-nullable DateTime values.
  DateTime newer(DateTime other) => isAfter(other) ? this : other;

  /// Returns the older (earlier) of two non-nullable DateTime values.
  DateTime older(DateTime other) => isBefore(other) ? this : other;
}

extension NullableDateTimeExtensions on DateTime? {
  /// Returns the newer (later) of two DateTime values, preferring the non-null value.
  /// If both are null, returns the current DateTime.
  DateTime newer(DateTime? other, {DateTime? defaultDateTime}) {
    if (this == null && other == null) return defaultDateTime ?? DateTime.now();
    if (this == null) return other!;
    if (other == null) return this!;

    return this!.isAfter(other) ? this! : other;
  }

  /// Returns the older (earlier) of two DateTime values, preferring the non-null value.
  /// If both are null, returns the current DateTime.
  DateTime older(DateTime? other, {DateTime? defaultDateTime}) {
    if (this == null && other == null) return defaultDateTime ?? DateTime.now();
    if (this == null) return other!;
    if (other == null) return this!;

    return this!.isBefore(other) ? this! : other;
  }
}
