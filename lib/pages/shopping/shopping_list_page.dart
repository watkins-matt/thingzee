import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:thingzee/icon_library.dart';
import 'package:thingzee/pages/barcode/barcode_scanner_page.dart';
import 'package:thingzee/pages/detail/item_detail_page.dart';
import 'package:thingzee/pages/shopping/shopping_cart_page.dart';
import 'package:thingzee/pages/shopping/state/shopping_cart.dart';
import 'package:thingzee/pages/shopping/state/shopping_list.dart';

class ShoppingListPage extends ConsumerWidget {
  const ShoppingListPage({Key? key}) : super(key: key);

  static Future<void> push(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ShoppingListPage()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sl = ref.watch(shoppingListProvider);
    final sc = ref.watch(shoppingCartProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        actions: [
          TextButton.icon(
              onPressed: () async {
                await ShoppingCartPage.push(context);
              },
              icon: const Icon(Icons.shopping_cart),
              label: const Text('View Cart'))
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemBuilder: (context, index) => shoppingListItemBuilder(context, ref, index, sl, sc),
              itemCount: sl.items.length,
            ),
          )
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // FloatingActionButton(
          //     onPressed: () {}, heroTag: 'ShoppingListAdd', child: Icon(Icons.add)),
          // SizedBox(
          //   height: 15,
          //   // width: 50,
          // ),
          FloatingActionButton(
            heroTag: 'ShoppingListBarcodeScan',
            onPressed: () async {
              await BarcodeScannerPage.push(context, BarcodeScannerMode.addToShoppingList);
            },
            tooltip: 'Scan Barcode',
            child: const Icon(IconLibrary.barcode),
          ),
        ],
      ),
    );
  }

  Widget shoppingListItemBuilder(
      BuildContext context, WidgetRef ref, int index, ShoppingListState sl, ShoppingCartState sc) {
    final joinedItem = sl.items[index];
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
          ref.read(shoppingListProvider.notifier).removeAt(index);
          ref.read(shoppingCartProvider.notifier).remove(joinedItem);
        },
        child: CheckboxListTile(
          value: sl.checked.contains(item.upc),
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: (value) {
            ref.read(shoppingListProvider.notifier).check(index, value ?? false);

            if (sl.checked.contains(item.upc)) {
              ref.read(shoppingCartProvider.notifier).add(joinedItem);
            } else {
              ref.read(shoppingCartProvider.notifier).remove(joinedItem);
            }
          },
          title: Text(
            item.name,
            style: TextStyle(
              decoration:
                  sl.checked.contains(item.upc) ? TextDecoration.lineThrough : TextDecoration.none,
            ),
          ),
          subtitle: inventory.canPredict
              ? Text('Out on ${DateFormat.yMMMd().format(inventory.predictedOutDate)}',
                  style: TextStyle(
                      decoration: sl.checked.contains(item.upc)
                          ? TextDecoration.lineThrough
                          : TextDecoration.none))
              : null,
          secondary: Text(
            inventory.preferredAmountString,
            textScaleFactor: 1.5,
            style: TextStyle(color: inventory.preferredAmount > 0.5 ? Colors.green : Colors.red),
          ),
        ),
      ),
    );
  }
}
