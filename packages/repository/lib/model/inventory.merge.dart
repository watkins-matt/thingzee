// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'inventory.dart';
Inventory _$mergeInventory(Inventory first, Inventory second) {
  final firstUpdate = first.lastUpdate ?? DateTime.fromMillisecondsSinceEpoch(0);
  final secondUpdate = second.lastUpdate ?? DateTime.fromMillisecondsSinceEpoch(0);
  final newerInventory = secondUpdate.isAfter(firstUpdate) ? second : first;
  return Inventory()
    ..amount = newerInventory.amount
    ..unitCount = newerInventory.unitCount != 1 ? newerInventory.unitCount : first.unitCount
    ..lastUpdate = newerInventory.lastUpdate ?? first.lastUpdate
    ..expirationDates = {...newerInventory.expirationDates, ...first.expirationDates}.toList()
    ..locations = {...newerInventory.locations, ...first.locations}.toList()
    ..history = newerInventory.history
    ..restock = newerInventory.restock
    ..upc = newerInventory.upc.isNotEmpty ? newerInventory.upc : first.upc
    ..iuid = newerInventory.iuid.isNotEmpty ? newerInventory.iuid : first.iuid
  ;
}
