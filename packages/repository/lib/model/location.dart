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

  const Location({
    required this.upc,
    required this.location,
    this.quantity,
    this.created,
    this.updated,
  });

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

  Map<String, dynamic> toJson() => _$LocationToJson(this);
}
