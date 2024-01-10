// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manufacturer.dart';

Manufacturer _$mergeManufacturer(Manufacturer first, Manufacturer second) {
  final newer = first.updated.newer(second.updated) == first.updated ? first : second;
  var merged = Manufacturer(
    name: newer.name.isNotEmpty ? newer.name : first.name,
    website: newer.website.isNotEmpty ? newer.website : first.website,
    uid: newer.uid.isNotEmpty ? newer.uid : first.uid,
    parentName: newer.parentName.isNotEmpty ? newer.parentName : first.parentName,
    parentUid: newer.parentUid.isNotEmpty ? newer.parentUid : first.parentUid,
    created: first.created.older(second.created),
    updated: newer.updated,
  );
  if (!merged.equalTo(newer)) {
    merged = merged.copyWith(updated: DateTime.now());
  }
  return merged;
}
