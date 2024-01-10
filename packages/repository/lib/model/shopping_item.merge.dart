// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_item.dart';

ShoppingItem _$mergeShoppingItem(ShoppingItem first, ShoppingItem second) {
  final newer = first.updated.newer(second.updated) == first.updated ? first : second;
  var merged = ShoppingItem(
    upc: newer.upc.isNotEmpty ? newer.upc : first.upc,
    checked: newer.checked,
    listType: newer.listType,
    created: first.created.older(second.created),
    updated: newer.updated,
  );
  if (!merged.equalTo(newer)) {
    merged = merged.copyWith(updated: DateTime.now());
  }
  return merged;
}
