import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/database/joined_item_database.dart';
import 'package:repository/model/receipt_item.dart';
import 'package:thingzee/pages/detail/widget/material_card_widget.dart';
import 'package:thingzee/pages/inventory/state/inventory_view.dart';
import 'package:thingzee/pages/receipt_scanner/widget/browser_page.dart';

class ItemMatchPage extends ConsumerStatefulWidget {
  final ReceiptItem receiptItem;
  final String searchUrl;
  const ItemMatchPage({super.key, required this.receiptItem, required this.searchUrl});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ItemMatchPageState();

  static Future<JoinedItem?> push(
      BuildContext context, ReceiptItem receiptItem, String searchUrl) async {
    return await Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => ItemMatchPage(receiptItem: receiptItem, searchUrl: searchUrl)),
    );
  }

  static Future<JoinedItem?> pushReplacement(
      BuildContext context, ReceiptItem receiptItem, String searchUrl) async {
    return await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
          builder: (context) => ItemMatchPage(receiptItem: receiptItem, searchUrl: searchUrl)),
    );
  }
}

class _ItemMatchPageState extends ConsumerState<ItemMatchPage> {
  String searchQuery = '';
  late TextEditingController _controller;

  @override
  Widget build(BuildContext context) {
    List<JoinedItem> items = ref.watch(inventoryProvider);
    ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Match: ${widget.receiptItem.name}'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () => openSearchUrl(context, widget.searchUrl),
            tooltip: 'Open Link',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: _controller,
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
                ref.read(inventoryProvider.notifier).fuzzySearch(value);
              },
              decoration: InputDecoration(
                labelText: 'Search',
                hintText: 'Type to search items',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                prefixIcon: Icon(Icons.search, color: theme.iconTheme.color),
                filled: true,
                fillColor: theme.inputDecorationTheme.fillColor ?? theme.canvasColor,
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: theme.colorScheme.background,
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  JoinedItem item = items[index];
                  return MaterialCardWidget(
                    children: [
                      ListTile(
                        title: Text(item.item.name, style: theme.textTheme.titleMedium),
                        onTap: () {
                          Navigator.of(context).pop(item);
                        },
                      ),
                    ],
                  );
                },
              ),
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

  Future<void> openSearchUrl(BuildContext context, String url) async {
    if (url.isNotEmpty) {
      await BrowserPage.push(context, url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No search URL available.')),
      );
    }
  }
}
