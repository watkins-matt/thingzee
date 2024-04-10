import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:repository/database/shopping_list.dart';
import 'package:repository/merge_generator.dart';
import 'package:repository/model/abstract/model.dart';
import 'package:repository/model/serializer_datetime.dart';
import 'package:repository/util/hash.dart';
import 'package:util/extension/date_time.dart';
import 'package:uuid/uuid.dart';

part 'shopping_item.g.dart';
part 'shopping_item.merge.dart';

@JsonSerializable(explicitToJson: true)
@immutable
@Mergeable()
class ShoppingItem extends Model<ShoppingItem> {
  final String uid; // Unique identifier for the item
  final String upc; // The UPC of the item
  final String name; // The name of the item
  final String category; // The category of the item
  final double price; // The price of the item
  final bool checked; // Whether the item is checked or not
  final String listName; // The name of the list the item is in

  ShoppingItem({
    String? uid,
    this.upc = '',
    this.checked = false,
    this.listName = ShoppingListName.shopping,
    this.name = '',
    this.category = '',
    this.price = 0.0,
    super.created,
    super.updated,
  }) : uid = uid != null && uid.isNotEmpty
            ? uid
            : (upc.isNotEmpty ? hashBarcode(upc) : const Uuid().v4());

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => _$ShoppingItemFromJson(json);

  @override
  String get id => uid;

  @override
  ShoppingItem copyWith({
    String? uid,
    String? upc,
    bool? checked,
    String? listName,
    String? name,
    String? category,
    double? price,
    DateTime? created,
    DateTime? updated,
  }) {
    return ShoppingItem(
      uid: uid != null && uid.isNotEmpty
          ? uid
          : (upc != null && upc.isNotEmpty ? hashBarcode(upc) : this.uid),
      upc: upc ?? this.upc,
      checked: checked ?? this.checked,
      listName: listName ?? this.listName,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  @override
  bool equalTo(ShoppingItem other) {
    return uid == other.uid &&
        upc == other.upc &&
        checked == other.checked &&
        listName == other.listName &&
        name == other.name &&
        category == other.category &&
        price == other.price;
  }

  @override
  ShoppingItem merge(ShoppingItem other) => _$mergeShoppingItem(this, other);

  @override
  Map<String, dynamic> toJson() => _$ShoppingItemToJson(this);
}
