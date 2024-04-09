import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:receipt_ocr/post_scan_handler.dart';
import 'package:receipt_ocr/receipt_scanner.dart';
import 'package:thingzee/pages/bottom_nav_bar/state/bottom_nav_state.dart';
import 'package:thingzee/pages/inventory/state/inventory_view.dart';
import 'package:thingzee/pages/receipt_scanner/receipt_confirmation_page.dart';
import 'package:thingzee/pages/shopping/confirmation_dialog.dart';
import 'package:thingzee/pages/shopping/state/shopping_cart.dart';
import 'package:thingzee/pages/shopping/state/shopping_list.dart';
import 'package:thingzee/pages/shopping/widget/shopping_cart_list_tile.dart';
import 'package:thingzee/pages/shopping/widget/shopping_list_tile.dart';

class ShoppingListPage extends ConsumerWidget {
  const ShoppingListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          title: const Text('Shopping'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Shopping List'),
              Tab(text: 'Shopping Cart'),
            ],
          ),
          actions: [
            IconButton(
              style: IconButton.styleFrom(
                  foregroundColor: Theme.of(context).bottomNavigationBarTheme.selectedItemColor),
              icon: const Icon(Icons.camera_alt),
              tooltip: 'Scan Receipt',
              onPressed: () => _navigateToReceiptScannerPage(context),
            ),
            TextButton.icon(
                style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).bottomNavigationBarTheme.selectedItemColor),
                onPressed: () => _handleTripCompleted(context, ref),
                icon: const Icon(
                  Icons.check,
                ),
                label: const Text('Done'))
          ],
        ),
        body: TabBarView(
          children: [
            shoppingListTab(context, ref),
            shoppingCartTab(context, ref),
          ],
        ),
      ),
    );
  }

  Widget shoppingCartBuilder(BuildContext context, WidgetRef ref, int index, ShoppingCartState sc) {
    final joinedItem = sc.items[index];
    return ShoppingCartListTile(joinedItem: joinedItem, index: index);
  }

  Widget shoppingCartTab(BuildContext context, WidgetRef ref) {
    final sc = ref.watch(shoppingCartProvider);
    return sc.items.isEmpty
        ? const Center(
            child: Text(
              'Your shopping cart is empty.',
              style: TextStyle(fontSize: 18),
            ),
          )
        : ListView.builder(
            itemBuilder: (context, index) => shoppingCartBuilder(context, ref, index, sc),
            itemCount: sc.items.length,
          );
  }

  Widget shoppingListItemBuilder(
      BuildContext context, WidgetRef ref, int index, ShoppingListState sl, ShoppingCartState sc) {
    final joinedItem = sl.items[index];
    return ShoppingListTile(
      index: index,
      joinedItem: joinedItem,
      sl: sl,
      sc: sc,
      ref: ref,
    );
  }

  Widget shoppingListTab(BuildContext context, WidgetRef ref) {
    final sl = ref.watch(shoppingListProvider);
    final sc = ref.watch(shoppingCartProvider);

    return sl.items.isEmpty
        ? const Center(
            child: Text(
              'You are not running out of anything yet.',
              style: TextStyle(fontSize: 18),
            ),
          )
        : ListView.builder(
            itemBuilder: (context, index) => shoppingListItemBuilder(context, ref, index, sl, sc),
            itemCount: sl.items.length,
          );
  }

  Future<void> _handleTripCompleted(BuildContext context, WidgetRef ref) async {
    // Show confirmation dialog
    if (await TripCompletedConfirmationDialog.show(context)) {
      // Complete trip will update inventory information
      ref.read(shoppingCartProvider.notifier).completeTrip();

      // Refresh the list and inventory view
      ref.read(shoppingListProvider.notifier).refresh();
      await ref.read(inventoryProvider.notifier).refresh();

      // Switch back to the inventory view tab
      ref.read(bottomNavBarIndexProvider.notifier).state = 0;
    }
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
    // Navigator.push(
    //     context,
    //     MaterialPageRoute(
    //         builder: (context) => LiveReceiptScannerPage(postScanHandler: DebugPostScanHandler())));
  }

  static Future<void> push(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ShoppingListPage()),
    );
  }
}
