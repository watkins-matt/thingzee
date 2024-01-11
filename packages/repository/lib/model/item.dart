import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:repository/extension/date_time.dart';
import 'package:repository/merge_generator.dart';
import 'package:repository/model/abstract/model.dart';
import 'package:repository/model/abstract/nameable.dart';
import 'package:repository/model/serializer_datetime.dart';

part 'item.g.dart';
part 'item.merge.dart';

@JsonSerializable(explicitToJson: true)
@immutable
@Mergeable()
class Item extends Model<Item> implements Comparable<Item>, Nameable {
  final String upc; // generator:unique

  final String uid;

  @override
  final String name;

  final String variety;
  final String category;
  final String type; // Type of the item, example: Cereal, Milk, Tomato Sauce
  final String typeId;
  final int unitCount; // How many units are part of this item, e.g. 12 bottles
  final String unitName; // What is the name of the unit, e.g. bottle
  final String unitPlural; // What is the plural of the unit, e.g. bottles
  final String imageUrl;
  final bool consumable;
  final String languageCode;
  @NullableDateTimeSerializer()
  final DateTime? lastUpdate;

  Item({
    this.upc = '',
    this.uid = '',
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
  String get id => upc;

  @override
  int compareTo(Item other) {
    return name.compareTo(other.name);
  }

  Item copyWith({
    String? upc,
    String? uid,
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
      uid: uid ?? this.uid,
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
          uid == other.uid &&
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
