import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:repository/merge_generator.dart';
import 'package:repository/model/abstract/model.dart';
import 'package:repository/model/serializer_datetime.dart';
import 'package:util/extension/date_time.dart';

part 'location.g.dart';
part 'location.merge.dart';

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
@Mergeable()
class Location extends Model<Location> {
  @JsonKey(defaultValue: '')
  final String upc;

  @JsonKey(defaultValue: '')
  final String name;

  final double? quantity;

  Location({
    required this.upc,
    required this.name,
    this.quantity = 0,
    super.created,
    super.updated,
  });

  factory Location.fromJson(Map<String, dynamic> json) => _$LocationFromJson(json);

  @override
  String get uniqueKey {
    var path = normalizeLocation(name);
    if (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    return '$path/$upc';
  }

  @override
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

  @override
  bool equalTo(Location other) {
    return upc == other.upc && name == other.name && quantity == other.quantity;
  }

  @override
  Location merge(Location other) => _$mergeLocation(this, other);

  @override
  Map<String, dynamic> toJson() => _$LocationToJson(this);
}
