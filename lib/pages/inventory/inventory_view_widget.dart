import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/model/inventory.dart';
import 'package:thingzee/pages/inventory/item_list_tile.dart';
import 'package:thingzee/pages/inventory/state/inventory_view.dart';

class InventoryViewWidget extends ConsumerWidget {
  const InventoryViewWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(inventoryProvider);

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        children: [
          Expanded(
              child: ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: products.length + 1,
            itemBuilder: (context, index) => buildItem(context, ref, index),
            separatorBuilder: (context, index) => const Divider(
              color: Colors.grey,
            ),
          )),
        ],
      ),
    );
  }

  Widget buildItem(BuildContext context, WidgetRef ref, int index) {
    if (index == 0) return const ListTile();

    final products = ref.watch(inventoryProvider);
    final inventoryMap = ref.read(inventoryProvider.notifier).inventory;
    final productUpc = products[index - 1].upc;
    final product = products[index - 1];

    // We create a new inventory if it doesn't exist. Note that changing
    // the upc here updates the upc in History as well so the state remains
    // valid.
    final inventory = inventoryMap[productUpc] ?? Inventory.withUPC(productUpc);

    return Dismissible(
      key: Key(productUpc),
      dismissThresholds: const {
        DismissDirection.endToStart: 0.9,
        DismissDirection.startToEnd: 0.9,
      },
      onDismissed: (direction) {
        ref.read(inventoryProvider.notifier).delete(inventory);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$product.name deleted from inventory.'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                ref.read(inventoryProvider.notifier).add(inventory);
              },
            ),
          ),
        );
      },
      background: Container(color: Colors.red),
      child: ItemListTile(product, inventory),
    );
  }
}
