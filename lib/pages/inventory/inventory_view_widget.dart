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
    final inventory = ref.read(inventoryProvider.notifier).inventory;
    final productUpc = products[index - 1].upc;

    return ItemListTile(
        products[index - 1],
        inventory[productUpc] ?? Inventory()
          ..upc = productUpc);
  }
}
