import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:repository/model/serializer_datetime.dart';

part 'identifier.g.dart';

@JsonSerializable(explicitToJson: true)
@immutable
class ItemIdentifier {
  @JsonKey(defaultValue: '')
  final String type; // The type of identifier, e.g. UPC, EAN, ISBN, ASIN, etc.

  @JsonKey(defaultValue: '')
  final String value; // The value of the identifier, e.g. the barcode number

  @JsonKey(defaultValue: '')
  final String uid; // The global uid of the item that this identifier maps to

  @NullableDateTimeSerializer()
  final DateTime? created;

  @NullableDateTimeSerializer()
  final DateTime? updated;

  ItemIdentifier({
    this.type = '',
    this.value = '',
    this.uid = '',
    DateTime? created,
    DateTime? updated,
  })  :
        // Initialize 'created' and 'updated' date-times.
        // If 'created' is not provided, it defaults to the value of 'updated' if that was provided,
        // otherwise to the current time. If 'updated' is not provided, it defaults to the value of 'created',
        // ensuring both fields are synchronized and non-null. If both are provided, their values are retained.
        created = created ?? _defaultDateTime(updated),
        updated = updated ?? _defaultDateTime(created);

  factory ItemIdentifier.fromJson(Map<String, dynamic> json) => _$ItemIdentifierFromJson(json);

  ItemIdentifier copyWith({
    String? type,
    String? value,
    String? uid,
    DateTime? created,
    DateTime? updated,
  }) {
    return ItemIdentifier(
      type: type ?? this.type,
      value: value ?? this.value,
      uid: uid ?? this.uid,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  Map<String, dynamic> toJson() => _$ItemIdentifierToJson(this);

  /// This method is a helper method to ensure that
  /// created and updated can be initialized to equivalent values if
  /// one or both are null.
  static DateTime _defaultDateTime(DateTime? dateTime) => dateTime ?? DateTime.now();
}
