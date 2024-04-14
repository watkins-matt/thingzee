import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:receipt_ocr/post_scan_handler.dart';
import 'package:receipt_ocr/receipt_scanner.dart';
import 'package:repository/database/shopping_list_database.dart';
import 'package:repository/model/shopping_item.dart';
import 'package:thingzee/pages/bottom_nav_bar/state/bottom_nav_state.dart';
import 'package:thingzee/pages/inventory/state/inventory_view.dart';
import 'package:thingzee/pages/receipt_scanner/receipt_confirmation_page.dart';
import 'package:thingzee/pages/shopping/confirmation_dialog.dart';
import 'package:thingzee/pages/shopping/state/shopping_list.dart';
import 'package:thingzee/pages/shopping/widget/shopping_list_tile.dart';

final tabIndexProvider = StateProvider<int>((ref) => 0);

class ShoppingListPage extends HookConsumerWidget {
  const ShoppingListPage({super.key});

  Future<void> addNewItem(BuildContext context, WidgetRef ref) async {
    final shoppingList = ref.read(shoppingListProvider);
    final items = shoppingList.shoppingItems;

    // Don't add a new item if the last item is already a new item
    if (items.isNotEmpty && items.last.name.isEmpty) {
      return;
    }

    final newItem = ShoppingItem(listName: ShoppingListName.shopping);
    await ref.read(shoppingListProvider.notifier).add(newItem);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabController = useTabController(initialLength: 2);
    ref.watch(shoppingListProvider);

    useEffect(() {
      tabController.addListener(() {
        ref.read(tabIndexProvider.notifier).state = tabController.index;
      });
      return tabController.dispose;
    }, [tabController]);

    return DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: Theme.of(context).brightness == Brightness.light
              ? Colors.white
              : Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              children: <Widget>[
                Material(
                  color: Theme.of(context).appBarTheme.backgroundColor,
                  child: TabBar(
                    controller: tabController,
                    labelColor: Theme.of(context).textTheme.bodyLarge?.color,
                    tabs: const [
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.list_alt_outlined),
                            SizedBox(width: 8),
                            Text('Shopping List'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shopping_cart_outlined),
                            SizedBox(width: 8),
                            Text('Shopping Cart'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: tabController,
                    children: [
                      shoppingListTab(context, ref),
                      shoppingCartTab(context, ref),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: ref.watch(tabIndexProvider) == 1 &&
                  ref.watch(shoppingListProvider).cartItems.isNotEmpty
              ? FloatingActionButton(
                  onPressed: () => _handleTripCompleted(context, ref),
                  tooltip: 'Complete Shopping',
                  child: const Icon(Icons.check),
                )
              : null,
        ));
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

  Widget shoppingListItemBuilder(
      BuildContext context, WidgetRef ref, ShoppingItem item, bool isLastItem) {
    bool shouldAutoFocus = isLastItem && item.name.isEmpty;
    return ShoppingListTile(item: item, editable: true, checkbox: true, autoFocus: shouldAutoFocus);
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
        : shoppingListViewBuilder(context, ref, items);
  }

  Widget shoppingListViewBuilder(BuildContext context, WidgetRef ref, List<ShoppingItem> items) {
    return ListView.builder(
      itemCount: items.length + 1,
      itemBuilder: (context, index) {
        if (index == items.length) {
          // This is the "Add new item" tile
          return ListTile(
            leading: const Icon(Icons.add),
            title: const Text('List Item'),
            onTap: () => addNewItem(context, ref),
          );
        }
        return shoppingListItemBuilder(context, ref, items[index], index == items.length - 1);
      },
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
