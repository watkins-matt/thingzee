import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:repository/database/shopping_list.dart';
import 'package:repository/merge_generator.dart';
import 'package:repository/model/abstract/model.dart';
import 'package:repository/model/serializer_datetime.dart';
import 'package:util/extension/date_time.dart';

part 'shopping_item.g.dart';
part 'shopping_item.merge.dart';

@JsonSerializable(explicitToJson: true)
@immutable
@Mergeable()
class ShoppingItem extends Model<ShoppingItem> {
  // The UPC of the item
  @JsonKey(defaultValue: '')
  final String upc;

  // The name of the item; can potentially be a generic name like 'Bread'
  @JsonKey(defaultValue: '')
  final String name;

  // The category of the item - where it would be found in a store
  @JsonKey(defaultValue: '')
  final String category;

  // The price of the item, defaulting to 0.0 if not present
  @JsonKey(defaultValue: 0.0)
  final double price;

  // Whether the item is checked or not
  @JsonKey(defaultValue: false)
  final bool checked;

  @JsonKey(defaultValue: ShoppingListName.shopping)
  final String listName;

  ShoppingItem({
    required this.upc,
    required this.checked,
    this.listName = ShoppingListName.shopping,
    this.name = '',
    this.category = '',
    this.price = 0.0,
    super.created,
    super.updated,
  });

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => _$ShoppingItemFromJson(json);

  @override
  String get id => upc;

  @override
  ShoppingItem copyWith({
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
    return upc == other.upc &&
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
