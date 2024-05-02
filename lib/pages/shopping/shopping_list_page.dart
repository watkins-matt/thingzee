import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:thingzee/pages/bottom_nav_bar/state/bottom_nav_state.dart';
import 'package:thingzee/pages/inventory/state/inventory_view.dart';
import 'package:thingzee/pages/shopping/confirmation_dialog.dart';
import 'package:thingzee/pages/shopping/state/shopping_list.dart';
import 'package:thingzee/pages/shopping/widget/shopping_cart_tab.dart';
import 'package:thingzee/pages/shopping/widget/shopping_list_tab.dart';

final tabIndexProvider = StateProvider<int>((ref) => 0);

class ShoppingListPage extends HookConsumerWidget {
  const ShoppingListPage({super.key});

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
                    children: const [
                      ShoppingListTab(),
                      ShoppingCartTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: buildFab(context, ref),
        ));
  }

  Widget? buildFab(BuildContext context, WidgetRef ref) {
    final tabIndex = ref.watch(tabIndexProvider);
    final cartItems = ref.watch(shoppingListProvider).cartItems;
    final totalCartPrice = ref.watch(shoppingListProvider.notifier).totalCartPrice;

    if (tabIndex == 1 && cartItems.isNotEmpty) {
      if (totalCartPrice > 0) {
        return FloatingActionButton.extended(
          onPressed: () => _handleTripCompleted(context, ref),
          tooltip: 'Complete Shopping',
          icon: const Icon(Icons.check),
          label:
              totalCartPrice > 0 ? Text('\$${totalCartPrice.toStringAsFixed(2)}') : const Text(''),
        );
      } else {
        return FloatingActionButton(
          onPressed: () => _handleTripCompleted(context, ref),
          tooltip: 'Complete Shopping',
          child: const Icon(Icons.check),
        );
      }
    }

    // Don't show the FAB on the shopping list tab, or if the cart is empty
    return null;
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

  static Future<void> push(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ShoppingListPage()),
    );
  }
}
