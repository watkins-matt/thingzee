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
  @Property(type: PropertyType.date)
  late DateTime? date;
  late double subtotal;
  late double tax;
  late double total;
  List<double> discounts = [];
  @Transient()
  List<ReceiptItem> items = [];
  late String barcodeType;
  late String uid;
  ObjectBoxReceipt();
  ObjectBoxReceipt.from(Receipt original) {
    barcodeType = original.barcodeType;
    created = original.created;
    date = original.date;
    discounts = original.discounts;
    items = original.items;
    subtotal = original.subtotal;
    tax = original.tax;
    total = original.total;
    uid = original.uid;
    updated = original.updated;
  }
  Receipt convert() {
    return Receipt(
        barcodeType: barcodeType,
        created: created,
        date: date,
        discounts: discounts,
        items: items,
        subtotal: subtotal,
        tax: tax,
        total: total,
        uid: uid,
        updated: updated);
  }
}
