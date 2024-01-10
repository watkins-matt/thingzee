// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory.dart';

Inventory _$mergeInventory(Inventory first, Inventory second) {
  final newer = first.updated.newer(second.updated) == first.updated ? first : second;
  var merged = Inventory(
    amount: newer.amount,
    unitCount: newer.unitCount,
    locations: <String>{...first.locations, ...second.locations}.toList(),
    expirationDates: <DateTime>{...first.expirationDates, ...second.expirationDates}.toList(),
    restock: newer.restock,
    uid: newer.uid.isNotEmpty ? newer.uid : first.uid,
    lastUpdate: newer.lastUpdate,
    history: newer.history,
    upc: newer.upc.isNotEmpty ? newer.upc : first.upc,
    created: first.created.older(second.created),
    updated: newer.updated,
  );
  if (!merged.equalTo(newer)) {
    merged = merged.copyWith(updated: DateTime.now());
  }
  return merged;
}
