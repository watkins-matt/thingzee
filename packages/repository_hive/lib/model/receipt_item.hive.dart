

import 'package:hive/hive.dart';
import 'package:repository/model/receipt_item.dart';

part 'receipt_item.hive.g.dart';

@HiveType(typeId: 0)
class HiveReceiptItem extends HiveObject {
  @HiveField(0)
  late String name;
  @HiveField(1)
  late double price;
  @HiveField(2)
  late double regularPrice;
  @HiveField(3)
  late int quantity;
  @HiveField(4)
  late String barcode;
  @HiveField(5)
  late bool taxable;
  @HiveField(6)
  late double bottleDeposit;
  HiveReceiptItem();
  HiveReceiptItem.from(ReceiptItem original) {
    name = original.name;
    price = original.price;
    regularPrice = original.regularPrice;
    quantity = original.quantity;
    barcode = original.barcode;
    taxable = original.taxable;
    bottleDeposit = original.bottleDeposit;
  }
  ReceiptItem toReceiptItem() {
    return ReceiptItem(
        name: name,
        price: price,
        regularPrice: regularPrice,
        quantity: quantity,
        barcode: barcode,
        taxable: taxable,
        bottleDeposit: bottleDeposit);
  }
}
