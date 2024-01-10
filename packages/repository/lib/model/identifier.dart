import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:repository/model/abstract/model.dart';
import 'package:repository/model/serializer_datetime.dart';

part 'identifier.g.dart';

@JsonSerializable(explicitToJson: true)
@immutable
class ItemIdentifier extends Model<ItemIdentifier> {
  @JsonKey(defaultValue: '')
  final String type; // The type of identifier, e.g. UPC, EAN, ISBN, ASIN, etc.

  @JsonKey(defaultValue: '')
  final String value; // The value of the identifier, e.g. the barcode number

  @JsonKey(defaultValue: '')
  final String uid; // The global uid of the item that this identifier maps to

  ItemIdentifier({
    this.type = '',
    this.value = '',
    this.uid = '',
    super.created,
    super.updated,
  });

  factory ItemIdentifier.fromJson(Map<String, dynamic> json) => _$ItemIdentifierFromJson(json);

  @override
  String get id => '$type:$value';

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

  @override
  bool equalTo(ItemIdentifier other) {
    return type == other.type && value == other.value && uid == other.uid;
  }

  @override
  ItemIdentifier merge(ItemIdentifier other) {
    // Determine the older 'created' date, considering null values.
    DateTime? olderCreatedDate;
    if (created == null) {
      olderCreatedDate = other.created;
    } else if (other.created == null) {
      olderCreatedDate = created;
    } else {
      olderCreatedDate = created!.isBefore(other.created!) ? created : other.created;
    }

    // Determine the newer 'updated' date.
    final newerUpdatedDate = updated == null
        ? other.updated
        : (other.updated == null
            ? updated
            : (updated!.isAfter(other.updated!) ? updated : other.updated));

    // Merge the fields.
    return ItemIdentifier(
      type: other.type.isNotEmpty ? other.type : type,
      value: other.value.isNotEmpty ? other.value : value,
      uid: other.uid.isNotEmpty ? other.uid : uid,
      created: olderCreatedDate,
      updated: newerUpdatedDate,
    );
  }

  @override
  Map<String, dynamic> toJson() => _$ItemIdentifierToJson(this);
}
