// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShoppingItem _$ShoppingItemFromJson(Map<String, dynamic> json) => ShoppingItem(
      upc: json['upc'] as String? ?? '',
      checked: json['checked'] as bool? ?? false,
      listType: ShoppingItem.intToShoppingListType(json['listType'] as int),
    );

Map<String, dynamic> _$ShoppingItemToJson(ShoppingItem instance) =>
    <String, dynamic>{
      'upc': instance.upc,
      'checked': instance.checked,
      'listType': ShoppingItem.shoppingListTypeToInt(instance.listType),
    };
