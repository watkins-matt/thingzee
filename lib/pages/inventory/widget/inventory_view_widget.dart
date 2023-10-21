import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:thingzee/pages/inventory/state/inventory_view.dart';
import 'package:thingzee/pages/inventory/widget/item_list_tile.dart';

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

    final joinedItemList = ref.watch(inventoryProvider);
    final joinedItem = joinedItemList[index - 1];
    final item = joinedItem.item;
    final inventory = joinedItem.inventory;

    bool showBranded = ref.read(inventoryProvider.notifier).filter.displayBranded;

    return Dismissible(
      key: Key(item.upc),
      dismissThresholds: const {
        DismissDirection.endToStart: 0.9,
        DismissDirection.startToEnd: 0.9,
      },
      onDismissed: (direction) {
        ref.read(inventoryProvider.notifier).deleteInventory(inventory);

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} deleted.'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                ref.read(inventoryProvider.notifier).addInventory(inventory);
              },
            ),
          ),
        );
      },
      background: Container(color: Colors.red),
      child: ItemListTile(item, inventory, key: ValueKey(item.upc), brandedName: showBranded),
    );
  }
}
