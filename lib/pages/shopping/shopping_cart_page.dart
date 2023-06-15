import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:thingzee/pages/detail/item_detail_page.dart';
import 'package:thingzee/pages/shopping/confirmation_dialog.dart';
import 'package:thingzee/pages/shopping/price_entry_dialog.dart';
import 'package:thingzee/pages/shopping/state/shopping_cart.dart';
import 'package:thingzee/pages/shopping/state/shopping_list.dart';

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
    final sc = ref.watch(shoppingCartProvider);
    final sl = ref.watch(shoppingListProvider);

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
            child: ListView.builder(
              itemBuilder: (context, index) => shoppingCartItemBuilder(context, ref, index, sc, sl),
              itemCount: sc.items.length,
            ),
          )
        ],
      ),
    );
  }

  Widget shoppingCartItemBuilder(
      BuildContext context, WidgetRef ref, int index, ShoppingCartState sc, ShoppingListState sl) {
    final joinedItem = sc.items[index];
    final item = joinedItem.item;
    final inventory = joinedItem.inventory;

    return InkWell(
      onLongPress: () async {
        await ItemDetailPage.push(context, ref, item, inventory);
      },
      child: Dismissible(
        key: UniqueKey(),
        background: Container(color: Colors.red),
        dismissThresholds: const {
          DismissDirection.endToStart: 0.9,
          DismissDirection.startToEnd: 0.9,
        },
        onDismissed: (_) {
          ref.read(shoppingCartProvider.notifier).removeAt(index);
          ref.read(shoppingListProvider.notifier).check(sl.items.indexOf(joinedItem), false);
        },
        child: ListTile(
            title: Text(
              item.name,
            ),
            trailing: ElevatedButton(
              onPressed: () async => await PriceEntryDialog.show(context),
              child: const Text('Enter Price'),
            )),
      ),
    );
  }
}
