import 'package:repository/model/receipt.dart';
import 'package:thingzee/pages/receipt_scanner/parser/order_tracker.dart';

abstract class ReceiptParser {
  RelativeOrderTracker orderTracker = RelativeOrderTracker();
  Receipt get receipt;
  void parse(String text);

  List<ReceiptItem> sortItems(List<ReceiptItem> items) {
    // Create a map for quick access to items by their barcode
    final itemMap = {for (final item in items) item.barcode: item};

    // Use the order in canonicalOrder to sort items
    List<ReceiptItem> sortedItems = [];
    for (final barcode in orderTracker.canonicalOrder.keys) {
      if (itemMap.containsKey(barcode)) {
        sortedItems.add(itemMap[barcode]!);
      }
    }

    return sortedItems;
  }
}
