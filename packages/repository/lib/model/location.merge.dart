// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location.dart';

Location _$mergeLocation(Location first, Location second) {
  final newer = first.updated.newer(second.updated) == first.updated ? first : second;
  var merged = Location(
    upc: newer.upc.isNotEmpty ? newer.upc : first.upc,
    name: newer.name.isNotEmpty ? newer.name : first.name,
    quantity: newer.quantity,
    householdId: newer.householdId.isNotEmpty ? newer.householdId : first.householdId,
    created: first.created.older(second.created),
    updated: newer.updated,
  );
  if (!merged.equalTo(newer)) {
    merged = merged.copyWith(updated: DateTime.now());
  }
  return merged;
}
