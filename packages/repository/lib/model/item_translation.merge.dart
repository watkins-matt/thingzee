// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_translation.dart';

ItemTranslation _$mergeItemTranslation(ItemTranslation first, ItemTranslation second) {
  final newer = first.updated.newer(second.updated) == first.updated ? first : second;
  var merged = ItemTranslation(
    upc: newer.upc.isNotEmpty ? newer.upc : first.upc,
    languageCode: newer.languageCode.isNotEmpty ? newer.languageCode : first.languageCode,
    name: newer.name.isNotEmpty ? newer.name : first.name,
    variety: newer.variety.isNotEmpty ? newer.variety : first.variety,
    unitName: newer.unitName.isNotEmpty ? newer.unitName : first.unitName,
    unitPlural: newer.unitPlural.isNotEmpty ? newer.unitPlural : first.unitPlural,
    type: newer.type.isNotEmpty ? newer.type : first.type,
    created: first.created.older(second.created),
    updated: newer.updated,
  );
  if (!merged.equalTo(newer)) {
    merged = merged.copyWith(updated: DateTime.now());
  }
  return merged;
}
