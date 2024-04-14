import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/model/item.dart';
import 'package:thingzee/icon_library.dart';
import 'package:thingzee/pages/barcode/quick_barcode_scanner.dart';
import 'package:thingzee/pages/inventory/state/item_view.dart';

class AddItemBrowserPage extends ConsumerStatefulWidget {
  final String initialUrl;
  const AddItemBrowserPage(this.initialUrl, {super.key});

  @override
  ConsumerState<AddItemBrowserPage> createState() => _AddItemBrowserPageState();

  static Future<Item?> push(BuildContext context, String initialUrl) async {
    return await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddItemBrowserPage(initialUrl)),
    );
  }
}

class _AddItemBrowserPageState extends ConsumerState<AddItemBrowserPage> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;
  late final TextEditingController urlController;
  late final TextEditingController itemNameController;
  late final TextEditingController itemUpcController;

  // Regular expression for matching a UPC.
  final RegExp upcRegex = RegExp(r'\b\d{12}\b');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search & Add Item'),
        actions: <Widget>[
          IconButton(
              icon: const Icon(Icons.save),
              onPressed: () {
                saveItemAndClose(context);
              })
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: itemNameController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                  ),
                  keyboardType: TextInputType.text,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.content_paste),
                onPressed: pasteSelectedText,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: itemUpcController,
                  decoration: const InputDecoration(
                    labelText: 'Item UPC',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              IconButton(
                  icon: const Icon(IconLibrary.barcode),
                  onPressed: () => pasteScannedBarcode(context)),
            ],
          ),
        ),
        Expanded(
          child: InAppWebView(
            key: webViewKey,
            shouldOverrideUrlLoading: shouldOverrideUrlLoading,
            onLongPressHitTestResult: onLongPressHitTestResult,
            initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
            onWebViewCreated: (controller) {
              webViewController = controller;
            },
            initialSettings: InAppWebViewSettings(
                useShouldOverrideUrlLoading: true,
                javaScriptEnabled: true,
                useHybridComposition: true),
          ),
        ),
      ]),
    );
  }

  @override
  void initState() {
    super.initState();
    urlController = TextEditingController(text: widget.initialUrl);
    itemNameController = TextEditingController();
    itemUpcController = TextEditingController();
  }

  Future<void> onLongPressHitTestResult(
      InAppWebViewController controller, InAppWebViewHitTestResult hitTestResult) async {
    String? selectedText = await controller.getSelectedText();
    if (selectedText != null && upcRegex.hasMatch(selectedText)) {
      String matchedUpc = upcRegex.firstMatch(selectedText)!.group(0)!;
      setState(() {
        itemUpcController.text = matchedUpc;
      });
    }
  }

  Future<void> pasteScannedBarcode(BuildContext context) async {
    String? barcode = await QuickBarcodeScanner.scanBarcode(context);

    if (barcode != null && barcode.isNotEmpty) {
      setState(() {
        itemUpcController.text = barcode;
      });
    }
  }

  Future<void> pasteSelectedText() async {
    String? selectedText = await webViewController?.getSelectedText();
    if (selectedText != null && selectedText.isNotEmpty) {
      setState(() {
        itemNameController.text = selectedText;
      });
    }
  }

  void saveItemAndClose(BuildContext context) {
    if (itemNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item name is required.'),
        ),
      );
      return;
    }

    if (itemUpcController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item UPC is required.'),
        ),
      );
      return;
    }

    final itemView = ref.read(itemViewProvider.notifier);
    final newItem = Item(
      upc: itemUpcController.text,
      name: itemNameController.text,
    );

    itemView.put(newItem);
    Navigator.pop(context, newItem);
  }

  Future<NavigationActionPolicy> shouldOverrideUrlLoading(
      InAppWebViewController controller, NavigationAction action) async {
    final request = action.request;
    final string = request.url.toString();

    if (string.startsWith('http://')) {
      final newUrl = string.replaceFirst('http://', 'https://');
      await controller.loadUrl(urlRequest: URLRequest(url: WebUri(newUrl)));
      urlController.text = newUrl;
      return NavigationActionPolicy.CANCEL;
    } else {
      urlController.text = string;
    }

    return NavigationActionPolicy.ALLOW;
  }
}
