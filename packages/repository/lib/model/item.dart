import 'package:json_annotation/json_annotation.dart';
import 'package:repository/merge_generator.dart';
import 'package:repository/model/inventory.dart';

part 'item.g.dart';
part 'item.merge.dart';

@JsonSerializable(explicitToJson: true)
@Mergeable()
class Item implements Comparable<Item> {
  String upc = '';
  String iuid = '';

  String name = '';
  String variety = '';

  String category = '';
  String type = '';

  // Unit information
  int unitCount = 1; // How many units are part of this item, e.g. 12 bottles
  String unitName = ''; // What is the name of the unit, e.g. bottle
  String unitPlural = ''; // What is the plural of the unit, e.g. bottle
  String imageUrl = '';

  bool consumable = true;
  String languageCode = 'en';

  @NullableDateTimeSerializer()
  DateTime? lastUpdate;

  Item();
  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);

  @override
  int compareTo(Item other) {
    return name.compareTo(other.name);
  }

  bool equalTo(Item other) =>
      identical(this, other) ||
      upc == other.upc &&
          iuid == other.iuid &&
          name == other.name &&
          variety == other.variety &&
          category == other.category &&
          type == other.type &&
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
  String upc = '';
  String languageCode = 'en';
  String name = '';
  String variety = '';
  String unitName = '';
  String unitPlural = '';

  ItemTranslation();
  factory ItemTranslation.fromJson(Map<String, dynamic> json) => _$ItemTranslationFromJson(json);
  Map<String, dynamic> toJson() => _$ItemTranslationToJson(this);
}
