// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item.dart';

Item _$mergeItem(Item first, Item second) {
  final newer = first.updated.newer(second.updated) == first.updated ? first : second;
  var merged = Item(
    upc: newer.upc.isNotEmpty ? newer.upc : first.upc,
    id: newer.id.isNotEmpty ? newer.id : first.id,
    name: newer.name.isNotEmpty ? newer.name : first.name,
    variety: newer.variety.isNotEmpty ? newer.variety : first.variety,
    category: newer.category.isNotEmpty ? newer.category : first.category,
    type: newer.type.isNotEmpty ? newer.type : first.type,
    typeId: newer.typeId.isNotEmpty ? newer.typeId : first.typeId,
    unitCount: newer.unitCount,
    unitName: newer.unitName.isNotEmpty ? newer.unitName : first.unitName,
    unitPlural: newer.unitPlural.isNotEmpty ? newer.unitPlural : first.unitPlural,
    imageUrl: newer.imageUrl.isNotEmpty ? newer.imageUrl : first.imageUrl,
    consumable: newer.consumable,
    languageCode: newer.languageCode.isNotEmpty ? newer.languageCode : first.languageCode,
    lastUpdate: newer.lastUpdate,
    created: first.created.older(second.created),
    updated: newer.updated,
  );
  if (!merged.equalTo(newer)) {
    merged = merged.copyWith(updated: DateTime.now());
  }
  return merged;
}
