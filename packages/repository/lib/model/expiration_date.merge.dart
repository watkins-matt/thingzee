// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expiration_date.dart';

ExpirationDate _$mergeExpirationDate(ExpirationDate first, ExpirationDate second) {
  final newer = first.updated.newer(second.updated) == first.updated ? first : second;
  var merged = ExpirationDate(
    upc: newer.upc.isNotEmpty ? newer.upc : first.upc,
    expirationDate: newer.expirationDate,
    created: first.created.older(second.created),
    updated: newer.updated,
  );
  if (!merged.equalTo(newer)) {
    merged = merged.copyWith(updated: DateTime.now());
  }
  return merged;
}
