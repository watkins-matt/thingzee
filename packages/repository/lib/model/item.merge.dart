// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'item.dart';
Item _$mergeItem(Item first, Item second) {
  final firstUpdate = first.lastUpdate ?? DateTime.fromMillisecondsSinceEpoch(0);
  final secondUpdate = second.lastUpdate ?? DateTime.fromMillisecondsSinceEpoch(0);
  final newerItem = secondUpdate.isAfter(firstUpdate) ? second : first;
  return Item()
    ..upc = newerItem.upc.isNotEmpty ? newerItem.upc : first.upc
    ..id = newerItem.id.isNotEmpty ? newerItem.id : first.id
    ..name = newerItem.name.isNotEmpty ? newerItem.name : first.name
    ..variety = newerItem.variety.isNotEmpty ? newerItem.variety : first.variety
    ..category = newerItem.category.isNotEmpty ? newerItem.category : first.category
    ..type = newerItem.type.isNotEmpty ? newerItem.type : first.type
    ..unitCount = newerItem.unitCount != 1 ? newerItem.unitCount : first.unitCount
    ..unitName = newerItem.unitName.isNotEmpty ? newerItem.unitName : first.unitName
    ..unitPlural = newerItem.unitPlural.isNotEmpty ? newerItem.unitPlural : first.unitPlural
    ..imageUrl = newerItem.imageUrl.isNotEmpty ? newerItem.imageUrl : first.imageUrl
    ..consumable = newerItem.consumable
    ..languageCode = newerItem.languageCode.isNotEmpty ? newerItem.languageCode : first.languageCode
    ..lastUpdate = newerItem.lastUpdate ?? first.lastUpdate
  ;
}
