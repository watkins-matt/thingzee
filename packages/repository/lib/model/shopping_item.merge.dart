// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_item.dart';

ShoppingItem _$mergeShoppingItem(ShoppingItem first, ShoppingItem second) {
  final newer = first.updated.newer(second.updated) == first.updated ? first : second;
  var merged = ShoppingItem(
    uid: newer.uid.isNotEmpty ? newer.uid : first.uid,
    upc: newer.upc.isNotEmpty ? newer.upc : first.upc,
    name: newer.name.isNotEmpty ? newer.name : first.name,
    category: newer.category.isNotEmpty ? newer.category : first.category,
    price: newer.price,
    quantity: newer.quantity,
    checked: newer.checked,
    listName: newer.listName.isNotEmpty ? newer.listName : first.listName,
    created: first.created.older(second.created),
    updated: newer.updated,
  );
  if (!merged.equalTo(newer)) {
    merged = merged.copyWith(updated: DateTime.now());
  }
  return merged;
}
