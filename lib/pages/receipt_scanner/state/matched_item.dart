import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:receipt_parser/model/receipt.dart';
import 'package:receipt_parser/model/receipt_item.dart';
import 'package:repository/database/identifier_database.dart';
import 'package:repository/model/identifier.dart';
import 'package:repository/model/inventory.dart';
import 'package:repository/model/item.dart';
import 'package:repository/repository.dart';

final matchedItemsProvider =
    StateNotifierProvider.family<MatchedItemsNotifier, List<MatchedItem>, List<ParsedReceiptItem>>(
        (ref, items) {
  return MatchedItemsNotifier(items);
});

class MatchedItem {
  final ParsedReceiptItem receiptItem;
  String status;
  Item? match;

  MatchedItem({required this.receiptItem, this.status = 'No Match', this.match});
}

class MatchedItemsNotifier extends StateNotifier<List<MatchedItem>> {
  MatchedItemsNotifier(List<ParsedReceiptItem> receiptItems)
      : super(receiptItems.map((item) => MatchedItem(receiptItem: item)).toList());

  List<MatchedItem> get confirmedItems =>
      state.where((item) => item.status.startsWith('Confirmed')).toList();
  List<MatchedItem> get matchedItems =>
      state.where((item) => item.status.startsWith('Matched')).toList();
  List<MatchedItem> get unmatchedItems =>
      state.where((item) => item.status.startsWith('No Match')).toList();

  void addItemsToInventory(Repository repo, ParsedReceipt receipt) {
    final time = receipt.date ?? DateTime.now();
    bool addedAlready = false;

    for (final matchedItem in state) {
      final item = matchedItem.match;

      // Only process items that have been matched (and are not null)
      if (item != null) {
        var inventory = repo.inv.get(item.upc);

        if (inventory != null) {
          // Check to see if we already added this inventory item to the
          // history within the last 24 hours
          addedAlready = wasInventoryAddedAlready(inventory, time);

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

        // Only make changes to the inventory if we haven't added it already
        if (!addedAlready) {
          final newHistory =
              inventory.history.add(time.millisecondsSinceEpoch, inventory.amount, 2);
          repo.inv.put(inventory);
          repo.hist.put(newHistory);
        }

        // If we have a confirmed item and the barcode type is not UPC,
        // add the identifier
        if (matchedItem.status.startsWith('Confirmed')) {
          // First, add the UPC identifier
          final upcIdentifier = Identifier(
            type: IdentifierType.upc,
            value: item.upc,
            uid: item.uid,
          );
          repo.identifiers.put(upcIdentifier);

          // If the barcode type is not UPC, add the identifier
          if (receipt.barcodeType != IdentifierType.upc) {
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
  }

  void clearStatus(int index) {
    var currentMatchedItem = state[index];
    currentMatchedItem.status = 'No Match';
    currentMatchedItem.match = null;
    state = [...state];
  }

  bool isWithinDuration(DateTime time, DateTime otherTime, Duration duration) {
    return time.difference(otherTime).abs() <= duration;
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

  /// Check to see if the inventory level was increased within 24 hours
  bool wasInventoryAddedAlready(Inventory inventory, DateTime time) {
    const timeFrame = Duration(days: 1);
    final history = inventory.history;
    final currentSeries = history.current;

    for (final observation in currentSeries.observations) {
      final observationTime = DateTime.fromMillisecondsSinceEpoch(observation.timestamp.round());

      if (isWithinDuration(time, observationTime, timeFrame)) {
        return true;
      }
    }

    return false;
  }
}
