import 'package:repository/database/receipt_database.dart';
import 'package:repository/model/receipt.dart';
import 'package:repository_ob/database/database.dart';
import 'package:repository_ob/database/receipt_item_db.dart';
import 'package:repository_ob/model/receipt.ob.dart';
import 'package:repository_ob/objectbox.g.dart';

/// ObjectBox implementation of the ReceiptDatabase
class ObjectBoxReceiptDatabase extends ReceiptDatabase
    with ObjectBoxDatabase<Receipt, ObjectBoxReceipt> {
  /// Reference to the ReceiptItemDatabase for retrieving associated items
  final ObjectBoxReceiptItemDatabase receiptItemDatabase;

  /// Constructor initializing ObjectBoxReceiptDatabase with the store and field mappings
  ObjectBoxReceiptDatabase(Store store, this.receiptItemDatabase) {
    init(
      store,
      ObjectBoxReceipt.from,
      ObjectBoxReceipt_.uid,
      ObjectBoxReceipt_.updated,
    );
  }

  @override
  void deleteById(String uid) {
    final receipt = get(uid);
    if (receipt != null) {
      // Delete associated items first
      final items = receiptItemDatabase.getItemsByReceiptUid(uid);
      for (final item in items) {
        receiptItemDatabase.delete(item);
      }
    }
    // Delete the receipt itself
    super.deleteById(uid);
  }

  @override
  Receipt? get(String uid) {
    final receipt = super.get(uid);
    if (receipt != null) {
      final items = receiptItemDatabase.getItemsByReceiptUid(receipt.uid);
      return receipt.copyWith(items: items);
    }
    return null;
  }

  @override
  List<Receipt> getAll(List<String> uids) {
    final receipts = super.getAll(uids);
    for (var receipt in receipts) {
      final items = receiptItemDatabase.getItemsByReceiptUid(receipt.uid);
      receipt = receipt.copyWith(items: items);
    }
    return receipts;
  }

  @override
  Receipt put(Receipt receipt) {
    assert(receipt.isValid);

    // Save receipt metadata
    final itemOb = fromModel(receipt);

    final query = box.query(buildIdCondition(receipt.uniqueKey)).build();
    final exists = query.findFirst();
    query.close();

    if (exists != null && itemOb.objectBoxId != exists.objectBoxId) {
      itemOb.objectBoxId = exists.objectBoxId;
    }

    box.put(itemOb);

    // Save the associated receipt items
    for (final item in receipt.items) {
      receiptItemDatabase.put(item.copyWith(receiptUid: receipt.uid));
    }

    // Return the updated receipt (with potentially updated metadata)
    return receipt.copyWith(
      uid: itemOb.uid,
      created: itemOb.created,
      updated: itemOb.updated,
    );
  }
}
