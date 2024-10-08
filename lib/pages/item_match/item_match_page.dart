import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:log/log.dart';
import 'package:receipt_parser/model/receipt_item.dart';
import 'package:repository/model/item.dart';
import 'package:thingzee/pages/inventory/state/item_view.dart';
import 'package:thingzee/pages/item_match/widget/add_item_browser_page.dart';
import 'package:thingzee/pages/item_match/widget/draggable_bottom_sheet.dart';
import 'package:thingzee/pages/item_match/widget/potential_match_list_tile.dart';
import 'package:thingzee/pages/item_match/widget/text_button_with_dropdown.dart';

class ItemMatchPage extends ConsumerStatefulWidget {
  final ParsedReceiptItem receiptItem;
  final String searchUrl;

  const ItemMatchPage({super.key, required this.receiptItem, required this.searchUrl});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ItemMatchPageState();

  static Future<Item?> push(
      BuildContext context, ParsedReceiptItem receiptItem, String searchUrl) async {
    return await Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => ItemMatchPage(receiptItem: receiptItem, searchUrl: searchUrl)),
    );
  }

  static Future<Item?> pushReplacement(
      BuildContext context, ParsedReceiptItem receiptItem, String searchUrl) async {
    return await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
          builder: (context) => ItemMatchPage(receiptItem: receiptItem, searchUrl: searchUrl)),
    );
  }
}

class _ItemMatchPageState extends ConsumerState<ItemMatchPage> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  final DraggableBottomSheetController _bottomSheetController = DraggableBottomSheetController();
  String searchQuery = '';

  void addNewItemFromWeb(BuildContext context) {
    AddItemBrowserPage.push(context, widget.searchUrl).then((item) {
      if (item != null) {
        if (context.mounted) {
          Navigator.of(context).pop(item);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiptItem.name),
        backgroundColor: theme.appBarTheme.backgroundColor,
        actions: [
          TextButtonWithDropdown<String>(
            label: 'Add New',
            icon: Icons.add,
            menuItems: const {
              'web': 'From Web',
              'scan': 'By Scanning Barcode',
            },
            onSelected: (string) => onAddNewItemSelected(context, string),
          ),
        ],
      ),
      body: buildBody(context),
      bottomSheet: DraggableBottomSheet(controller: _bottomSheetController, child: buildWebView()),
    );
  }

  Widget buildBody(BuildContext context) {
    List<Item> items = ref.watch(itemViewProvider);
    ThemeData theme = Theme.of(context);

    return Padding(
      // Padding to ensure the content is not covered by the bottom sheet
      padding: const EdgeInsets.only(bottom: 30),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: onSearchTextChanged,
                  decoration: InputDecoration(
                    labelText: 'Search',
                    hintText: 'Type to search items',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                    prefixIcon: Icon(Icons.search, color: theme.iconTheme.color),
                    filled: true,
                    fillColor: theme.inputDecorationTheme.fillColor ?? theme.canvasColor,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: onClearButtonPressed,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: theme.colorScheme.surface,
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  Item item = items[index];

                  return PotentialItemMatchTile(
                      item: item, onTap: () => Navigator.of(context).pop(item));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildWebView() {
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(widget.searchUrl)),
      initialSettings: InAppWebViewSettings(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
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

      // Remove trailing 's' if it exists
      if (searchQuery.endsWith('s') || searchQuery.endsWith('S')) {
        searchQuery = searchQuery.substring(0, searchQuery.length - 1);
      }
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
    _focusNode = FocusNode();

    // Listen for focus changes
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );

        _bottomSheetController.collapse();
      }
    });

    // Schedule a microtask to perform initial search after the build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeSearchQuery();
    });
  }

  void onAddNewItemSelected(BuildContext context, String? action) {
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

  void onClearButtonPressed() {
    setState(() {
      _controller.clear();
      searchQuery = '';
      _focusNode.requestFocus();
    });
    ref.read(itemViewProvider.notifier).fuzzySearch('');
  }

  void onSearchTextChanged(String value) {
    setState(() {
      searchQuery = value;
    });
    ref.read(itemViewProvider.notifier).fuzzySearch(value);
  }
}
