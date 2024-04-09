import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:repository/merge_generator.dart';
import 'package:repository/model/abstract/model.dart';
import 'package:repository/model/serializer_datetime.dart';
import 'package:util/extension/date_time.dart';

part 'identifier.g.dart';
part 'identifier.merge.dart';

@JsonSerializable(explicitToJson: true)
@immutable
@Mergeable()
class Identifier extends Model<Identifier> {
  final String type; // The type of identifier, e.g. UPC, EAN, ISBN, ASIN, etc.
  final String value; // The value of the identifier, e.g. the barcode number
  final String uid; // The global uid of the item that this identifier maps to

  Identifier({
    this.type = '',
    this.value = '',
    this.uid = '',
    super.created,
    super.updated,
  });

  factory Identifier.fromJson(Map<String, dynamic> json) => _$IdentifierFromJson(json);

  /// For our unique id, we use $type-$value. For any given type, for
  /// example UPC, the value should always be unique. However, the same
  /// value can be (in theory) used for different types, so using both together
  /// gets us a unique id.
  @override
  String get id => '$type-$value';

  @override
  Identifier copyWith({
    String? type,
    String? value,
    String? uid,
    DateTime? created,
    DateTime? updated,
  }) {
    return Identifier(
      type: type ?? this.type,
      value: value ?? this.value,
      uid: uid ?? this.uid,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  @override
  bool equalTo(Identifier other) {
    return type == other.type && value == other.value && uid == other.uid;
  }

  @override
  Identifier merge(Identifier other) => _$mergeIdentifier(this, other);

  @override
  Map<String, dynamic> toJson() => _$IdentifierToJson(this);
}
