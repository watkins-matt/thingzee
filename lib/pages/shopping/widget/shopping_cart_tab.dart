import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:receipt_ocr/post_scan_handler.dart';
import 'package:receipt_ocr/receipt_scanner.dart';
import 'package:repository/model/shopping_item.dart';
import 'package:thingzee/pages/receipt_scanner/receipt_confirmation_page.dart';
import 'package:thingzee/pages/shopping/state/shopping_list.dart';
import 'package:thingzee/pages/shopping/widget/shopping_list_tile.dart';

class ShoppingCartTab extends ConsumerStatefulWidget {
  const ShoppingCartTab({super.key});

  @override
  ConsumerState<ShoppingCartTab> createState() => _ShoppingCartTabState();
}

class _ShoppingCartTabState extends ConsumerState<ShoppingCartTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final shoppingProvider = ref.watch(shoppingListProvider);
    final items = shoppingProvider.cartItems;

    return items.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Your shopping cart is empty.',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Scan Receipt'),
                  onPressed: () => _navigateToReceiptScannerPage(context),
                ),
              ],
            ),
          )
        : ListView.builder(
            itemBuilder: (context, index) => shoppingCartItemBuilder(context, ref, items[index]),
            itemCount: items.length,
          );
  }

  Widget shoppingCartItemBuilder(BuildContext context, WidgetRef ref, ShoppingItem item) {
    return ShoppingListTile(
      item: item,
      editable: false,
      checkbox: false,
    );
  }

  void _navigateToReceiptScannerPage(BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (newContext) => ReceiptScannerPage(postScanHandler: ShowReceiptDetailHandler(
                  onAcceptPressed: (context, receipt, parser) async {
                    await ReceiptConfirmationPage.push(context, receipt, parser);
                  },
                ))));
  }
}
