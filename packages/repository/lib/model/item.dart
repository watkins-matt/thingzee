import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:repository/merge_generator.dart';
import 'package:repository/model/abstract/model.dart';
import 'package:repository/model/abstract/nameable.dart';
import 'package:repository/model/serializer_datetime.dart';
import 'package:repository/util/hash.dart';
import 'package:util/extension/date_time.dart';
import 'package:uuid/uuid.dart';

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

  Item(
      {this.upc = '',
      String? uid,
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
      super.created,
      super.updated})
      : uid = uid != null && uid.isNotEmpty
            ? uid
            : (upc.isNotEmpty ? hashBarcode(upc) : const Uuid().v4());

  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);

  @override
  String get id => upc;

  @override
  int compareTo(Item other) {
    return name.compareTo(other.name);
  }

  @override
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
    DateTime? created,
    DateTime? updated,
  }) {
    return Item(
      upc: upc ?? this.upc,
      uid: uid != null && uid.isNotEmpty
          ? uid
          : (upc != null && upc.isNotEmpty ? hashBarcode(upc) : this.uid),
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
          created == other.created &&
          updated == other.updated;

  @override
  Item merge(Item other) => _$mergeItem(this, other);

  @override
  Map<String, dynamic> toJson() => _$ItemToJson(this);
}
