import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/database/identifier_database.dart';
import 'package:repository/ml/history_provider.dart';
import 'package:repository/model/identifier.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository/model/item.dart';
import 'package:repository/model/receipt.dart';
import 'package:repository/model/receipt_item.dart';
import 'package:repository/repository.dart';

final matchedItemsProvider =
    StateNotifierProvider.family<MatchedItemsNotifier, List<MatchedItem>, List<ReceiptItem>>(
        (ref, items) {
  return MatchedItemsNotifier(items);
});

class MatchedItem {
  final ReceiptItem receiptItem;
  String status;
  Item? match;

  MatchedItem({required this.receiptItem, this.status = 'No Match', this.match});
}

class MatchedItemsNotifier extends StateNotifier<List<MatchedItem>> {
  MatchedItemsNotifier(List<ReceiptItem> receiptItems)
      : super(receiptItems.map((item) => MatchedItem(receiptItem: item)).toList());

  List<MatchedItem> get confirmedItems =>
      state.where((item) => item.status.startsWith('Confirmed')).toList();
  List<MatchedItem> get matchedItems =>
      state.where((item) => item.status.startsWith('Matched')).toList();
  List<MatchedItem> get unmatchedItems =>
      state.where((item) => item.status.startsWith('No Match')).toList();

  void addItemsToInventory(Repository repo, Receipt receipt) {
    final time = receipt.date ?? DateTime.now();

    for (final matchedItem in state) {
      final item = matchedItem.match;

      // Only process items that have been matched (and are not null)
      if (item != null) {
        var inventory = repo.inv.get(item.upc);

        // Increment the inventory if it exists
        if (inventory != null) {
          inventory = inventory.updateAmountToPredictionAtTimestamp(time.millisecondsSinceEpoch);
          inventory = inventory.copyWith(
            amount: inventory.amount + matchedItem.receiptItem.quantity,
            updated: time,
          );
        }

        // Need to create a new inventory item
        else {
          inventory = Inventory(
            upc: item.upc,
            amount: matchedItem.receiptItem.quantity.toDouble(),
            updated: time,
          );
        }

        final newHistory = inventory.history.add(time.millisecondsSinceEpoch, inventory.amount, 2);
        repo.inv.put(inventory);
        repo.hist.put(newHistory);
        HistoryProvider().updateHistory(newHistory);

        // If we have a confirmed item and the barcode type is not UPC, add the identifier
        if (matchedItem.status == 'Confirmed' && receipt.barcodeType != IdentifierType.upc) {
          final identifierType = receipt.barcodeType;
          final identifier = Identifier(
            type: identifierType,
            value: matchedItem.receiptItem.barcode,
            uid: item.uid,
          );

          repo.identifiers.put(identifier);
        }
      }
    }
  }

  void updateStatus(int index, String newStatus, {Item? matchedItem}) {
    var currentMatchedItem = state[index];

    // Update status and optionally set the matchedItem if provided
    currentMatchedItem.status = newStatus;

    if (matchedItem != null) {
      currentMatchedItem.match = matchedItem;
    }

    state = [...state];
  }
}
