// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

Product _$mergeProduct(Product first, Product second) {
  final newer = first.updated.newer(second.updated) == first.updated ? first : second;
  var merged = Product(
    name: newer.name.isNotEmpty ? newer.name : first.name,
    uid: newer.uid.isNotEmpty ? newer.uid : first.uid,
    manufacturer: newer.manufacturer.isNotEmpty ? newer.manufacturer : first.manufacturer,
    manufacturerUid: newer.manufacturerUid.isNotEmpty ? newer.manufacturerUid : first.manufacturerUid,
    category: newer.category.isNotEmpty ? newer.category : first.category,
    upcs: <String>{...first.upcs, ...second.upcs}.toList(),
    created: first.created.older(second.created),
    updated: newer.updated,
  );
  if (!merged.equalTo(newer)) {
    merged = merged.copyWith(updated: DateTime.now());
  }
  return merged;
}
