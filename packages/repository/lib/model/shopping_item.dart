import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:repository/model/abstract/model.dart';

part 'shopping_item.g.dart';

@JsonSerializable(explicitToJson: true)
@immutable
class ShoppingItem extends Model<ShoppingItem> {
  // The UPC of the item
  @JsonKey(defaultValue: '')
  final String upc;

  // Whether the item is checked or not
  @JsonKey(defaultValue: false)
  final bool checked;

  // The type of list this item is on
  @JsonKey(
    toJson: ShoppingItem.shoppingListTypeToInt,
    fromJson: ShoppingItem.intToShoppingListType,
  )
  final ShoppingListType listType;

  ShoppingItem({
    required this.upc,
    required this.checked,
    required this.listType,
    super.created,
    super.updated,
  });

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => _$ShoppingItemFromJson(json);

  @override
  String get id => upc;

  ShoppingItem copyWith({
    String? upc,
    bool? checked,
    ShoppingListType? listType,
    DateTime? created,
    DateTime? updated,
  }) {
    return ShoppingItem(
      upc: upc ?? this.upc,
      checked: checked ?? this.checked,
      listType: listType ?? this.listType,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  @override
  bool equalTo(ShoppingItem other) {
    return upc == other.upc && checked == other.checked && listType == other.listType;
  }

  @override
  ShoppingItem merge(ShoppingItem other) {
    final newer = (updated != null &&
            updated!.isAfter(other.updated ?? DateTime.fromMillisecondsSinceEpoch(0)))
        ? this
        : other;

    return ShoppingItem(
      upc: newer.upc.isNotEmpty ? newer.upc : upc,
      checked: newer.checked,
      listType: newer.listType,
      created: _determineOlderCreatedDate(created, other.created),
      updated: !equalTo(newer) ? DateTime.now() : newer.updated,
    );
  }

  @override
  Map<String, dynamic> toJson() => _$ShoppingItemToJson(this);

  static ShoppingListType intToShoppingListType(int index) => ShoppingListType.values[index];

  static int shoppingListTypeToInt(ShoppingListType listType) => listType.index;

  static DateTime _determineOlderCreatedDate(DateTime? date1, DateTime? date2) {
    return date1 ?? date2 ?? DateTime.now();
  }
}

enum ShoppingListType { savedList, shoppingList, shoppingCart }
