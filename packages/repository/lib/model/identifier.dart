import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:repository/extension/date_time.dart';
import 'package:repository/merge_generator.dart';
import 'package:repository/model/abstract/model.dart';
import 'package:repository/model/serializer_datetime.dart';

part 'identifier.g.dart';
part 'identifier.merge.dart';

@JsonSerializable(explicitToJson: true)
@immutable
@Mergeable()
class ItemIdentifier extends Model<ItemIdentifier> {
  final String type; // The type of identifier, e.g. UPC, EAN, ISBN, ASIN, etc.
  final String value; // The value of the identifier, e.g. the barcode number
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

  @override
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
  ItemIdentifier merge(ItemIdentifier other) => _$mergeItemIdentifier(this, other);

  @override
  Map<String, dynamic> toJson() => _$ItemIdentifierToJson(this);
}
