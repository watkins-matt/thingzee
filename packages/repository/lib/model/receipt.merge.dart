// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt.dart';

Receipt _$mergeReceipt(Receipt first, Receipt second) {
  final newer = first.updated.newer(second.updated) == first.updated ? first : second;
  var merged = Receipt(
    items: <ReceiptItem>{...first.items, ...second.items}.toList(),
    date: newer.date,
    subtotal: newer.subtotal,
    discounts: <double>{...first.discounts, ...second.discounts}.toList(),
    tax: newer.tax,
    total: newer.total,
    uid: newer.uid.isNotEmpty ? newer.uid : first.uid,
    created: first.created.older(second.created),
    updated: newer.updated,
  );
  if (!merged.equalTo(newer)) {
    merged = merged.copyWith(updated: DateTime.now());
  }
  return merged;
}
