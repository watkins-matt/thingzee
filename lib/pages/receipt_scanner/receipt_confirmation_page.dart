import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/database/joined_item_database.dart';
import 'package:repository/model/receipt.dart';
import 'package:repository/model/receipt_item.dart';
import 'package:thingzee/pages/inventory/state/inventory_view.dart';
import 'package:thingzee/pages/item_match/item_match_page.dart';

// A provider that holds the match status for each receipt item.
final itemMatchProvider = StateProvider.family<List<String>, List<ReceiptItem>>((ref, items) {
  return List.generate(items.length, (index) => 'No Match');
});

class ReceiptConfirmationPage extends ConsumerStatefulWidget {
  final Receipt receipt;
  const ReceiptConfirmationPage({super.key, required this.receipt});

  @override
  ConsumerState<ReceiptConfirmationPage> createState() => _ReceiptConfirmationPageState();

  static Future<void> push(BuildContext context, Receipt receipt) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReceiptConfirmationPage(receipt: receipt)),
    );
  }

  static Future<void> pushReplacement(BuildContext context, Receipt receipt) async {
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ReceiptConfirmationPage(receipt: receipt)),
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
            subtitle: Text(matchStatus,
                style: TextStyle(
                    color: matchStatus.startsWith('Matched') ? Colors.green : Colors.red)),
            onTap: () {
              if (matchStatus == 'No Match') {
                ItemMatchPage.push(context, item);
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
    WidgetsBinding.instance.addPostFrameCallback((_) => performInitialFuzzySearch());
  }

  Future<void> performInitialFuzzySearch() async {
    // Iterate through each item and perform a fuzzy search.
    for (int i = 0; i < widget.receipt.items.length; i++) {
      ReceiptItem item = widget.receipt.items[i];
      final provider = ref.read(inventoryProvider.notifier);
      final joinedItemDb = provider.joinedItemDb;

      final query = _getSearchQuery(item);
      if (query.isEmpty) {
        continue;
      }

      List<JoinedItem> matches = joinedItemDb.fuzzySearch(query);

      // Check if there's a single match or a small number of matches.
      if (matches.length <= 3 && matches.isNotEmpty) {
        // Update the match status for this item.
        ref.read(itemMatchProvider(widget.receipt.items).notifier).update((state) {
          state[i] = 'Matched ${matches.first.item.name}';
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
