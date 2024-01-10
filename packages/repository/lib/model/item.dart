import 'package:json_annotation/json_annotation.dart';
import 'package:repository/model/abstract/model.dart';
import 'package:repository/model/abstract/nameable.dart';
import 'package:repository/model/serializer_datetime.dart';

part 'item.g.dart';

@JsonSerializable(explicitToJson: true)
class Item extends Model<Item> implements Comparable<Item>, Nameable {
  @JsonKey(defaultValue: '')
  final String upc; // generator:unique

  @override
  @JsonKey(defaultValue: '')
  final String id;

  @override
  @JsonKey(defaultValue: '')
  final String name;

  @JsonKey(defaultValue: '')
  final String variety;

  @JsonKey(defaultValue: '')
  final String category;

  @JsonKey(defaultValue: '')
  final String type; // Type of the item, example: Cereal, Milk, Tomato Sauce

  @JsonKey(defaultValue: '')
  final String typeId;

  // Unit information:
  @JsonKey(defaultValue: 1)
  final int unitCount; // How many units are part of this item, e.g. 12 bottles

  @JsonKey(defaultValue: '')
  final String unitName; // What is the name of the unit, e.g. bottle

  @JsonKey(defaultValue: '')
  final String unitPlural; // What is the plural of the unit, e.g. bottles

  @JsonKey(defaultValue: '')
  final String imageUrl;

  @JsonKey(defaultValue: true)
  final bool consumable;

  @JsonKey(defaultValue: 'en')
  final String languageCode;

  @NullableDateTimeSerializer()
  final DateTime? lastUpdate;

  Item({
    this.upc = '',
    this.id = '',
    this.name = '',
    this.variety = '',
    this.category = '',
    this.type = '',
    this.typeId = '',
    this.unitCount = 1,
    this.unitName = '',
    this.unitPlural = '',
    this.imageUrl = '',
    this.consumable = true,
    this.languageCode = 'en',
    this.lastUpdate,
    super.created,
    super.updated,
  });

  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);

  @override
  int compareTo(Item other) {
    return name.compareTo(other.name);
  }

  Item copyWith({
    String? upc,
    String? id,
    String? name,
    String? variety,
    String? category,
    String? type,
    String? typeId,
    int? unitCount,
    String? unitName,
    String? unitPlural,
    String? imageUrl,
    bool? consumable,
    String? languageCode,
    DateTime? lastUpdate,
    DateTime? created,
    DateTime? updated,
  }) {
    return Item(
      upc: upc ?? this.upc,
      id: id ?? this.id,
      name: name ?? this.name,
      variety: variety ?? this.variety,
      category: category ?? this.category,
      type: type ?? this.type,
      typeId: typeId ?? this.typeId,
      unitCount: unitCount ?? this.unitCount,
      unitName: unitName ?? this.unitName,
      unitPlural: unitPlural ?? this.unitPlural,
      imageUrl: imageUrl ?? this.imageUrl,
      consumable: consumable ?? this.consumable,
      languageCode: languageCode ?? this.languageCode,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  @override
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

  @override
  Item merge(Item other) => _$mergeItem(this, other);

  @override
  Map<String, dynamic> toJson() => _$ItemToJson(this);

  Item _$mergeItem(Item first, Item second) {
    final firstUpdate = first.lastUpdate ?? DateTime.fromMillisecondsSinceEpoch(0);
    final secondUpdate = second.lastUpdate ?? DateTime.fromMillisecondsSinceEpoch(0);
    final newerItem = secondUpdate.isAfter(firstUpdate) ? second : first;
    return Item(
      upc: newerItem.upc.isNotEmpty ? newerItem.upc : first.upc,
      id: newerItem.id.isNotEmpty ? newerItem.id : first.id,
      name: newerItem.name.isNotEmpty ? newerItem.name : first.name,
      variety: newerItem.variety.isNotEmpty ? newerItem.variety : first.variety,
      category: newerItem.category.isNotEmpty ? newerItem.category : first.category,
      type: newerItem.type.isNotEmpty ? newerItem.type : first.type,
      typeId: newerItem.typeId.isNotEmpty ? newerItem.typeId : first.typeId,
      unitCount: newerItem.unitCount != 1 ? newerItem.unitCount : first.unitCount,
      unitName: newerItem.unitName.isNotEmpty ? newerItem.unitName : first.unitName,
      unitPlural: newerItem.unitPlural.isNotEmpty ? newerItem.unitPlural : first.unitPlural,
      imageUrl: newerItem.imageUrl.isNotEmpty ? newerItem.imageUrl : first.imageUrl,
      consumable: newerItem.consumable,
      languageCode: newerItem.languageCode.isNotEmpty ? newerItem.languageCode : first.languageCode,
      lastUpdate: newerItem.lastUpdate ?? first.lastUpdate,
    );
  }
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
