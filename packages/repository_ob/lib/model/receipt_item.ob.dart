// ignore_for_file: annotate_overrides


import 'package:objectbox/objectbox.dart';
import 'package:repository/model/receipt_item.dart';
import 'package:repository_ob/model_custom/object_box_model.dart';

@Entity()
class ObjectBoxReceiptItem extends ObjectBoxModel {
  @Id()
  int objectBoxId = 0;
  @Property(type: PropertyType.date)
  late DateTime? created;
  @Property(type: PropertyType.date)
  late DateTime? updated;
  late String name;
  late double price;
  late double regularPrice;
  late int quantity;
  late String barcode;
  late bool taxable;
  late double bottleDeposit;
  ObjectBoxReceiptItem();
  ObjectBoxReceiptItem.from(ReceiptItem original) {
    created = original.created;
    updated = original.updated;
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
        created: created,
        updated: updated,
        name: name,
        price: price,
        regularPrice: regularPrice,
        quantity: quantity,
        barcode: barcode,
        taxable: taxable,
        bottleDeposit: bottleDeposit);
  }
}
