import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/model/item.dart';
import 'package:repository/model/receipt.dart';
import 'package:repository/model/receipt_item.dart';
import 'package:thingzee/pages/inventory/state/inventory_view.dart';
import 'package:thingzee/pages/item_match/item_match_page.dart';
import 'package:thingzee/pages/receipt_scanner/parser/parser.dart';

// A provider that holds the match status for each receipt item.
final itemMatchProvider = StateProvider.family<List<String>, List<ReceiptItem>>((ref, items) {
  return List.generate(items.length, (index) => 'No Match');
});

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
    List<String> matchStatuses = ref.watch(itemMatchProvider(widget.receipt.items));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Receipt Items'),
      ),
      body: ListView.builder(
        itemCount: widget.receipt.items.length,
        itemBuilder: (context, index) {
          final item = widget.receipt.items[index];
          final matchStatus = matchStatuses[index];

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

              // Update the status when an item is confirmed.
              if (result != null) {
                ref.read(itemMatchProvider(widget.receipt.items).notifier).update((state) {
                  state[index] = 'Confirmed ${result.name}';
                  return state;
                });
                setState(() {});
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

  void performInitialFuzzySearch() {
    final currentStatuses = ref.read(itemMatchProvider(widget.receipt.items));

    // Iterate through each item and perform a fuzzy search if not already matched or confirmed.
    for (int i = 0; i < widget.receipt.items.length; i++) {
      // Skip if already matched or confirmed.
      if (currentStatuses[i].startsWith('Matched') || currentStatuses[i].startsWith('Confirmed')) {
        continue;
      }

      ReceiptItem item = widget.receipt.items[i];
      final provider = ref.read(inventoryProvider.notifier);
      final itemDb = provider.r.items;

      final query = _getSearchQuery(item);
      if (query.isEmpty) {
        continue;
      }

      List<Item> matches = itemDb.fuzzySearch(query);

      // Check if there's a single match or a small number of matches.
      if (matches.length <= 3 && matches.isNotEmpty) {
        // Update the match status for this item.
        ref.read(itemMatchProvider(widget.receipt.items).notifier).update((state) {
          state[i] = 'Matched ${matches.first.name}';
          return state;
        });
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
}
