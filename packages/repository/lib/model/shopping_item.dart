import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:repository/database/shopping_list_database.dart';
import 'package:repository/merge_generator.dart';
import 'package:repository/model/abstract/model.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository/model/item.dart';
import 'package:repository/model/serializer_datetime.dart';
import 'package:repository/model_provider.dart';
import 'package:util/extension/date_time.dart';
import 'package:uuid/uuid.dart';

part 'shopping_item.g.dart';
part 'shopping_item.merge.dart';

@JsonSerializable(explicitToJson: true)
@immutable
@Mergeable()
class ShoppingItem extends Model<ShoppingItem> {
  final String uid; // generator:unique Unique identifier for the item
  final String upc; // The UPC of the item
  final String name; // The name of the item
  final String category; // The category of the item
  final double price; // The price of the item
  final int quantity; // The quantity of the item
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
    this.quantity = 1,
    super.created,
    super.updated,
  }) : uid = uid != null && uid.isNotEmpty ? uid : const Uuid().v4();
  factory ShoppingItem.fromJson(Map<String, dynamic> json) => _$ShoppingItemFromJson(json);

  @override
  int get hashCode => upc.isNotEmpty ? upc.hashCode : uid.hashCode;

  @override
  String get uniqueKey => uid;
  Inventory get inventory => ModelProvider<Inventory>().get(upc, Inventory(upc: upc));

  Item get item => ModelProvider<Item>().get(upc, Item(upc: upc));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShoppingItem &&
          runtimeType == other.runtimeType &&
          (upc.isNotEmpty ? upc == other.upc : uid == other.uid);

  @override
  ShoppingItem copyWith({
    String? uid,
    String? upc,
    bool? checked,
    String? listName,
    String? name,
    String? category,
    double? price,
    int? quantity,
    DateTime? created,
    DateTime? updated,
  }) {
    return ShoppingItem(
      uid: uid != null && uid.isNotEmpty ? uid : this.uid,
      upc: upc ?? this.upc,
      checked: checked ?? this.checked,
      listName: listName ?? this.listName,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
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
        price == other.price &&
        quantity == other.quantity;
  }

  @override
  ShoppingItem merge(ShoppingItem other) => _$mergeShoppingItem(this, other);

  @override
  Map<String, dynamic> toJson() => _$ShoppingItemToJson(this);
}
