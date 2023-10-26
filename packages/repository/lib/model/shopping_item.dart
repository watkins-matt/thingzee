import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'shopping_item.g.dart';

@JsonSerializable(explicitToJson: true)
@immutable
class ShoppingItem {
  // The UPC of the item
  @JsonKey(defaultValue: '')
  final String upc;

  // Whether the item is checked or not
  @JsonKey(defaultValue: false)
  final bool checked;

  // The type of list the item is on
  @JsonKey(
    toJson: ShoppingItem.shoppingListTypeToInt,
    fromJson: ShoppingItem.intToShoppingListType,
  )
  final ShoppingListType listType;

  const ShoppingItem({
    required this.upc,
    required this.checked,
    required this.listType,
  });

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => _$ShoppingItemFromJson(json);

  ShoppingItem copyWith({
    String? upc,
    bool? checked,
    ShoppingListType? listType,
  }) {
    return ShoppingItem(
      upc: upc ?? this.upc,
      checked: checked ?? this.checked,
      listType: listType ?? this.listType,
    );
  }

  Map<String, dynamic> toJson() => _$ShoppingItemToJson(this);

  static ShoppingListType intToShoppingListType(int index) => ShoppingListType.values[index];
  static int shoppingListTypeToInt(ShoppingListType listType) => listType.index;
}

enum ShoppingListType { savedList, shoppingList, shoppingCart }
