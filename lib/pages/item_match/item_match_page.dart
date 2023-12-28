import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/database/joined_item_database.dart';
import 'package:repository/model/receipt_item.dart';
import 'package:thingzee/pages/inventory/state/inventory_view.dart';

class ItemMatchPage extends ConsumerStatefulWidget {
  final ReceiptItem receiptItem;
  const ItemMatchPage({super.key, required this.receiptItem});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ItemMatchPageState();

  static Future<void> push(BuildContext context, ReceiptItem receiptItem) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => ItemMatchPage(receiptItem: receiptItem)),
    );
  }

  static Future<void> pushReplacement(BuildContext context, ReceiptItem receiptItem) async {
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => ItemMatchPage(receiptItem: receiptItem)),
    );
  }
}

class _ItemMatchPageState extends ConsumerState<ItemMatchPage> {
  String searchQuery = '';
  late TextEditingController _controller;

  @override
  Widget build(BuildContext context) {
    List<JoinedItem> items = ref.watch(inventoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Match Item: ${widget.receiptItem.name}'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _controller,
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
                ref.read(inventoryProvider.notifier).fuzzySearch(value);
              },
              decoration: const InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                JoinedItem item = items[index];
                return ListTile(
                  title: Text(item.item.name),
                  subtitle: Text(item.item.type),
                  onTap: () {
                    // Handle item selection by popping the current page
                    // and returning the selected item
                    Navigator.of(context).pop(item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void initializeSearchQuery() {
    // Extract the first word from the receipt item's name that is >= 3 characters.
    String name = widget.receiptItem.name;
    // Find the first word in the name, ignoring leading punctuation and considering only letters.
    RegExp regex = RegExp(r'\b[a-zA-Z]{3,}\b');
    Match? match = regex.firstMatch(name);

    if (match != null) {
      // Set the found word as the initial search query
      searchQuery = name.substring(match.start, match.end);
    } else {
      // Default to an empty string if no matching word is found
      searchQuery = '';
    }

    _controller.text = searchQuery;
    ref.read(inventoryProvider.notifier).fuzzySearch(searchQuery);
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();

    // Schedule a microtask to perform initial search after the build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeSearchQuery();
    });
  }
}
