import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:repository/model/serializer_datetime.dart';

part 'location.g.dart';

String convertLegacyPath(String location) {
  // Convert from "Kitchen: Fridge (Top)" to "/Kitchen/Fridge/Top/"
  if (location.contains(':')) {
    var parts = location.split(':');
    var mainLocation = parts[0].trim();
    var subLocations = parts[1].split('(');
    var firstSub = subLocations[0].trim();
    var secondSub = '';
    if (subLocations.length > 1) {
      secondSub = subLocations[1].replaceAll(')', '').trim();
    }
    location = '/$mainLocation/$firstSub/$secondSub/';
  } else {
    location = '/$location/';
  }
  return location;
}

String normalizeLocation(String location) {
  if (location.isEmpty) return '/'; // Root location is /

  // Check if location is in legacy format and convert if necessary
  if (location.contains(':') || location.contains('(')) {
    location = convertLegacyPath(location);
  }

  // Replace multiple consecutive slashes with a single slash
  location = location.replaceAll(RegExp(r'//+'), '/');

  // Ensure the path starts with a slash
  if (!location.startsWith('/')) {
    location = '/$location';
  }

  // Ensure the path ends with a slash
  if (!location.endsWith('/')) {
    location += '/';
  }

  String titleCase(value) {
    return value.isEmpty
        ? value
        : value.split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  // Convert to title case
  location = titleCase(location);

  return location;
}

String prettyPrintPath(String path) {
  final parts = path.split('/').where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) return '';

  final buffer = StringBuffer(parts[0]);
  for (int i = 1; i < parts.length; i++) {
    if (i == parts.length - 1) {
      buffer.write(' (${parts[i]})');
    } else {
      buffer.write(': ${parts[i]}');
    }
  }

  return buffer.toString();
}

@JsonSerializable(explicitToJson: true)
@immutable
class Location {
  @JsonKey(defaultValue: '')
  final String upc;

  @JsonKey(defaultValue: '')
  final String name;

  @JsonKey(defaultValue: 0.0)
  final double? quantity;

  @NullableDateTimeSerializer()
  final DateTime? created;

  @NullableDateTimeSerializer()
  final DateTime? updated;

  Location({
    required this.upc,
    required this.name,
    this.quantity,
    DateTime? created,
    DateTime? updated,
  })  :
        // Initialize 'created' and 'updated' date-times.
        // If 'created' is not provided, it defaults to the value of 'updated' if that was provided,
        // otherwise to the current time. If 'updated' is not provided, it defaults to the value of 'created',
        // ensuring both fields are synchronized and non-null. If both are provided, their values are retained.
        created = created ?? _defaultDateTime(updated),
        updated = updated ?? _defaultDateTime(created);

  factory Location.fromJson(Map<String, dynamic> json) => _$LocationFromJson(json);

  Location copyWith({
    String? upc,
    String? name,
    double? quantity,
    DateTime? created,
    DateTime? updated,
  }) {
    return Location(
      upc: upc ?? this.upc,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  bool equalTo(Location other) {
    return upc == other.upc &&
        name == other.name &&
        quantity == other.quantity &&
        created?.millisecondsSinceEpoch == other.created?.millisecondsSinceEpoch &&
        updated?.millisecondsSinceEpoch == other.updated?.millisecondsSinceEpoch;
  }

  Location merge(Location other) {
    final firstUpdate = updated ?? DateTime.fromMillisecondsSinceEpoch(0);
    final secondUpdate = other.updated ?? DateTime.fromMillisecondsSinceEpoch(0);
    final newerLocation = secondUpdate.isAfter(firstUpdate) ? other : this;

    return Location(
      upc: newerLocation.upc.isNotEmpty ? newerLocation.upc : upc,
      name: newerLocation.name.isNotEmpty ? newerLocation.name : name,
      quantity: newerLocation.quantity ?? quantity,
      created: newerLocation.created ?? created,
      updated: newerLocation.updated ?? updated,
    );
  }

  Map<String, dynamic> toJson() => _$LocationToJson(this);

  /// This method is a helper method to ensure that
  /// created and updated can be initialized to equivalent values if
  /// one or both are null.
  static DateTime _defaultDateTime(DateTime? dateTime) => dateTime ?? DateTime.now();
}
