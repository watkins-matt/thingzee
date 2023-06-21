import 'package:json_annotation/json_annotation.dart';

part 'item.g.dart';

@JsonSerializable(explicitToJson: true)
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
  List<ItemTranslation> translations = <ItemTranslation>[];

  @override
  int compareTo(Item other) {
    return name.compareTo(other.name);
  }

  Item();
  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);
  Map<String, dynamic> toJson() => _$ItemToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ItemTranslation {
  String languageCode = 'en';
  String name = '';
  String variety = '';
  String unitName = '';
  String unitPlural = '';

  ItemTranslation();
  factory ItemTranslation.fromJson(Map<String, dynamic> json) => _$ItemTranslationFromJson(json);
  Map<String, dynamic> toJson() => _$ItemTranslationToJson(this);
}
