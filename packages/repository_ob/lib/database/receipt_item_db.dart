import 'package:repository/database/receipt_database.dart';
import 'package:repository/model/receipt_item.dart';
import 'package:repository_ob/database/database.dart';
import 'package:repository_ob/model/receipt_item.ob.dart';
import 'package:repository_ob/objectbox.g.dart';

/// ObjectBox implementation of the ReceiptItemDatabase
class ObjectBoxReceiptItemDatabase extends ReceiptItemDatabase
    with ObjectBoxDatabase<ReceiptItem, ObjectBoxReceiptItem> {
  /// Constructor initializing ObjectBoxReceiptItemDatabase with the store and field mappings
  ObjectBoxReceiptItemDatabase(Store store) {
    init(
      store,
      ObjectBoxReceiptItem.from,
      ObjectBoxReceiptItem_.receiptUid,
      ObjectBoxReceiptItem_.updated,
    );
  }

  /// Retrieves all items associated with a specific receipt UID
  List<ReceiptItem> getItemsByReceiptUid(String receiptUid) {
    final query = box.query(ObjectBoxReceiptItem_.receiptUid.equals(receiptUid)).build();
    final results = query.find().map(convert).toList();
    query.close();
    return results;
  }
}
