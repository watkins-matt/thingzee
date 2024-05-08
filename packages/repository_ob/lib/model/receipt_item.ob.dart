// ignore_for_file: annotate_overrides


import 'package:objectbox/objectbox.dart';
import 'package:repository/model/receipt_item.dart';
import 'package:repository_ob/objectbox_model.dart';

@Entity()
class ObjectBoxReceiptItem extends ObjectBoxModel<ReceiptItem> {
  @Id()
  int objectBoxId = 0;
  late bool taxable;
  @Property(type: PropertyType.date)
  late DateTime created;
  @Property(type: PropertyType.date)
  late DateTime updated;
  late double bottleDeposit;
  late double price;
  late double regularPrice;
  late int quantity;
  late String barcode;
  late String name;
  late String receiptUid;
  ObjectBoxReceiptItem();
  ObjectBoxReceiptItem.from(ReceiptItem original) {
    barcode = original.barcode;
    bottleDeposit = original.bottleDeposit;
    created = original.created;
    name = original.name;
    price = original.price;
    quantity = original.quantity;
    receiptUid = original.receiptUid;
    regularPrice = original.regularPrice;
    taxable = original.taxable;
    updated = original.updated;
  }
  ReceiptItem convert() {
    return ReceiptItem(
        barcode: barcode,
        bottleDeposit: bottleDeposit,
        created: created,
        name: name,
        price: price,
        quantity: quantity,
        receiptUid: receiptUid,
        regularPrice: regularPrice,
        taxable: taxable,
        updated: updated);
  }
}
