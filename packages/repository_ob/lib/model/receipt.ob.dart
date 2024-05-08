// ignore_for_file: annotate_overrides

import 'package:objectbox/objectbox.dart';
import 'package:repository/model/receipt.dart';
import 'package:repository/model/receipt_item.dart';
import 'package:repository_ob/objectbox_model.dart';

@Entity()
class ObjectBoxReceipt extends ObjectBoxModel<Receipt> {
  @Id()
  int objectBoxId = 0;
  @Property(type: PropertyType.date)
  late DateTime created;
  @Property(type: PropertyType.date)
  late DateTime updated;
  @Transient()
  List<ReceiptItem> items = [];
  @Property(type: PropertyType.date)
  late DateTime? date;
  late double subtotal;
  List<double> discounts = [];
  late double tax;
  late double total;
  late String uid;
  late String barcodeType;
  ObjectBoxReceipt();
  ObjectBoxReceipt.from(Receipt original) {
    created = original.created;
    updated = original.updated;
    items = original.items;
    date = original.date;
    subtotal = original.subtotal;
    discounts = original.discounts;
    tax = original.tax;
    total = original.total;
    uid = original.uid;
    barcodeType = original.barcodeType;
  }
  Receipt convert() {
    return Receipt(
        created: created,
        updated: updated,
        items: items,
        date: date,
        subtotal: subtotal,
        discounts: discounts,
        tax: tax,
        total: total,
        uid: uid,
        barcodeType: barcodeType);
  }
}
