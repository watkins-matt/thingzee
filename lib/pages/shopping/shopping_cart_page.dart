import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:thingzee/pages/shopping/confirmation_dialog.dart';
import 'package:thingzee/pages/shopping/state/shopping_cart.dart';
import 'package:thingzee/pages/shopping/widget/shopping_cart_list_tile.dart';

class ShoppingCartPage extends ConsumerWidget {
  const ShoppingCartPage({Key? key}) : super(key: key);

  static Future<void> push(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ShoppingCartPage()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton.icon(
              onPressed: () async {
                if (await TripCompletedConfirmationDialog.show(context)) {
                  ref.read(shoppingCartProvider.notifier).completeTrip();
                  // ref.read(shoppingListProvider.notifier).refresh();
                }
              },
              icon: const Icon(Icons.check),
              label: const Text('Done'))
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              itemBuilder: (context, index) {
                final item = ref.watch(shoppingCartProvider).items[index];
                return ShoppingCartListTile(joinedItem: item, index: index);
              },
              separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.grey),
              itemCount: ref.watch(shoppingCartProvider).items.length,
            ),
          ),
        ],
      ),
    );
  }
}
