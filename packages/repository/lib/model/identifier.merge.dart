// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'identifier.dart';

ItemIdentifier _$mergeItemIdentifier(ItemIdentifier first, ItemIdentifier second) {
  final newer = first.updated.newer(second.updated) == first.updated ? first : second;
  var merged = ItemIdentifier(
    type: newer.type.isNotEmpty ? newer.type : first.type,
    value: newer.value.isNotEmpty ? newer.value : first.value,
    uid: newer.uid.isNotEmpty ? newer.uid : first.uid,
    created: first.created.older(second.created),
    updated: newer.updated,
  );
  if (!merged.equalTo(newer)) {
    merged = merged.copyWith(updated: DateTime.now());
  }
  return merged;
}