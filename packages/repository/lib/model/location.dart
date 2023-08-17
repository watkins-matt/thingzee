import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:repository/model/serializer_datetime.dart';

part 'location.g.dart';

@JsonSerializable(explicitToJson: true)
@immutable
class Location {
  final String upc;
  final String location;
  final double? quantity;

  @NullableDateTimeSerializer()
  final DateTime? created;

  @NullableDateTimeSerializer()
  final DateTime? updated;

  Location({
    required this.upc,
    required this.location,
    this.quantity,
    DateTime? created,
    DateTime? updated,
  })  : created = created ?? _defaultDateTime(updated),
        updated = updated ?? _defaultDateTime(created);

  factory Location.fromJson(Map<String, dynamic> json) => _$LocationFromJson(json);

  Location copyWith({
    String? upc,
    String? location,
    double? quantity,
    DateTime? created,
    DateTime? updated,
  }) {
    return Location(
      upc: upc ?? this.upc,
      location: location ?? this.location,
      quantity: quantity ?? this.quantity,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  bool equalTo(Location other) {
    return upc == other.upc &&
        location == other.location &&
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
      location: newerLocation.location.isNotEmpty ? newerLocation.location : location,
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
