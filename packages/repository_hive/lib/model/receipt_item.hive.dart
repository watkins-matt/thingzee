// ignore_for_file: annotate_overrides


import 'package:hive/hive.dart';
import 'package:repository/model/receipt_item.dart';

part 'receipt_item.hive.g.dart';

@HiveType(typeId: 0)
class HiveReceiptItem extends HiveObject {
  @HiveField(0)
  late DateTime? created;
  @HiveField(1)
  late DateTime? updated;
  @HiveField(2)
  late String name;
  @HiveField(3)
  late double price;
  @HiveField(4)
  late double regularPrice;
  @HiveField(5)
  late int quantity;
  @HiveField(6)
  late String barcode;
  @HiveField(7)
  late bool taxable;
  @HiveField(8)
  late double bottleDeposit;
  @HiveField(9)
  late String receiptUid;
  HiveReceiptItem();
  HiveReceiptItem.from(ReceiptItem original) {
    created = original.created;
    updated = original.updated;
    name = original.name;
    price = original.price;
    regularPrice = original.regularPrice;
    quantity = original.quantity;
    barcode = original.barcode;
    taxable = original.taxable;
    bottleDeposit = original.bottleDeposit;
    receiptUid = original.receiptUid;
  }
  ReceiptItem toReceiptItem() {
    return ReceiptItem(
        created: created,
        updated: updated,
        name: name,
        price: price,
        regularPrice: regularPrice,
        quantity: quantity,
        barcode: barcode,
        taxable: taxable,
        bottleDeposit: bottleDeposit,
        receiptUid: receiptUid);
  }
}
