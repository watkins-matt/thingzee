

import 'package:objectbox/objectbox.dart';
import 'package:repository/model/receipt_item.dart';

@Entity()
class ObjectBoxReceiptItem {
  late String name;
  late double price;
  late double regularPrice;
  late int quantity;
  late String barcode;
  late bool taxable;
  late double bottleDeposit;
  @Id()
  int objectBoxId = 0;
  ObjectBoxReceiptItem();
  ObjectBoxReceiptItem.from(ReceiptItem original) {
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
