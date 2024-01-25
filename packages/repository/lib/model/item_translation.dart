import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:repository/extension/date_time.dart';
import 'package:repository/merge_generator.dart';
import 'package:repository/model/abstract/model.dart';
import 'package:repository/model/serializer_datetime.dart';

part 'item_translation.g.dart';
part 'item_translation.merge.dart';

@JsonSerializable(explicitToJson: true)
@immutable
@Mergeable()
class ItemTranslation extends Model<ItemTranslation> {
  final String upc; // generator:unique
  final String languageCode;
  final String name;
  final String variety;
  final String unitName;
  final String unitPlural;
  final String type;

  ItemTranslation({
    this.upc = '', // generator:unique
    this.languageCode = 'en',
    this.name = '',
    this.variety = '',
    this.unitName = '',
    this.unitPlural = '',
    this.type = '',
    super.created,
    super.updated,
  });

  factory ItemTranslation.fromJson(Map<String, dynamic> json) => _$ItemTranslationFromJson(json);

  @override
  String get id => upc;

  @override
  ItemTranslation copyWith({
    String? upc,
    String? languageCode,
    String? name,
    String? variety,
    String? unitName,
    String? unitPlural,
    String? type,
    DateTime? created,
    DateTime? updated,
  }) {
    return ItemTranslation(
      upc: upc ?? this.upc,
      languageCode: languageCode ?? this.languageCode,
      name: name ?? this.name,
      variety: variety ?? this.variety,
      unitName: unitName ?? this.unitName,
      unitPlural: unitPlural ?? this.unitPlural,
      type: type ?? this.type,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  @override
  bool equalTo(ItemTranslation other) {
    if (identical(this, other)) return true;

    return other.upc == upc &&
        other.languageCode == languageCode &&
        other.name == name &&
        other.variety == variety &&
        other.unitName == unitName &&
        other.unitPlural == unitPlural &&
        other.type == type;
  }

  @override
  ItemTranslation merge(ItemTranslation other) => _$mergeItemTranslation(this, other);

  @override
  Map<String, dynamic> toJson() => _$ItemTranslationToJson(this);
}
