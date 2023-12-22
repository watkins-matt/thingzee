import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

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

  const ItemIdentifier({
    this.type = '',
    this.value = '',
    this.uid = '',
  });

  factory ItemIdentifier.fromJson(Map<String, dynamic> json) => _$ItemIdentifierFromJson(json);

  ItemIdentifier copyWith({
    String? type,
    String? value,
    String? uid,
  }) {
    return ItemIdentifier(
      type: type ?? this.type,
      value: value ?? this.value,
      uid: uid ?? this.uid,
    );
  }

  Map<String, dynamic> toJson() => _$ItemIdentifierToJson(this);
}
