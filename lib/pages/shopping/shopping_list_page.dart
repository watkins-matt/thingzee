import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:receipt_ocr/post_scan_handler.dart';
import 'package:receipt_ocr/receipt_scanner.dart';
import 'package:repository/model/shopping_item.dart';
import 'package:thingzee/pages/bottom_nav_bar/state/bottom_nav_state.dart';
import 'package:thingzee/pages/inventory/state/inventory_view.dart';
import 'package:thingzee/pages/receipt_scanner/receipt_confirmation_page.dart';
import 'package:thingzee/pages/shopping/confirmation_dialog.dart';
import 'package:thingzee/pages/shopping/state/shopping_list.dart';
import 'package:thingzee/pages/shopping/widget/shopping_list_tile.dart';

class ShoppingListPage extends ConsumerWidget {
  const ShoppingListPage({super.key});

  Future<void> addItem(BuildContext context, WidgetRef ref) async {
    ShoppingItem? newItem = await showDialog<ShoppingItem>(
        context: context,
        builder: (BuildContext context) {
          throw UnimplementedError();
        });

    if (newItem != null) {
      await ref.read(shoppingListProvider.notifier).add(newItem);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(shoppingListProvider);

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

  Widget shoppingCartItemBuilder(BuildContext context, WidgetRef ref, ShoppingItem item) {
    return ShoppingListTile(
      item: item,
      editable: false,
      checkbox: false,
    );
  }

  Widget shoppingCartTab(BuildContext context, WidgetRef ref) {
    final shoppingProvider = ref.watch(shoppingListProvider);
    final items = shoppingProvider.cartItems;

    return items.isEmpty
        ? const Center(
            child: Text(
              'Your shopping cart is empty.',
              style: TextStyle(fontSize: 18),
            ),
          )
        : ListView.builder(
            itemBuilder: (context, index) => shoppingCartItemBuilder(context, ref, items[index]),
            itemCount: items.length,
          );
  }

  Widget shoppingListItemBuilder(BuildContext context, WidgetRef ref, ShoppingItem item) {
    return ShoppingListTile(item: item, editable: true, checkbox: true);
  }

  Widget shoppingListTab(BuildContext context, WidgetRef ref) {
    final shoppingList = ref.watch(shoppingListProvider);
    final items = shoppingList.shoppingItems;

    return items.isEmpty
        ? const Center(
            child: Text(
              'You are not running out of anything yet.',
              style: TextStyle(fontSize: 18),
            ),
          )
        : ListView.builder(
            itemBuilder: (context, index) => shoppingListItemBuilder(context, ref, items[index]),
            itemCount: items.length,
          );
  }

  Future<void> _handleTripCompleted(BuildContext context, WidgetRef ref) async {
    // Show confirmation dialog
    if (await TripCompletedConfirmationDialog.show(context)) {
      // Complete trip will update inventory information
      ref.read(shoppingListProvider.notifier).completeTrip();

      // Refresh the list and inventory view
      await ref.read(shoppingListProvider.notifier).refreshAll();
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
  }

  static Future<void> push(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ShoppingListPage()),
    );
  }
}
