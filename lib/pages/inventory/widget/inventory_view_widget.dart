import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:thingzee/pages/inventory/state/inventory_display.dart';
import 'package:thingzee/pages/inventory/state/inventory_view.dart';
import 'package:thingzee/pages/inventory/widget/item_list_tile.dart';

class InventoryViewWidget extends ConsumerWidget {
  const InventoryViewWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(inventoryProvider);

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: ListView.builder(
        padding: const EdgeInsets.all(0),
        itemCount: products.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return const SizedBox(
              height: 80,
            );
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Card(
              margin: EdgeInsets.zero,
              elevation: 1,
              shape: const RoundedRectangleBorder(),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildItem(context, ref, index),
                  ],
                ),
              ),
            ),
          );
        },
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
    bool showImages = ref.watch(inventoryDisplayProvider).displayImages;

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
      child: ItemListTile(item, inventory,
          key: ValueKey(item.upc), brandedName: showBranded, image: showImages),
    );
  }
}
