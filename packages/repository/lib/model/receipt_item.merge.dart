// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_item.dart';

ReceiptItem _$mergeReceiptItem(ReceiptItem first, ReceiptItem second) {
  final newer = first.updated.newer(second.updated) == first.updated ? first : second;
  var merged = ReceiptItem(
    name: newer.name.isNotEmpty ? newer.name : first.name,
    price: newer.price,
    regularPrice: newer.regularPrice,
    quantity: newer.quantity,
    barcode: newer.barcode.isNotEmpty ? newer.barcode : first.barcode,
    taxable: newer.taxable,
    bottleDeposit: newer.bottleDeposit,
    created: first.created.older(second.created),
    updated: newer.updated,
  );
  if (!merged.equalTo(newer)) {
    merged = merged.copyWith(updated: DateTime.now());
  }
  return merged;
}
