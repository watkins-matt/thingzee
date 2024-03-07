import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/model/item.dart';
import 'package:repository/model/receipt.dart';
import 'package:repository/model/receipt_item.dart';
import 'package:thingzee/main.dart';
import 'package:thingzee/pages/bottom_nav_bar/state/bottom_nav_state.dart';
import 'package:thingzee/pages/inventory/state/inventory_view.dart';
import 'package:thingzee/pages/item_match/item_match_page.dart';
import 'package:thingzee/pages/receipt_scanner/parser/parser.dart';
import 'package:thingzee/pages/receipt_scanner/state/matched_item.dart';

class ReceiptConfirmationPage extends ConsumerStatefulWidget {
  final Receipt receipt;
  final ReceiptParser parser;
  const ReceiptConfirmationPage({super.key, required this.receipt, required this.parser});

  @override
  ConsumerState<ReceiptConfirmationPage> createState() => _ReceiptConfirmationPageState();

  static Future<void> push(BuildContext context, Receipt receipt, ReceiptParser parser) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ReceiptConfirmationPage(receipt: receipt, parser: parser)),
    );
  }

  static Future<void> pushReplacement(
      BuildContext context, Receipt receipt, ReceiptParser parser) async {
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => ReceiptConfirmationPage(receipt: receipt, parser: parser)),
    );
  }
}

class _ReceiptConfirmationPageState extends ConsumerState<ReceiptConfirmationPage> {
  @override
  Widget build(BuildContext context) {
    List<MatchedItem> matchedItems = ref.watch(matchedItemsProvider(widget.receipt.items));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Receipt Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () async => await onDoneButtonPressed(context, ref),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: matchedItems.length,
        itemBuilder: (context, index) {
          final matchedItem = matchedItems[index];
          final item = matchedItem.receiptItem;
          final matchStatus = matchedItem.status;

          return ListTile(
            title: Text(item.name),
            subtitle: Text(
              matchStatus,
              style: TextStyle(
                  color: matchStatus.startsWith('Matched')
                      ? Colors.green
                      : matchStatus.startsWith('Confirmed')
                          ? Colors.blue
                          : Colors.red),
            ),
            onTap: () async {
              final result = await ItemMatchPage.push(context, item,
                  widget.parser.getSearchUrl(item.barcode.isNotEmpty ? item.barcode : item.name));

              if (result != null) {
                ref
                    .read(matchedItemsProvider(widget.receipt.items).notifier)
                    .updateStatus(index, 'Confirmed ${result.name}');
              }
            },
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        performInitialFuzzySearch();
      });
    });
  }

  Future<bool> onDoneButtonPressed(BuildContext context, WidgetRef ref) async {
    // Access the MatchedItemsNotifier using matchedItemsProvider
    final matchedItemsNotifier = ref.read(matchedItemsProvider(widget.receipt.items).notifier);

    // Directly use unmatchedItems from MatchedItemsNotifier
    final unmatchedItems = matchedItemsNotifier.unmatchedItems;

    if (unmatchedItems.isNotEmpty) {
      // Call showConfirmationDialog with the count of unmatched items
      final proceedWithUnmatched = await showConfirmationDialog(context, unmatchedItems.length);
      if (!proceedWithUnmatched) {
        return false;
      }

      // Add all items to the inventory
      final repo = ref.watch(repositoryProvider);
      final receipt = widget.receipt;
      matchedItemsNotifier.addItemsToInventory(repo, receipt);

      // Refresh the inventory provider
      await ref.read(inventoryProvider.notifier).refresh();

      // Switch back to the inventory view tab
      ref.read(bottomNavBarIndexProvider.notifier).state = 0;
    }

    return true;
  }

  void performInitialFuzzySearch() {
    final matchedItemsNotifier = ref.read(matchedItemsProvider(widget.receipt.items).notifier);
    final matchedItems = ref.read(matchedItemsProvider(widget.receipt.items));

    // Iterate through each item and perform a fuzzy search if not already matched or confirmed.
    for (int i = 0; i < matchedItems.length; i++) {
      final matchedItem = matchedItems[i];

      // Skip if already matched or confirmed.
      if (matchedItem.status.startsWith('Matched') || matchedItem.status.startsWith('Confirmed')) {
        continue;
      }

      ReceiptItem item = matchedItem.receiptItem;
      final provider = ref.read(inventoryProvider.notifier);
      final itemDb = provider.r.items;

      final query = _getSearchQuery(item);
      if (query.isEmpty) {
        continue;
      }

      List<Item> matches = itemDb.fuzzySearch(query);

      // Check if there's a single match or a small number of matches.
      if (matches.isNotEmpty && matches.length <= 3) {
        // Update the match status for this item.
        matchedItemsNotifier.updateStatus(i, 'Matched ${matches.first.name}');
      }
    }
  }

  String _getSearchQuery(ReceiptItem item) {
    String name = item.name;
    // Find the first word in the name, ignoring leading punctuation and considering only letters.
    RegExp regex = RegExp(r'\b[a-zA-Z]{3,}\b');
    Match? match = regex.firstMatch(name);

    if (match != null) {
      // Set the found word as the initial search query
      return name.substring(match.start, match.end);
    }

    return '';
  }

  static Future<bool> showConfirmationDialog(BuildContext context, int unmatchedItemCount) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Unmatched Items'),
          content: Text(
              'There are $unmatchedItemCount unmatched items. Are you sure you want to proceed?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Proceed'),
            ),
          ],
        );
      },
    );
    return result ?? false; // Ensure we return false if dialog is dismissed
  }
}
