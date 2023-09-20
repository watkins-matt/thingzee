import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:thingzee/pages/bottom_nav_bar/state/bottom_nav_state.dart';
import 'package:thingzee/pages/inventory/state/inventory_view.dart';
import 'package:thingzee/pages/shopping/confirmation_dialog.dart';
import 'package:thingzee/pages/shopping/state/shopping_cart.dart';
import 'package:thingzee/pages/shopping/state/shopping_list.dart';
import 'package:thingzee/pages/shopping/widget/shopping_cart_list_tile.dart';

class ShoppingCartPage extends ConsumerWidget {
  const ShoppingCartPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton.icon(
              onPressed: () => _handleTripCompleted(context, ref),
              icon: const Icon(Icons.check),
              label: const Text('Done'))
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              itemBuilder: (context, index) => _buildShoppingCartItem(context, index, ref),
              separatorBuilder: (context, index) => _buildShoppingCartSeparator(),
              itemCount: _getShoppingCartItemCount(ref),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShoppingCartItem(BuildContext context, int index, WidgetRef ref) {
    final item = ref.watch(shoppingCartProvider).items[index];
    return ShoppingCartListTile(joinedItem: item, index: index);
  }

  Widget _buildShoppingCartSeparator() {
    return const Divider(height: 1, color: Colors.grey);
  }

  int _getShoppingCartItemCount(WidgetRef ref) {
    return ref.watch(shoppingCartProvider).items.length;
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

      // Hide the shopping cart page
      if (context.mounted) Navigator.pop(context);
    }
  }

  static Future<void> push(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ShoppingCartPage()),
    );
  }
}
