import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:log/log.dart';
import 'package:repository/model/item.dart';
import 'package:repository/model/receipt_item.dart';
import 'package:thingzee/icon_library.dart';
import 'package:thingzee/pages/barcode/barcode_scanner_page.dart';
import 'package:thingzee/pages/detail/widget/material_card_widget.dart';
import 'package:thingzee/pages/inventory/state/item_view.dart';
import 'package:thingzee/pages/item_match/widget/add_item_browser_page.dart';
import 'package:thingzee/pages/item_match/widget/text_button_with_dropdown.dart';
import 'package:url_launcher/url_launcher.dart';

class ItemMatchPage extends ConsumerStatefulWidget {
  final ReceiptItem receiptItem;
  final String searchUrl;
  const ItemMatchPage({super.key, required this.receiptItem, required this.searchUrl});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ItemMatchPageState();

  static Future<Item?> push(BuildContext context, ReceiptItem receiptItem, String searchUrl) async {
    return await Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => ItemMatchPage(receiptItem: receiptItem, searchUrl: searchUrl)),
    );
  }

  static Future<Item?> pushReplacement(
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

  void addNewItemFromWeb(BuildContext context) {
    AddItemBrowserPage.push(context, widget.searchUrl).then((item) {
      if (item != null) {
        Navigator.of(context).pop(item);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Item> items = ref.watch(itemViewProvider);
    ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiptItem.name),
        backgroundColor: theme.appBarTheme.backgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.app_registration, color: Colors.white),
            onPressed: () => openSearchUrl(context, widget.searchUrl),
          ),
          TextButtonWithDropdown<String>(
            label: 'Add New',
            icon: Icons.add,
            menuItems: const {
              'web': 'From Web',
              'scan': 'By Scanning Barcode',
            },
            onSelected: (string) => handleAddNewAction(context, string),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'FabItemMatchAddNewBarcode',
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const BarcodeScannerPage(BarcodeScannerMode.showItemDetail)),
          );
        },
        tooltip: 'New Item',
        icon: const Icon(IconLibrary.barcode),
        label: const Text('New Item'),
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
                ref.read(itemViewProvider.notifier).fuzzySearch(value);
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
                  Item item = items[index];
                  return MaterialCardWidget(
                    children: [
                      ListTile(
                        title: Text(item.name, style: theme.textTheme.titleMedium),
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

  void handleAddNewAction(BuildContext context, String? action) {
    switch (action) {
      case 'web':
        addNewItemFromWeb(context);
        break;
      // case 'scan':
      //   addNewItemByScanning(context);
      //   break;
      default:
        Log.e('Unknown action: $action');
    }
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
    ref.read(itemViewProvider.notifier).fuzzySearch(searchQuery);
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
      // await BrowserPage.push(context, url);
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        Log.e('Could not launch $uri');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No search URL available.')),
      );
    }
  }
}
