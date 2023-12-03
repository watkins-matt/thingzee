import 'package:json_annotation/json_annotation.dart';
import 'package:repository/merge_generator.dart';
import 'package:repository/model/serializer_datetime.dart';

part 'item.g.dart';
part 'item.merge.dart';

@JsonSerializable(explicitToJson: true)
@Mergeable()
class Item implements Comparable<Item> {
  @JsonKey(defaultValue: '')
  String upc = ''; // generator:unique

  @JsonKey(defaultValue: '')
  String id = '';

  @JsonKey(defaultValue: '')
  String name = '';

  @JsonKey(defaultValue: '')
  String variety = '';

  @JsonKey(defaultValue: '')
  String category = '';

  @JsonKey(defaultValue: '')
  String type = ''; // Type of the item, example: Cereal, Milk, Tomato Sauce

  @JsonKey(defaultValue: '')
  String typeId = '';

  // Unit information:
  @JsonKey(defaultValue: 1)
  int unitCount = 1; // How many units are part of this item, e.g. 12 bottles

  @JsonKey(defaultValue: '')
  String unitName = ''; // What is the name of the unit, e.g. bottle

  @JsonKey(defaultValue: '')
  String unitPlural = ''; // What is the plural of the unit, e.g. bottles

  @JsonKey(defaultValue: '')
  String imageUrl = '';

  @JsonKey(defaultValue: true)
  bool consumable = true;

  @JsonKey(defaultValue: 'en')
  String languageCode = 'en';

  @NullableDateTimeSerializer()
  DateTime? lastUpdate;

  Item();
  factory Item.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('typeId')) {
      json['typeId'] = '';
    }

    return _$ItemFromJson(json);
  }

  @override
  int compareTo(Item other) {
    return name.compareTo(other.name);
  }

  bool equalTo(Item other) =>
      identical(this, other) ||
      upc == other.upc &&
          id == other.id &&
          name == other.name &&
          variety == other.variety &&
          category == other.category &&
          type == other.type &&
          typeId == other.typeId &&
          unitCount == other.unitCount &&
          unitName == other.unitName &&
          unitPlural == other.unitPlural &&
          imageUrl == other.imageUrl &&
          consumable == other.consumable &&
          languageCode == other.languageCode &&
          lastUpdate == other.lastUpdate;

  Item merge(Item other) => _$mergeItem(this, other);
  Map<String, dynamic> toJson() => _$ItemToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ItemTranslation {
  String upc = ''; // generator:unique
  String languageCode = 'en';
  String name = '';
  String variety = '';
  String unitName = '';
  String unitPlural = '';
  String type = '';

  ItemTranslation();
  factory ItemTranslation.fromJson(Map<String, dynamic> json) => _$ItemTranslationFromJson(json);
  Map<String, dynamic> toJson() => _$ItemTranslationToJson(this);
}
